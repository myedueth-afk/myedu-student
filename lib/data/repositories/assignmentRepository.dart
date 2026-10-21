import 'package:dio/dio.dart';
import 'package:eschool/data/models/assignment.dart';
import 'package:eschool/utils/api.dart';

class AssignmentRepository {
  Future<Map<String, dynamic>> fetchAssignments({
    int? page,
    int? assignmentId,
    int? classSubjectId,
    required int isSubmitted,
    required bool useParentApi,
    required int childId,
  }) async {
    try {
      Map<String, dynamic> queryParameters = {
        "assignment_id": assignmentId ?? 0,
        "class_subject_id": classSubjectId ?? 0,
        "page": page ?? 0,
        "is_submitted": isSubmitted
      };

      if (queryParameters['assignment_id'] == 0) {
        queryParameters.remove('assignment_id');
      }

      if (queryParameters['class_subject_id'] == 0) {
        queryParameters.remove('class_subject_id');
      }

      if (queryParameters['page'] == 0) {
        queryParameters.remove('page');
      }

      if (useParentApi) {
        queryParameters.addAll({"child_id": childId});
      }

      final result = await Api.get(
        url: useParentApi ? Api.getAssignmentsParent : Api.getAssignments,
        useAuthToken: true,
        queryParameters: queryParameters,
      );

      return {
        "assignments": (result['data']['data'] as List).map((e) {
          return Assignment.fromJson(Map.from(e));
        }).toList(),
        "totalPage": result['data']['last_page'] as int,
        "currentPage": result['data']['current_page'] as int,
      };
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> submitAssignment({
    required int assignmentId,
    List<String>? filePaths,
    String? linkUrl,
    required CancelToken cancelToken,
    required Function updateUploadAssignmentPercentage,
  }) async {
    try {
      Map<String, dynamic> body = {"assignment_id": assignmentId};

      // Add files if provided
      if (filePaths != null && filePaths.isNotEmpty) {
        List<MultipartFile> files = [];
        for (var filePath in filePaths) {
          files.add(await MultipartFile.fromFile(filePath));
        }
        body["files"] = files;
      }

      // Add link URL if provided
      if (linkUrl != null && linkUrl.isNotEmpty) {
        body["add_url"] = linkUrl;
      }

      final result = await Api.post(
        body: body,
        url: Api.submitAssignment,
        useAuthToken: true,
        cancelToken: cancelToken,
        onSendProgress: (count, total) {
          updateUploadAssignmentPercentage((count / total) * 100);
        },
      );

      final assignmentSubmissions = (result['data'] ?? []) as List;
      final successMessage =
          result['message']?.toString() ?? 'Assignment submitted successfully';

      return {
        'assignmentSubmission': AssignmentSubmission.fromJson(
          Map.from(
            assignmentSubmissions.isEmpty ? {} : assignmentSubmissions.first,
          ),
        ),
        'message': successMessage,
      };
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<void> deleteAssignment({
    required int assignmentSubmissionId,
  }) async {
    try {
      await Api.post(
        body: {"assignment_submission_id": assignmentSubmissionId},
        url: Api.deleteAssignment,
        useAuthToken: true,
      );
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
