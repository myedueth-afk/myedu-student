import 'package:eschool/ui/styles/colors.dart';
import 'package:eschool/ui/widgets/customRoundedButton.dart';
import 'package:eschool/ui/widgets/customTextContainer.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Confirmation shown after a leave request is accepted by the backend. It
/// replaces the apply screen, so backing out of here lands on the leaves list.
class StudentLeaveSubmittedScreen extends StatelessWidget {
  const StudentLeaveSubmittedScreen({Key? key}) : super(key: key);

  static Widget routeInstance() {
    return const StudentLeaveSubmittedScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Utils.screenContentHorizontalPadding,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  height: 120.0,
                  width: 120.0,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 64.0,
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
              ),
              const SizedBox(height: 32.0),
              CustomTextContainer(
                textKey: leaveRequestSubmittedKey,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 24.0,
                  height: 32 / 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8.0),
              CustomTextContainer(
                textKey: leaveRequestSubmittedDescriptionKey,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: captionColor,
                  fontSize: 14.0,
                  height: 20 / 14,
                  letterSpacing: 0.25,
                ),
              ),
              const SizedBox(height: 32.0),
              CustomRoundedButton(
                onTap: () => Get.back(),
                height: 48.0,
                widthPercentage: 1.0,
                backgroundColor: Theme.of(context).colorScheme.primary,
                buttonTitle: Utils.getTranslatedLabel(viewRequestKey),
                showBorder: false,
                radius: 8.0,
              ),
              const SizedBox(height: 8.0),
              TextButton(
                onPressed: () => Get.until((route) => route.isFirst),
                child: CustomTextContainer(
                  textKey: homeKey,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
