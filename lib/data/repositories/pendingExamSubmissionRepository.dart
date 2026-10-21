import 'dart:convert';
import 'package:eschool/utils/hiveBoxKeys.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Repository for managing pending exam submissions
/// Used to persist exam state when app goes to background or is terminated
class PendingExamSubmissionRepository {
  /// Save pending exam data to Hive for later submission
  static Future<void> savePendingExam({
    required int examId,
    required Map<int, List<int>> answers,
    required String examTitle,
    required String subjectName,
    required int classSubjectId,
  }) async {
    try {
      final box = Hive.box(pendingExamBoxKey);

      // Convert answers map to JSON string for storage
      final answersJson = jsonEncode(
        answers.map((key, value) => MapEntry(key.toString(), value)),
      );

      await box.put(pendingExamIdKey, examId);
      await box.put(pendingExamAnswersKey, answersJson);
      await box.put(pendingExamTitleKey, examTitle);
      await box.put(pendingExamSubjectNameKey, subjectName);
      await box.put(pendingExamClassSubjectIdKey, classSubjectId);

      if (kDebugMode) {
        print('PendingExamSubmissionRepository: Saved pending exam $examId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('PendingExamSubmissionRepository: Error saving pending exam: $e');
      }
    }
  }

  /// Check if there's a pending exam submission
  static bool hasPendingExam() {
    try {
      final box = Hive.box(pendingExamBoxKey);
      final examId = box.get(pendingExamIdKey);
      return examId != null && examId > 0;
    } catch (e) {
      if (kDebugMode) {
        print(
            'PendingExamSubmissionRepository: Error checking pending exam: $e');
      }
      return false;
    }
  }

  /// Get pending exam data
  /// Returns null if no pending exam exists
  static Map<String, dynamic>? getPendingExam() {
    try {
      final box = Hive.box(pendingExamBoxKey);
      final examId = box.get(pendingExamIdKey);

      if (examId == null || examId <= 0) {
        return null;
      }

      final answersJson = box.get(pendingExamAnswersKey) as String?;
      final examTitle = box.get(pendingExamTitleKey) as String? ?? '';
      final subjectName = box.get(pendingExamSubjectNameKey) as String? ?? '';
      final classSubjectId = box.get(pendingExamClassSubjectIdKey) as int? ?? 0;

      // Convert JSON string back to Map<int, List<int>>
      Map<int, List<int>> answers = {};
      if (answersJson != null && answersJson.isNotEmpty) {
        final decoded = jsonDecode(answersJson) as Map<String, dynamic>;
        answers = decoded.map(
          (key, value) => MapEntry(
            int.parse(key),
            (value as List).map((e) => e as int).toList(),
          ),
        );
      }

      return {
        'examId': examId as int,
        'answers': answers,
        'examTitle': examTitle,
        'subjectName': subjectName,
        'classSubjectId': classSubjectId,
      };
    } catch (e) {
      if (kDebugMode) {
        print(
            'PendingExamSubmissionRepository: Error getting pending exam: $e');
      }
      return null;
    }
  }

  /// Clear pending exam data after successful submission
  static Future<void> clearPendingExam() async {
    try {
      final box = Hive.box(pendingExamBoxKey);
      await box.delete(pendingExamIdKey);
      await box.delete(pendingExamAnswersKey);
      await box.delete(pendingExamTitleKey);
      await box.delete(pendingExamSubjectNameKey);
      await box.delete(pendingExamClassSubjectIdKey);

      if (kDebugMode) {
        print('PendingExamSubmissionRepository: Cleared pending exam');
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            'PendingExamSubmissionRepository: Error clearing pending exam: $e');
      }
    }
  }
}
