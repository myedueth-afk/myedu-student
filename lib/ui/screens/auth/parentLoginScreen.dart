import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/authCubit.dart';
import 'package:eschool/cubits/forgotPasswordRequestCubit.dart';
import 'package:eschool/cubits/signInCubit.dart';
import 'package:eschool/data/repositories/authRepository.dart';
import 'package:eschool/ui/screens/auth/widgets/forgotPasswordRequestBottomsheet.dart';
import 'package:eschool/ui/screens/auth/widgets/termsAndConditionAndPrivacyPolicyContainer.dart';
import 'package:eschool/ui/widgets/appIcon.dart';
import 'package:eschool/ui/widgets/customCircularProgressIndicator.dart';
import 'package:eschool/ui/widgets/customRoundedButton.dart';
import 'package:eschool/ui/widgets/customTextFieldContainer.dart';
import 'package:eschool/ui/widgets/passwordHideShowButton.dart';
import 'package:eschool/utils/constants.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/unauthenticatedAccessManager.dart';
import 'package:eschool/utils/utils.dart';
import 'package:eschool/app/schoolBuildConfig.dart';
import 'package:eschool/ui/widgets/schoolCodeFieldContainer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class ParentLoginScreen extends StatefulWidget {
  const ParentLoginScreen({Key? key}) : super(key: key);

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();

  static Widget routeInstance() {
    return BlocProvider<SignInCubit>(
      child: const ParentLoginScreen(),
      create: (_) => SignInCubit(AuthRepository()),
    );
  }
}

