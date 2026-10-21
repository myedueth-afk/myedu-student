import 'package:eschool/data/models/subjectWiseReport.dart';
import 'package:eschool/utils/api.dart';

class SubjectWiseReportRepository {
  Future<SubjectWiseReport> getSubjectWiseReport({
    required int classSubjectId,
    required int childId,
    required bool useParentApi,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {
        'class_subject_id': classSubjectId,
      };

      if (useParentApi) {
        queryParameters['child_id'] = childId;
      }

      final response = await Api.get(
        url: Api.studentSubjectReport,
        useAuthToken: true,
        queryParameters: queryParameters,
      );

      return SubjectWiseReport.fromJson(response['data']);
    } catch (e) {
      rethrow;
    }
  }
}
