import 'package:eschool/data/models/liveRoute.dart';
import 'package:eschool/data/models/liveTrackingLink.dart';
import 'package:eschool/utils/api.dart';

class LiveRouteRepository {
  Future<LiveRouteResponse> getLiveRoute({required int userId}) async {
    try {
      final result = await Api.post(
        url: Api.getLiveRoute,
        useAuthToken: true,
        body: {
          'user_id': userId.toString(),
        },
      );
      return LiveRouteResponse.fromJson(result);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  /// Asks the backend for a link that shows [userId]'s bus on the web tracking
  /// page.
  ///
  /// [userId] is the student being tracked — the selected child, when a parent
  /// is signed in. The backend re-checks that the caller is allowed to track
  /// that student, so passing the wrong id here is refused rather than served;
  /// this is not a permission decision the app is trusted to have made.
  ///
  /// [tripId] pins the link to one trip. Leave it null to track whichever trip
  /// is running, which is what the transport home card wants.
  Future<LiveTrackingLink> createLiveTrackingLink({
    required int userId,
    int? tripId,
  }) async {
    try {
      final result = await Api.post(
        url: Api.createLiveTrackingLink,
        useAuthToken: true,
        body: {
          'user_id': userId.toString(),
          if (tripId != null) 'trip_id': tripId.toString(),
        },
      );
      return LiveTrackingLink.fromJson(
        Map<String, dynamic>.from(result['data'] ?? {}),
      );
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
