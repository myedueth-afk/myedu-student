import 'package:eschool/app/schoolBuildConfig.dart';
import 'package:eschool/cubits/appSettingsCubit.dart';
import 'package:eschool/data/repositories/authRepository.dart';
import 'package:eschool/data/repositories/systemInfoRepository.dart';
import 'package:eschool/ui/widgets/appSettingsBlocBuilder.dart';
import 'package:eschool/ui/widgets/customAppbar.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();

  static Widget routeInstance() {
    return BlocProvider<AppSettingsCubit>(
      create: (context) => AppSettingsCubit(SystemRepository()),
      child: const PrivacyPolicyScreen(),
    );
  }
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  /// The school's own policy.
  final String schoolPrivacyPolicyType = "privacy_policy";

  /// The super admin's policy, for when no school is known yet.
  final String superAdminPrivacyPolicyType = "student_parent_privacy_policy";

  final isLoggedIn = AuthRepository().getIsLogIn();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      final appSettingsCubit = context.read<AppSettingsCubit>();
      if (isLoggedIn) {
        appSettingsCubit.fetchSchoolSettings(type: schoolPrivacyPolicyType);
      } else if (SchoolBuildConfig.hasFixedSchoolCode) {
        // Before login, only a build locked to one school knows the user's
        // school; a generic build learns it from the login form.
        appSettingsCubit.fetchPublicSchoolSettings(
          type: schoolPrivacyPolicyType,
          schoolCode: SchoolBuildConfig.schoolCode,
        );
      } else {
        appSettingsCubit.fetchAppSettings(type: superAdminPrivacyPolicyType);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AppSettingsBlocBuilder(),
          CustomAppBar(
            title: Utils.getTranslatedLabel(privacyPolicyKey),
          )
        ],
      ),
    );
  }
}
