import 'dart:io';

import 'package:eschool/app/schoolBuildConfig.dart';
import 'package:eschool/data/models/guardian.dart';
import 'package:eschool/data/models/student.dart';
import 'package:eschool/utils/api.dart';
import 'package:eschool/utils/hiveBoxKeys.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class AuthRepository {
  //LocalDataSource
  bool getIsLogIn() {
    return Hive.box(authBoxKey).get(isLogInKey) ?? false;
  }

  Future<void> setIsLogIn(bool value) async {
    return Hive.box(authBoxKey).put(isLogInKey, value);
  }

  static bool getIsStudentLogIn() {
    return Hive.box(authBoxKey).get(isStudentLogInKey) ?? false;
  }

  Future<void> setIsStudentLogIn(bool value) async {
    return Hive.box(authBoxKey).put(isStudentLogInKey, value);
  }

  static Student getStudentDetails() {
    return Student.fromJson(
      Map.from(Hive.box(authBoxKey).get(studentDetailsKey) ?? {}),
    );
  }

  Future<void> setStudentDetails(Student student) async {
    return Hive.box(authBoxKey).put(studentDetailsKey, student.toJson());
  }

  // Profile data methods for updated student information
  Student getStudentProfileData() {
    return Student.fromJson(
      Map.from(Hive.box(authBoxKey).get(studentProfileDataKey) ??
          Hive.box(authBoxKey).get(studentDetailsKey) ??
          {}),
    );
  }

  Future<void> setStudentProfileData(Student student) async {
    return Hive.box(authBoxKey).put(studentProfileDataKey, student.toJson());
  }

  Future<void> clearStudentProfileData() async {
    return Hive.box(authBoxKey).delete(studentProfileDataKey);
  }

  static Guardian getParentDetails() {
    return Guardian.fromJson(
      Map.from(Hive.box(authBoxKey).get(parentDetailsKey) ?? {}),
    );
  }

  Future<void> setParentDetails(Guardian parent) async {
    return Hive.box(authBoxKey).put(parentDetailsKey, parent.toJson());
  }

  String getJwtToken() {
    return Hive.box(authBoxKey).get(jwtTokenKey) ?? "";
  }

  Future<void> setJwtToken(String value) async {
    return Hive.box(authBoxKey).put(jwtTokenKey, value);
  }

  String getFcmToken() {
    return Hive.box(authBoxKey).get(fcmTokenKey) ?? "";
  }

  Future<void> setFcmToken(String value) async {
    return Hive.box(authBoxKey).put(fcmTokenKey, value);
  }

  /// On a build locked to one school, the compiled-in code wins over Hive.
  String get schoolCode => SchoolBuildConfig.hasFixedSchoolCode
      ? SchoolBuildConfig.schoolCode
      : Hive.box(authBoxKey).get(schoolCodeKey, defaultValue: "") as String;

  set schoolCode(String value) =>
      Hive.box(authBoxKey).put(schoolCodeKey, value);

  Future<void> signOutUser() async {
    try {
      // Get the current FCM token from Hive before clearing
      final String currentFcmToken = getFcmToken();

      // Send FCM token to backend for clearing
      final body = {
        if (currentFcmToken.isNotEmpty) "fcm_id": currentFcmToken,
      };

      await Api.post(body: body, url: Api.logout, useAuthToken: true);
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Logout API error: $e");
      }
      // Continue with local logout even if API fails
    }

    // Clear all local data
    setIsLogIn(false);
    setJwtToken("");
    setFcmToken(""); // Clear FCM token from Hive
    setStudentDetails(Student.fromJson({}));
    setParentDetails(Guardian.fromJson({}));
    clearStudentProfileData();
  }

  //RemoteDataSource
  Future<Map<String, dynamic>> signInStudent({
    required String grNumber,
    required String schoolCode,
    required String password,
  }) async {
    try {
      String? fcmToken;

      try {
        // Request permissions before getting token (required for iOS)

        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('FCM token retrieval failed: $e');
        }
        // Continue with null token if FCM fails
        fcmToken = null;
      }

      final body = {
        "password": password,
        "school_code": schoolCode,
        "gr_number": grNumber,
        "fcm_id": fcmToken,
        "device_type": Platform.isIOS ? "ios" : "android",
      };

      final result = await Api.post(
        body: body,
        url: Api.studentLogin,
        useAuthToken: false,
        sendAppType: true,
      );

      final data = result['data'] as Map<String, dynamic>;
      final school = data['school'] as Map<String, dynamic>;

      // Store FCM token in Hive for later use (e.g., during logout)
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await setFcmToken(fcmToken);
      }

      return {
        "jwtToken": result['token'],
        "schoolCode": school['code'],
        "student": Student.fromJson(Map.from(result['data']))
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }

      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> signInParent({
    required String email,
    required String schoolCode,
    required String password,
  }) async {
    try {
      String? fcmToken;

      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('FCM token retrieval failed: $e');
        }
        // Continue with null token if FCM fails
        fcmToken = null;
      }

      final body = {
        "password": password,
        "email": email,
        "school_code": schoolCode,
        "fcm_id": fcmToken,
        "device_type": Platform.isIOS ? "ios" : "android",
      };

      final result = await Api.post(
        body: body,
        url: Api.parentLogin,
        useAuthToken: false,
        sendAppType: true,
      );

      // Store FCM token in Hive for later use (e.g., during logout)
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await setFcmToken(fcmToken);
      }

      return {
        "jwtToken": result['token'],
        "parent": Guardian.fromJson(Map.from(result['data'] ?? {}))
      };
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint("this is the stack trace: $st");
        debugPrint("this is the error: $e");
      }
      throw ApiException(e.toString());
    }
  }

  Future<void> resetPasswordRequest(
      {required String grNumber,
      required DateTime dob,
      required String schoolCode}) async {
    try {
      final body = {
        "school_code": schoolCode,
        "gr_no": grNumber,
        "dob": DateFormat('yyyy-MM-dd').format(dob)
      };
      await Api.post(
        body: body,
        url: Api.requestResetPassword,
        useAuthToken: false,
      );
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newConfirmedPassword,
  }) async {
    try {
      final body = {
        "current_password": currentPassword,
        "new_password": newPassword,
        "new_confirm_password": newConfirmedPassword
      };
      await Api.post(body: body, url: Api.changePassword, useAuthToken: true);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<void> forgotPassword(
      {required String email, required String schoolCode}) async {
    try {
      final body = {
        "email": email,
        "school_code": schoolCode,
      };
      await Api.post(body: body, url: Api.forgotPassword, useAuthToken: false);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Guardian> getParentData() async {
    try {
      final result = await Api.get(
        url: Api.getParentData,
        useAuthToken: true,
      );

      return Guardian.fromJson(Map.from(result['data'] ?? {}));
    } catch (e, st) {
      print("This is the stack trace: $st");
      print("This is the error: $e");
      throw ApiException(e.toString());
    }
  }
}
