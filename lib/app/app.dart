import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:eschool/app/appTranslation.dart';
import 'package:eschool/cubits/assignmentsCubit.dart';
import 'package:eschool/cubits/childFeeDetailsCubit.dart';
import 'package:eschool/cubits/resultsOnlineCubit.dart';
import 'package:eschool/cubits/schoolConfigurationCubit.dart';
import 'package:eschool/cubits/schoolDetailsCubit.dart';
import 'package:eschool/cubits/semesterCubit.dart';
import 'package:eschool/cubits/socketSettingCubit.dart';
import 'package:eschool/cubits/studentProfileCubit.dart';
import 'package:eschool/cubits/subjectWiseReportCubit.dart';
import 'package:eschool/data/repositories/assignmentRepository.dart';
import 'package:eschool/data/repositories/feeRepository.dart';
import 'package:eschool/data/repositories/resultRepository.dart';
import 'package:eschool/data/repositories/schoolRepository.dart';
import 'package:eschool/data/repositories/semesterRepository.dart';
import 'package:eschool/data/repositories/subjectWiseReportRepository.dart';
import 'package:eschool/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/route_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:eschool/app/routes.dart';

import 'package:eschool/cubits/appConfigurationCubit.dart';
import 'package:eschool/cubits/appLocalizationCubit.dart';
import 'package:eschool/cubits/authCubit.dart';
import 'package:eschool/cubits/examDetailsCubit.dart';
import 'package:eschool/cubits/examsOnlineCubit.dart';
import 'package:eschool/cubits/noticeBoardCubit.dart';
import 'package:eschool/cubits/notificationSettingsCubit.dart';
import 'package:eschool/cubits/postFeesPaymentCubit.dart';
import 'package:eschool/cubits/resultTabSelectionCubit.dart';
import 'package:eschool/cubits/studentSubjectAndSlidersCubit.dart';
import 'package:eschool/cubits/examTabSelectionCubit.dart';

import 'package:eschool/data/repositories/announcementRepository.dart';
import 'package:eschool/data/repositories/authRepository.dart';
import 'package:eschool/data/repositories/localizationRepository.dart';
import 'package:eschool/data/repositories/onlineExamRepository.dart';
import 'package:eschool/data/repositories/settingsRepository.dart';
import 'package:eschool/data/repositories/studentRepository.dart';
import 'package:eschool/data/repositories/systemInfoRepository.dart';

import 'package:eschool/cubits/onlineExamQuestionsCubit.dart';
import 'package:eschool/ui/styles/colors.dart';

import 'package:eschool/utils/hiveBoxKeys.dart';
import 'package:eschool/utils/notificationUtility.dart';
import 'package:eschool/utils/unauthenticatedAccessManager.dart';
import 'package:intl/date_symbol_data_local.dart';

//to avoid handshake error on some devices
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  HttpOverrides.global = MyHttpOverrides();

  //Register the licence of font
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  await AppTranslation.loadJsons();

  await NotificationUtility.initializeAwesomeNotification();

  await Hive.initFlutter();
  await Hive.openBox(showCaseBoxKey);
  await Hive.openBox(authBoxKey);
  await Hive.openBox(settingsBoxKey);
  await Hive.openBox(studentSubjectsBoxKey);
  await Hive.openBox(pendingExamBoxKey);
  await Hive.openBox(localizationBoxKey);

  // Overlay labels previously fetched from the panel on top of the bundled
  // ones so the first frame already renders them, even when offline.
  final cachedRemoteLabels = LocalizationRepository().getAllCachedLabels();
  AppTranslation.overlayRemoteLabels(cachedRemoteLabels);
  if (kDebugMode) {
    debugPrint(
        "Localization: startup overlay of cached labels for ${cachedRemoteLabels.keys.toList()}");
  }

  await initializeDateFormatting('en_US', null);

  runApp(const MyApp());
}

class GlobalScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationUtility.onActionReceivedMethod,
      onNotificationCreatedMethod:
          NotificationUtility.onNotificationCreatedMethod,
      onNotificationDisplayedMethod:
          NotificationUtility.onNotificationDisplayedMethod,
      onDismissActionReceivedMethod:
          NotificationUtility.onDismissActionReceivedMethod,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //SVG images are automatically cached by flutter_svg
    return MultiBlocProvider(
      providers: [
        BlocProvider<SchooldetailsCubit>(
          create: (_) => SchooldetailsCubit(),
        ),
        BlocProvider<AppLocalizationCubit>(
          create: (_) => AppLocalizationCubit(SettingsRepository()),
        ),
        BlocProvider<NotificationSettingsCubit>(
          create: (_) => NotificationSettingsCubit(SettingsRepository()),
        ),
        BlocProvider<AuthCubit>(
          create: (_) {
            final authCubit = AuthCubit(AuthRepository());
            // Will be fully initialized after SocketSettingCubit is created
            UnauthenticatedAccessManager().init(
              authCubit: authCubit,
            );
            return authCubit;
          },
        ),
        BlocProvider<StudentProfileCubit>(
          create: (_) =>
              StudentProfileCubit(StudentRepository(), AuthRepository()),
        ),
        BlocProvider<StudentSubjectsAndSlidersCubit>(
          create: (_) => StudentSubjectsAndSlidersCubit(),
        ),
        BlocProvider<NoticeBoardCubit>(
          create: (context) => NoticeBoardCubit(AnnouncementRepository()),
        ),
        BlocProvider<AppConfigurationCubit>(
          create: (context) => AppConfigurationCubit(SystemRepository()),
        ),
        BlocProvider<ExamDetailsCubit>(
          create: (context) => ExamDetailsCubit(StudentRepository()),
        ),
        BlocProvider<PostFeesPaymentCubit>(
          create: (context) => PostFeesPaymentCubit(StudentRepository()),
        ),
        BlocProvider<ResultTabSelectionCubit>(
          create: (_) => ResultTabSelectionCubit(),
        ),
        BlocProvider<SubjectWiseReportCubit>(
          create: (_) => SubjectWiseReportCubit(SubjectWiseReportRepository()),
        ),
        BlocProvider<ExamTabSelectionCubit>(
          create: (_) => ExamTabSelectionCubit(),
        ),
        BlocProvider<OnlineExamQuestionsCubit>(
          create: (_) => OnlineExamQuestionsCubit(OnlineExamRepository()),
        ),
        BlocProvider<ExamsOnlineCubit>(
          create: (_) => ExamsOnlineCubit(OnlineExamRepository()),
        ),
        BlocProvider<ResultsOnlineCubit>(
          create: (_) => ResultsOnlineCubit(ResultRepository()),
        ),
        BlocProvider<SemesterCubit>(
          create: (_) => SemesterCubit(SemesterRepository()),
        ),
        BlocProvider<AssignmentsCubit>(
          create: (_) => AssignmentsCubit(AssignmentRepository()),
        ),
        BlocProvider<SchoolConfigurationCubit>(
            create: (_) => SchoolConfigurationCubit(SchoolRepository())),
        BlocProvider<ChildFeeDetailsCubit>(
            create: (_) => ChildFeeDetailsCubit(FeeRepository())),
        BlocProvider<SocketSettingCubit>(create: (context) {
          final socketCubit = SocketSettingCubit();
          // Register with the manager for cleanup on logout
          UnauthenticatedAccessManager().init(
            authCubit: context.read<AuthCubit>(),
            socketSettingCubit: socketCubit,
          );
          return socketCubit;
        })
      ],
      child: Builder(
        builder: (context) {
          return GetMaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  viewPadding: MediaQuery.of(context).viewPadding.copyWith(
                        top: 0, // Keep status bar transparent
                      ),
                ),
                child: SafeArea(
                  top: false, // Don't add padding for status bar
                  bottom: true,
                  child: child ?? Container(),
                ),
              );
            },
            theme: Theme.of(context).copyWith(
              textTheme:
                  GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
              scaffoldBackgroundColor: pageBackgroundColor,
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: primaryColor,
                    onPrimary: onPrimaryColor,
                    secondary: secondaryColor,
                    tertiary: tertiaryColor,
                    surface: backgroundColor,
                    error: errorColor,
                    onSecondary: onSecondaryColor,
                    onSurface: onBackgroundColor,
                  ),
            ),
            locale: context.read<AppLocalizationCubit>().state.language,
            // Always a language bundled with the build, so a key the active
            // language is missing still renders as text and not as a raw key.
            fallbackLocale: context.read<AppLocalizationCubit>().fallbackLocale,
            // Custom panel language codes (e.g. "002") are not in GetX's
            // built-in RTL list, so direction is driven by the panel's flag.
            textDirection: context.read<AppLocalizationCubit>().textDirection,
            getPages: Routes.getPages,
            initialRoute: Routes.splash,
            translationsKeys: AppTranslation.translationsKeys,
          );
        },
      ),
    );
  }
}
