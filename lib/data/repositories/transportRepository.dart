import 'package:eschool/data/models/pickupPoint.dart';
import 'package:eschool/data/models/transportFee.dart';
import 'package:eschool/data/models/transportShift.dart';
import 'package:eschool/data/models/transportDashboard.dart';
import 'package:eschool/data/models/vehicleAssignmentStatus.dart';
import 'package:eschool/data/models/transportPlanDetails.dart';
import 'package:eschool/data/models/busRouteStops.dart';
import 'package:eschool/data/models/transportAttendance.dart';
import 'package:eschool/utils/api.dart';
import 'package:flutter/material.dart';

class TransportRepository {
  Future<List<PickupPoint>> getPickupPoints() async {
    try {
      final result =
          await Api.get(url: Api.getPickupPoints, useAuthToken: true);
      return ((result['data'] ?? []) as List)
          .map((e) => PickupPoint.fromJson(Map<String, dynamic>.from(e ?? {})))
          .toList();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<List<TransportShift>> getShifts({required int pickupPointId}) async {
    try {
      final result = await Api.get(
          url: Api.getTransportationShifts,
          queryParameters: {"pickup_point_id": pickupPointId},
          useAuthToken: true);
      return ((result['data'] ?? []) as List)
          .map((e) =>
              TransportShift.fromJson(Map<String, dynamic>.from(e ?? {})))
          .toList();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<TransportFeesResponse> getFees({required int pickupPointId}) async {
    try {
      final result = await Api.get(
          url: Api.getTransportationFees,
          queryParameters: {"pickup_point_id": pickupPointId},
          useAuthToken: true);
      return TransportFeesResponse.fromJson(result);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<TransportDashboard> getDashboard({
    required int userId,
  }) async {
    try {
      final result = await Api.post(
        url: Api.getTransportDashboard,
        useAuthToken: true,
        body: {
          'user_id': userId.toString(),
        },
      );
      return TransportDashboard.fromJson(Map.from(result['data'] ?? {}));
    } catch (e, st) {
      debugPrint("this is the error: $e");
      debugPrint("this is the stack trace: $st");
      throw ApiException(e.toString());
    }
  }

  Future<VehicleAssignmentStatus> getVehicleAssignmentStatus({
    required int userId,
  }) async {
    try {
      final result = await Api.post(
        url: Api.getVehicleAssignmentStatus,
        useAuthToken: true,
        body: {
          'user_id': userId.toString(),
        },
      );
      return VehicleAssignmentStatus.fromJson(Map.from(result));
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<TransportPlanDetails> getCurrentTransportPlan({
    required int userId,
  }) async {
    try {
      final result = await Api.post(
        url: Api.getCurrentTransportPlan,
        useAuthToken: true,
        body: {
          'user_id': userId.toString(),
        },
      );
      final data = result['data'];

      // API returns a List of plans — pick the active one
      if (data is List) {
        if (data.isEmpty) {
          return TransportPlanDetails();
        }
        // Find the first plan with 'active' status, or fall back to first
        final activePlan = data.firstWhere(
          (e) =>
              e is Map &&
              (e['plan_status']?.toString().toLowerCase() == 'active'),
          orElse: () => data.first,
        );
        return TransportPlanDetails.fromJson(
          Map<String, dynamic>.from(activePlan ?? {}),
        );
      }

      // Handle single Map response (backward compatibility)
      if (data is Map) {
        return TransportPlanDetails.fromJson(
          Map<String, dynamic>.from(data),
        );
      }

      return TransportPlanDetails();
    } catch (e, st) {
      debugPrint("this is the error: $e");
      debugPrint("this is the stack trace: $st");
      throw ApiException(e.toString());
    }
  }

  Future<BusRouteStops> getRouteStops({
    required int userId,
  }) async {
    try {
      final result = await Api.post(
        url: Api.getRouteStops,
        useAuthToken: true,
        body: {
          'user_id': userId.toString(),
        },
      );
      return BusRouteStops.fromJson(Map.from(result['data'] ?? {}));
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<TransportAttendanceResponse> getTransportAttendance({
    required int userId,
    required String month,
    required String tripType,
  }) async {
    try {
      final result = await Api.post(
        url: Api.getTransportAttendanceList,
        useAuthToken: true,
        body: {
          'user_id': userId.toString(),
          'month': month,
          'trip_type': tripType,
        },
      );
      return TransportAttendanceResponse.fromJson(Map.from(result));
    } catch (e) {
      throw Exception('Failed to get transport attendance: ${e.toString()}');
    }
  }

  Future<TransportRequestsResponse> getTransportRequests({
    required int userId,
  }) async {
    try {
      final result = await Api.post(
        url: Api.getTransportRequests,
        useAuthToken: true,
        body: {
          'user_id': userId.toString(),
        },
      );
      return TransportRequestsResponse.fromJson(Map.from(result));
    } catch (e) {
      throw Exception('Failed to get transport requests: ${e.toString()}');
    }
  }

  Future<List<TransportPlanDetails>> getTransportPlanHistory({
    required int userId,
  }) async {
    try {
      final result = await Api.post(
        url: Api.getCurrentTransportPlan,
        useAuthToken: true,
        body: {
          'user_id': userId.toString(),
        },
      );
      final data = result['data'];
      if (data is List) {
        return data
            .map((e) => TransportPlanDetails.fromJson(
                Map<String, dynamic>.from(e ?? {})))
            .toList();
      }
      if (data is Map) {
        return [TransportPlanDetails.fromJson(Map<String, dynamic>.from(data))];
      }
      return [];
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<String> getTransportReceipt({required int id}) async {
    try {
      final html = await Api.postRaw(
        url: Api.getTransportReceipt,
        useAuthToken: true,
        body: {
          'id': id.toString(),
          'school_code': Api.headers()['school-code'] ?? '',
        },
      );
      if (html.isEmpty) throw ApiException('Empty receipt response');
      return html;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
