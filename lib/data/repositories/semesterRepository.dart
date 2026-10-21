import 'package:eschool/data/models/semester.dart';
import 'package:eschool/utils/api.dart';

class SemesterRepository {
  /// Fetches the semesters configured for the given session year.
  ///
  /// When the guardian (parent) app is used, the API requires `child_id` to be
  /// the student's user id, so it is sent only for parent requests.
  ///
  /// Schools that do not use semesters get a `"No semester found"` response
  /// with a `null` data field, which is normalised here to an empty list.
  Future<List<Semester>> fetchSemesters({
    required int sessionYearId,
    bool useParentApi = false,
    int? childId,
  }) async {
    try {
      final result = await Api.get(
        url: Api.getSemesters,
        useAuthToken: true,
        queryParameters: {
          "session_year_id": sessionYearId,
          if (useParentApi) "child_id": childId,
        },
      );

      return ((result['data'] ?? []) as List)
          .map((semester) => Semester.fromJson(Map.from(semester ?? {})))
          .toList();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
