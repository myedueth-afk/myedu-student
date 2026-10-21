import 'package:eschool/data/models/holiday.dart';
import 'package:eschool/utils/api.dart';
import 'package:flutter/foundation.dart';

class SystemRepository {
  Future<dynamic> fetchSettings({
    required String type,
    bool sendAppType = false,
  }) async {
    try {
      final result = await Api.get(
        queryParameters: {"type": type},
        url: Api.settings,
        useAuthToken: false,
        sendAppType: sendAppType,
      );

      return result['data'];
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  /// The splash screen's app settings: the only settings request that sends
  /// the `App-Type` header.
  Future<dynamic> fetchAppConfiguration() =>
      fetchSettings(type: "app_settings", sendAppType: true);

  Future<dynamic> fetchSchoolSettings({required String type}) async {
    try {
      final result = await Api.get(
        queryParameters: {"type": type},
        url: Api.schoolSettings,
        useAuthToken: true,
      );

      return result['data'];
    } catch (e, st) {
      debugPrint(st.toString());
      debugPrint(e.toString());
      throw ApiException(e.toString());
    }
  }

  /// A school's settings read before login: [schoolCode] alone names the
  /// school, as there is no token yet.
  Future<dynamic> fetchPublicSchoolSettings({
    required String type,
    required String schoolCode,
  }) async {
    try {
      final result = await Api.get(
        queryParameters: {"type": type},
        url: Api.schoolSettings,
        useAuthToken: false,
        schoolCode: schoolCode,
      );

      return result['data'];
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<List<Holiday>> fetchHolidays({int? childId}) async {
    try {
      final result = await Api.get(
          queryParameters: {"child_id": childId},
          url: Api.holidays,
          useAuthToken: true);

      return ((result['data'] ?? []) as List)
          .map((holiday) => Holiday.fromJson(Map.from(holiday)))
          .toList();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
