import 'package:eschool/utils/api.dart';

class TripReportRepository {
  Future<Map<String, dynamic>> submitTripReport({
    required int routeVehicleHistoryId,
    required String description,
  }) async {
    try {
      final result = await Api.post(
        url: Api.storeTripReports,
        useAuthToken: true,
        body: {
          'route_vehicle_history_id': routeVehicleHistoryId.toString(),
          'description': description,
        },
      );
      return result;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
