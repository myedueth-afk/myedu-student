import 'package:eschool/app/routes.dart';
import 'package:eschool/data/repositories/onlineExamRepository.dart';
import 'package:eschool/data/repositories/pendingExamSubmissionRepository.dart';
import 'package:eschool/ui/screens/home/homeScreen.dart';
import 'package:eschool/ui/widgets/customRoundedButton.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

/// Utility class for handling pending exam submissions on app startup
class PendingExamSubmissionHandler {
  static bool _isSubmitting = false;

  /// Check and submit any pending exams on app startup
  /// This should be called after the user is authenticated and navigation is ready
  static Future<void> checkAndSubmitPendingExam() async {
    // Prevent duplicate submissions
    if (_isSubmitting) return;

    try {
      if (!PendingExamSubmissionRepository.hasPendingExam()) {
        return;
      }

      _isSubmitting = true;

      final pendingExam = PendingExamSubmissionRepository.getPendingExam();
      if (pendingExam == null) {
        _isSubmitting = false;
        return;
      }

      final int examId = pendingExam['examId'] as int;
      final Map<int, List<int>> answers =
          pendingExam['answers'] as Map<int, List<int>>;
      final String examTitle = pendingExam['examTitle'] as String;
      final String subjectName = pendingExam['subjectName'] as String;

      if (kDebugMode) {
        print(
            'PendingExamSubmissionHandler: Found pending exam $examId, submitting...');
      }

      // Submit the exam
      final repository = OnlineExamRepository();
      await repository.setExamOnlineAnswers(
        examId: examId,
        answerData: answers,
      );

      if (kDebugMode) {
        print(
            'PendingExamSubmissionHandler: Successfully submitted pending exam $examId');
      }

      // Clear the pending exam after successful submission
      await PendingExamSubmissionRepository.clearPendingExam();

      // Show the exam complete dialog (same as buildExamCompleteDialog)
      Future.delayed(const Duration(milliseconds: 500), () {
        if (Get.context != null) {
          _showExamCompleteDialog(
            context: Get.context!,
            examId: examId,
            examTitle: examTitle,
            subjectName: subjectName,
          );
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print(
            'PendingExamSubmissionHandler: Error submitting pending exam: $e');
      }
      // Keep the pending exam for retry on next app launch
      // Don't clear it if submission failed
    } finally {
      _isSubmitting = false;
    }
  }

  /// Show exam complete dialog with Home and Result buttons
  static void _showExamCompleteDialog({
    required BuildContext context,
    required int examId,
    required String examTitle,
    required String subjectName,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                "assets/animations/payment_success.json",
                animate: true,
              ),
              Text(
                Utils.getTranslatedLabel(examCompletedKey),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Utils.getColorScheme(dialogContext).secondary),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            CustomRoundedButton(
              backgroundColor: Utils.getColorScheme(dialogContext).primary,
              buttonTitle: Utils.getTranslatedLabel(homeKey),
              titleColor: Theme.of(dialogContext).scaffoldBackgroundColor,
              showBorder: false,
              widthPercentage: 0.3,
              height: 45,
              onTap: () {
                Navigator.of(dialogContext).pop();
                // User is already on home screen, just refresh
                Get.until((route) => route.isFirst);
                HomeScreen.currentState?.changeBottomNavItem(0);
              },
            ),
            CustomRoundedButton(
              backgroundColor: Theme.of(dialogContext).scaffoldBackgroundColor,
              buttonTitle: Utils.getTranslatedLabel(resultKey),
              titleColor: Utils.getColorScheme(dialogContext).primary,
              showBorder: true,
              borderColor: Utils.getColorScheme(dialogContext).primary,
              widthPercentage: 0.3,
              height: 45,
              onTap: () {
                Navigator.of(dialogContext).pop();
                Get.toNamed(
                  Routes.resultOnline,
                  arguments: {
                    "examId": examId,
                    "examName": examTitle,
                    "subjectName": subjectName,
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}
