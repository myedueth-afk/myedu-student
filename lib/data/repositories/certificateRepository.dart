import 'package:eschool/data/models/certificateAssignment.dart';
import 'package:eschool/utils/api.dart';

class CertificateRepository {
  Future<List<CertificateAssignment>> fetchCertificateAssignments({
    int? childId,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (childId != null && childId != 0) {
        body['user_id'] = childId;
      }

      final result = await Api.post(
        url: Api.getCertificateAssignments,
        useAuthToken: true,
        body: body,
      );

      return ((result['data'] ?? []) as List)
          .map(
            (json) => CertificateAssignment.fromJson(
              Map<String, dynamic>.from(json ?? {}),
            ),
          )
          .toList();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<String> generateCertificateHtml({
    required int certificateAssignmentId,
  }) async {
    try {
      final htmlContent = await Api.postRaw(
        url: Api.generateCertificate,
        useAuthToken: true,
        body: {
          'id': certificateAssignmentId,
          'school_code': Api.headers()['school-code'] ?? '',
        },
      );

      if (htmlContent.isEmpty) {
        throw ApiException('Empty certificate response');
      }

      return htmlContent;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