class _ParentLoginScreenState extends State<ParentLoginScreen>
    with TickerProviderStateMixin {
  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  late final Animation<double> _patterntAnimation =
      Tween<double>(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
    ),
  );

  late final Animation<double> _formAnimation =
      Tween<double>(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
    ),
  );

  final _schoolCodeController = TextEditingController(
    text: SchoolBuildConfig.hasFixedSchoolCode
        ? SchoolBuildConfig.schoolCode
        : (showDefaultCredentials ? defaultSchoolCode : null),
  );

  final TextEditingController _emailTextEditingController =
      TextEditingController(
          text: showDefaultCredentials
              ? defaultParentEmail
              : null); //default email

  final TextEditingController _passwordTextEditingController =
      TextEditingController(
          text: showDefaultCredentials
              ? defaultParentPassword
              : null); //default password

  static const MethodChannel _autofillChannel = MethodChannel('et.myedu/autofill');
  bool _hidePassword = true;

  @override
  void initState() {
    super.initState();
    _animationController.forward();
    _checkAutofill();
    _autofillChannel.setMethodCallHandler(_handleAutofillCall);
  }

  Future<dynamic> _handleAutofillCall(MethodCall call) async {
    if (call.method == 'onAutofillReceived') {
      final data = call.arguments;
      if (data is Map) {
        _applyAutofill(Map<String, dynamic>.from(data));
      }
    }
  }

  Future<void> _checkAutofill() async {
    try {
      final res = await _autofillChannel.invokeMethod('getAutofillCredentials');
      if (res != null && res is Map) {
        _applyAutofill(Map<String, dynamic>.from(res));
      }
    } catch (_) {}
  }

  void _applyAutofill(Map<String, dynamic> data) {
    if (!mounted) return;
    final role = data['role']?.toString().toLowerCase();
    if (role == null || role == 'parent' || !data.containsKey('role')) {
      setState(() {
        if (data['school_code'] != null && data['school_code'].toString().isNotEmpty) {
          _schoolCodeController.text = data['school_code'].toString();
        }
        if (data['username'] != null && data['username'].toString().isNotEmpty) {
          _emailTextEditingController.text = data['username'].toString();
        }
        if (data['password'] != null && data['password'].toString().isNotEmpty) {
          _passwordTextEditingController.text = data['password'].toString();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();

    _emailTextEditingController.dispose();
    _passwordTextEditingController.dispose();
    super.dispose();
  }

  void _signInParent() {
    final schoolCode =
        SchoolBuildConfig.resolveSchoolCode(_schoolCodeController.text);

    if (schoolCode.isEmpty) {
      Utils.showCustomSnackBar(
        context: context,
        errorMessage: Utils.getTranslatedLabel(
          Utils.getTranslatedLabel("pleaseEnterSchoolCode"),
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return;
    }

    if (_emailTextEditingController.text.trim().isEmpty) {
      Utils.showCustomSnackBar(
        context: context,
        errorMessage: Utils.getTranslatedLabel(pleaseEnterEmailKey),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return;
    }

    if (_passwordTextEditingController.text.trim().isEmpty) {
      Utils.showCustomSnackBar(
        context: context,
        errorMessage: Utils.getTranslatedLabel(pleaseEnterPasswordKey),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return;
    }

    context.read<SignInCubit>().signInUser(
          userId: _emailTextEditingController.text.trim(),
          schoolCode: schoolCode,
          password: _passwordTextEditingController.text.trim(),
          isStudentLogin: false,
        );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: GestureDetector(
          onTap: () {
            Utils.showBottomSheet(
              child: BlocProvider(
                create: (_) => ForgotPasswordRequestCubit(AuthRepository()),
                child: const ForgotPasswordRequestBottomsheet(),
              ),
              context: context,
            ).then((value) {
              if (value != null && !value['error']) {
                Utils.showCustomSnackBar(
                  context: context,
                  errorMessage: "${Utils.getTranslatedLabel(
                    passwordUpdateLinkSentKey,
                  )} ${value['email']}",
                  backgroundColor: Theme.of(context).colorScheme.onPrimary,
                );
              }
            });
          },
          child: Text(
            "${Utils.getTranslatedLabel(forgotPasswordKey)}?",
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildUpperPattern() {
    return Align(
      alignment: AlignmentDirectional.topEnd,
      child: FadeTransition(
        opacity: _patterntAnimation,
        child: SlideTransition(
          position: _patterntAnimation.drive(
            Tween<Offset>(begin: const Offset(0.0, -1.0), end: Offset.zero),
          ),
          child: AppIcon(
            Utils.getImagePath("upper_pattern.svg"),
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildLowerPattern() {
    return Align(
      alignment: AlignmentDirectional.bottomStart,
      child: FadeTransition(
        opacity: _patterntAnimation,
        child: SlideTransition(
          position: _patterntAnimation.drive(
            Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero),
          ),
          child: AppIcon(
            Utils.getImagePath("lower_pattern.svg"),
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: FadeTransition(
        opacity: _formAnimation,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ), //to make UI scrollable when keyboard is opened
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: NotificationListener(
              onNotification: (OverscrollIndicatorNotification overscroll) {
                overscroll.disallowIndicator();
                return true;
              },
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: MediaQuery.of(context).size.width * (0.075),
                  right: MediaQuery.of(context).size.width * (0.075),
                  top: MediaQuery.of(context).size.height * (0.17),
                ),
                child: Form(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Utils.getTranslatedLabel(letsSignInKey),
                        style: TextStyle(
                          fontSize: 34.0,
                          fontWeight: FontWeight.bold,
                          color: Utils.getColorScheme(context).secondary,
                        ),
                      ),
                      const SizedBox(
                        height: 10.0,
                      ),
                      Text(
                        "${Utils.getTranslatedLabel(welcomeBackKey)}, \n${Utils.getTranslatedLabel(youHaveBeenMissedKey)}",
                        style: TextStyle(
                          fontSize: 24.0,
                          height: 1.5,
                          color: Utils.getColorScheme(context).secondary,
                        ),
                      ),

                      /// School code field — hidden on a single-school build
                      if (!SchoolBuildConfig.hasFixedSchoolCode)
                        const SizedBox(height: 30.0),
                      SchoolCodeFieldContainer(
                        bottomPadding: 0,
                        textEditingController: _schoolCodeController,
                      ),

                      const SizedBox(
                        height: 30.0,
                      ),
                      CustomTextFieldContainer(
                        hideText: false,
                        hintTextKey: emailKey,
                        bottomPadding: 0,
                        textEditingController: _emailTextEditingController,
                        suffixWidget: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SvgPicture.asset(
                            Utils.getImagePath("mail_icon.svg"),
                            colorFilter: ColorFilter.mode(
                              Utils.getColorScheme(context).secondary,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20.0,
                      ),
                      CustomTextFieldContainer(
                        hideText: _hidePassword,
                        hintTextKey: passwordKey,
                        bottomPadding: 0,
                        textEditingController: _passwordTextEditingController,
                        suffixWidget: PasswordHideShowButton(
                          hidePassword: _hidePassword,
                          onTap: () {
                            _hidePassword = !_hidePassword;
                            setState(() {});
                          },
                        ),
                      ),
                      _buildForgotPassword(),
                      const SizedBox(
                        height: 30.0,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Center(
                        child: BlocConsumer<SignInCubit, SignInState>(
                          listener: (context, state) {
                            if (state is SignInSuccess) {
                              //
                              context.read<AuthCubit>().authenticateUser(
                                    schoolCode: state.schoolCode,
                                    jwtToken: state.jwtToken,
                                    isStudent: state.isStudentLogIn,
                                    parent: state.parent,
                                    student: state.student,
                                  );

                              // Unblock API calls after re-authentication
                              UnauthenticatedAccessManager()
                                  .onUserAuthenticated();

                              // Check if user was redirected here due to 401
                              final lastRoute =
                                  UnauthenticatedAccessManager().lastRoute;
                              if (lastRoute != null &&
                                  lastRoute != Routes.auth &&
                                  lastRoute != Routes.studentLogin &&
                                  lastRoute != Routes.parentLogin) {
                                UnauthenticatedAccessManager().clearLastRoute();
                                Get.offNamedUntil(
                                  lastRoute,
                                  (_) => false,
                                );
                              } else {
                                UnauthenticatedAccessManager().clearLastRoute();
                                Get.offNamedUntil(Routes.parentOnbording,
                                    (Route<dynamic> route) => false);
                              }
                            } else if (state is SignInFailure) {
                              Utils.showCustomSnackBar(
                                context: context,
                                errorMessage: Utils.getTranslatedLabel(
                                    state.errorMessage),
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
                              );
                            }
                          },
                          builder: (context, state) {
                            return CustomRoundedButton(
                              onTap: () {
                                if (state is SignInInProgress) {
                                  return;
                                }

                                FocusScope.of(context).unfocus();

                                _signInParent();
                              },
                              widthPercentage: 0.8,
                              backgroundColor:
                                  Utils.getColorScheme(context).primary,
                              buttonTitle: Utils.getTranslatedLabel(signInKey),
                              titleColor:
                                  Theme.of(context).scaffoldBackgroundColor,
                              showBorder: false,
                              child: state is SignInInProgress
                                  ? const CustomCircularProgressIndicator(
                                      strokeWidth: 2,
                                      widthAndHeight: 20,
                                    )
                                  : null,
                            );
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 10.0,
                      ),
                      BlocBuilder<SignInCubit, SignInState>(
                        builder: (context, state) {
                          return Center(
                            child: InkWell(
                              onTap: () {
                                if (state is SignInInProgress) {
                                  return;
                                }
                                Get.offNamed(Routes.studentLogin);
                              },
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        color: Utils.getColorScheme(context)
                                            .primary,
                                      ),
                                      text: Utils.getTranslatedLabel(
                                        loginAsKey,
                                      ),
                                    ),
                                    const TextSpan(text: " "),
                                    TextSpan(
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16.0,
                                        color: Utils.getColorScheme(context)
                                            .secondary,
                                      ),
                                      text:
                                          "${Utils.getTranslatedLabel(studentKey)}?",
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      const TermsAndConditionAndPrivacyPolicyContainer(),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * (0.025),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _buildUpperPattern(),
          _buildLowerPattern(),
          _buildLoginForm(),
        ],
      ),
    );
  }
}
