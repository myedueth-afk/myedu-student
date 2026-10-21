import 'package:eschool/cubits/appSettingsCubit.dart';
import 'package:eschool/data/repositories/authRepository.dart';
import 'package:eschool/data/repositories/systemInfoRepository.dart';
import 'package:eschool/ui/widgets/appSettingsBlocBuilder.dart';
import 'package:eschool/ui/widgets/customAppbar.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TermsAndConditionScreen extends StatefulWidget {
  const TermsAndConditionScreen({Key? key}) : super(key: key);

  @override
  State<TermsAndConditionScreen> createState() =>
      _TermsAndConditionScreenState();

  static Widget routeInstance() {
    return BlocProvider<AppSettingsCubit>(
      create: (context) => AppSettingsCubit(SystemRepository()),
      child: const TermsAndConditionScreen(),
    );
  }
}

class _TermsAndConditionScreenState extends State<TermsAndConditionScreen> {
  final String termsAndConditionTypeLoggedIn = "terms_condition";
  final String termsAndConditionTypeNotLoggedIn = "student_terms_condition";

  final isLoggedIn = AuthRepository().getIsLogIn();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (isLoggedIn) {
        context
            .read<AppSettingsCubit>()
            .fetchSchoolSettings(type: termsAndConditionTypeLoggedIn);
      } else {
        context
            .read<AppSettingsCubit>()
            .fetchAppSettings(type: termsAndConditionTypeNotLoggedIn);
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
            title: Utils.getTranslatedLabel(termsAndConditionKey),
          )
        ],
      ),
    );
  }
}
