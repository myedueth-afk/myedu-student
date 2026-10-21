import 'package:dio/dio.dart';
import 'package:eschool/data/models/leaveSettings.dart';
import 'package:eschool/data/models/publicHoliday.dart';
import 'package:eschool/data/models/studentLeave.dart';
import 'package:eschool/utils/api.dart';

class StudentLeaveRepository {
  /// Weekly offs and the public holiday calendar. This is the same school-wide
  /// endpoint the staff app reads when a staff member applies for leave.
  Future<({LeaveSettings leaveSettings, List<PublicHoliday> publicHolidays})>
      getLeaveSettings() async {
    try {
      final result =
          await Api.get(url: Api.getLeaveSettings, useAuthToken: true);
      final data = result['data'];

      //`leave_settings` is a single-entry list; older payloads sent the list
      //as `data` itself
      final settingsList = data is Map
          ? ((data['leave_settings'] as List?) ?? [])
          : (data is List ? data : const []);

      final leaveSettings = settingsList.isEmpty
          ? LeaveSettings.fromJson({})
          : LeaveSettings.fromJson(Map.from(settingsList.first ?? {}));

      final publicHolidays = data is Map
          ? (((data['public_holidays'] as List?) ?? [])
              .map((holiday) => PublicHoliday.fromJson(Map.from(holiday ?? {})))
              .where((holiday) => holiday.date != null)
              .toList())
          : <PublicHoliday>[];

      return (leaveSettings: leaveSettings, publicHolidays: publicHolidays);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<List<StudentLeave>> getStudentLeaves({int? childId}) async {
    try {
      final result = await Api.get(
        url: Api.studentLeave,
        useAuthToken: true,
        queryParameters: childId == null ? {} : {"child_id": childId},
      );

      return ((result['data'] ?? []) as List)
          .map((leave) => StudentLeave.fromJson(Map.from(leave ?? {})))
          .toList();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<void> applyStudentLeave({
    required int childId,
    required String fromDate,
    required String toDate,
    required String reason,
    List<String>? filePaths,
  }) async {
    try {
      final Map<String, dynamic> body = {
        "child_id": childId,
        "from_date": fromDate,
        "to_date": toDate,
        "reason": reason,
      };

      if (filePaths != null && filePaths.isNotEmpty) {
        final List<MultipartFile> files = [];
        for (var filePath in filePaths) {
          files.add(await MultipartFile.fromFile(filePath));
        }
        body["files"] = files;
      }

      await Api.post(url: Api.studentLeave, body: body, useAuthToken: true);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<void> cancelStudentLeave({required int leaveId}) async {
    try {
      await Api.post(
        url: Api.cancelStudentLeave,
        body: {"leave_id": leaveId},
        useAuthToken: true,
      );
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
