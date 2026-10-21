import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eschool/app/schoolBuildConfig.dart';
import 'package:eschool/data/repositories/authRepository.dart';
import 'package:eschool/utils/constants.dart';
import 'package:eschool/utils/curlLoggerInterceptor.dart';
import 'package:eschool/utils/errorMessageKeysAndCodes.dart';
import 'package:eschool/utils/unauthenticatedAccessManager.dart';
import 'package:flutter/foundation.dart';

class ApiException implements Exception {
  String errorMessage;

  ApiException(this.errorMessage);

  @override
  String toString() {
    return errorMessage;
  }
}

// ignore: avoid_classes_with_only_static_members
class Api {
  /// Tells the backend which kind of app is calling: `general` or
  /// `school-specific` ([SchoolBuildConfig.appType]). Only the login requests
  /// and the splash screen's settings request send it, each by passing
  /// `sendAppType: true`.
  static const String appTypeHeader = "App-Type";

  /// Names the school a request is for. Signed-in requests always send it;
  /// a signed-out request sends it only when it passes `schoolCode`.
  static const String schoolCodeHeader = "school-code";

  static Map<String, dynamic> headers() {
    final String jwtToken = AuthRepository().getJwtToken();
    final schoolCode = AuthRepository().schoolCode;

    if (kDebugMode) {
      debugPrint(jwtToken);
    }

    return {
      "Authorization": "Bearer $jwtToken",
      schoolCodeHeader: schoolCode,
      "Accept": "application/json",
    };
  }

  /// The headers of one request: the signed-in user's when [useAuthToken],
  /// plus [appTypeHeader] when [sendAppType] and [schoolCodeHeader] when
  /// [schoolCode] is given. Null when there are none.
  @visibleForTesting
  static Map<String, dynamic>? requestHeaders({
    required bool useAuthToken,
    bool sendAppType = false,
    String? schoolCode,
  }) {
    if (!useAuthToken && !sendAppType && schoolCode == null) return null;
    return {
      if (useAuthToken) ...headers(),
      if (sendAppType) appTypeHeader: SchoolBuildConfig.appType,
      if (schoolCode != null) schoolCodeHeader: schoolCode,
    };
  }

  ///[General Apis]
  //Apis that will be use in both student and parent app
  //
  static String logout = "${databaseUrl}logout";
  static String settings = "${databaseUrl}settings";
  static String schoolSettings = "${databaseUrl}school-settings";

  /// Panel-managed localization. Despite its name, `set-languages` is the
  /// backend endpoint that RETURNS the label values of a language for a given
  /// app type — it does not mutate anything on the panel.
  static String getLanguages = "${databaseUrl}get-languages";
  static String getLanguageLabels = "${databaseUrl}set-languages";
  static String holidays = "${databaseUrl}holidays";
  static String notifications = "${databaseUrl}notifications";

  static String changePassword = "${databaseUrl}change-password";
  static String getSchoolGallery = "${databaseUrl}gallery";
  static String getSchoolSessionYears = "${databaseUrl}session-years";
  static String getSemesters = "${databaseUrl}semester";
  static String getUsers = "${databaseUrl}users";
  static String getUserChatHistory = "${databaseUrl}users/chat/history";
  static String chatMessages = "${databaseUrl}message";
  static String readMessages = "${databaseUrl}message/read";
  static String deleteMessages = "${databaseUrl}delete/message";
  static String schoolDetails = "${databaseUrl}school-details";
  //
  //
  ///[Student app apis]
  //
  static String studentLogin = "${databaseUrl}student/login";
  static String studentProfile = "${databaseUrl}student/get-profile-data";
  static String studentSubjects = "${databaseUrl}student/subjects";
  //get subjects of given class
  static String classSubjects = "${databaseUrl}student/class-subjects";
  static String studentTimeTable = "${databaseUrl}student/timetable";
  static String studentExamList = "${databaseUrl}student/get-exam-list";

  static String getSchoolSettingDetails =
      "${databaseUrl}student/school-settings";

  static String studentExamDetails = "${databaseUrl}student/get-exam-details";
  static String selectStudentElectiveSubjects =
      "${databaseUrl}student/select-subjects";
  static String getLessonsOfSubject = "${databaseUrl}student/lessons";
  static String getstudyMaterialsOfTopic =
      "${databaseUrl}student/lesson-topics";
  static String getStudentAttendance = "${databaseUrl}student/attendance";
  static String getAssignments = "${databaseUrl}student/assignments";
  static String submitAssignment = "${databaseUrl}student/submit-assignment";
  static String generalAnnouncements = "${databaseUrl}student/announcements";
  static String guardianDetailsOfStudent =
      "${databaseUrl}student/guradian-details";
  static String deleteAssignment =
      "${databaseUrl}student/delete-assignment-submission";

  static String studentResults = "${databaseUrl}student/exam-marks";
  static String requestResetPassword = "${databaseUrl}student/forgot-password";

  static String studentExamOnlineList =
      "${databaseUrl}student/get-online-exam-list";
  static String studentExamOnlineQuestions =
      "${databaseUrl}student/get-online-exam-questions";
  static String studentSubmitOnlineExamAnswers =
      "${databaseUrl}student/submit-online-exam-answers";

  static String studentOnlineExamResultList =
      "${databaseUrl}student/get-online-exam-result-list";

  static String studentOnlineExamResult =
      "${databaseUrl}student/get-online-exam-result";

  static String studentOnlineExamReport =
      "${databaseUrl}student/get-online-exam-report";
  static String studentAssignmentReport =
      "${databaseUrl}student/get-assignments-report";
  static String studentSubjectReport = "${databaseUrl}student/report";

  static String getStudentSliders = "${databaseUrl}student/sliders";

  //
  ///[Parent app apis]
  //
  static String subjectsByChildId = "${databaseUrl}parent/subjects";
  static String parentLogin = "${databaseUrl}parent/login";
  static String getParentData = "${databaseUrl}parent/get-data";

  //
  static String childProfileDetails =
      "${databaseUrl}parent/get-child-profile-data";
  static String lessonsOfSubjectParent = "${databaseUrl}parent/lessons";
  static String getstudyMaterialsOfTopicParent =
      "${databaseUrl}parent/lesson-topics";
  static String getAssignmentsParent = "${databaseUrl}parent/assignments";
  static String getParentChildSchoolSettingDetails =
      "${databaseUrl}parent/school-settings";
  static String getStudentAttendanceParent = "${databaseUrl}parent/attendance";
  static String getStudentTimetableParent = "${databaseUrl}parent/timetable";
  static String getStudentExamListParent = "${databaseUrl}parent/get-exam-list";
  static String getStudentResultsParent = "${databaseUrl}parent/exam-marks";
  static String getStudentExamDetailsParent =
      "${databaseUrl}parent/get-exam-details";

  static String generalAnnouncementsParent =
      "${databaseUrl}parent/announcements";

  static String getStudentTeachersParent = "${databaseUrl}teachers";
  static String forgotPassword = "${databaseUrl}forgot-password";

  static String getStudentFeesDetailParent = "${databaseUrl}parent/fees";
  static String addFeesTransaction =
      "${databaseUrl}parent/add-fees-transaction";
  static String failPaymentTransaction =
      "${databaseUrl}parent/fail-payment-transaction";
  static String storeFeesParent = "${databaseUrl}parent/store-fees";

  static String getPaidFeesListParent = "${databaseUrl}parent/fees-paid-list";

  static String parentExamOnlineList =
      "${databaseUrl}parent/get-online-exam-list";
  static String parentOnlineExamResultList =
      "${databaseUrl}parent/get-online-exam-result-list";
  static String parentOnlineExamResult =
      "${databaseUrl}parent/get-online-exam-result";
  static String parentOnlineExamReport =
      "${databaseUrl}parent/get-online-exam-report";
  static String parentAssignmentReport =
      "${databaseUrl}parent/get-assignments-report";

  /// A child's fee payment history — every gateway, cash and manual payment
  /// recorded against their fees, newest first. Paged.
  static String getFeesTransactions =
      "${databaseUrl}parent/fees/fees-transactions";

  /// Receipt for a settled fee payment. A gateway or cash payment has no
  /// receipt on the transaction itself — only the ids needed to fetch one here.
  static String getFeeTransactionReceipt =
      "${databaseUrl}parent/fees/transaction-receipt";

  static String getParentSliders = "${databaseUrl}parent/sliders";

  static String payChildCompulsoryFees =
      "${databaseUrl}parent/fees/compulsory/pay";

  static String payChildOptionalFees = "${databaseUrl}parent/fees/optional/pay";

  /// Manual (offline) fee payment — the parent has already paid the school
  /// directly and uploads the receipt for verification. Mirrors the
  /// compulsory/optional split of the gateway endpoints above, but takes a
  /// receipt file instead of a payment method and returns no payment intent:
  /// nothing is charged here, the school approves it later.
  ///
  /// The receipt's size limit is enforced by the backend only — it is an admin
  /// setting that can be raised without shipping a new app build.
  static String payChildCompulsoryFeesManual =
      "${databaseUrl}parent/fees/manual/compulsory/pay";
  static String payChildOptionalFeesManual =
      "${databaseUrl}parent/fees/manual/optional/pay";
  static String confirmPayment = "${databaseUrl}payment-confirmation";
  static String getTransactions = "${databaseUrl}payment-transactions";
  static String downloadFeeReceipt = "${databaseUrl}parent/fees/receipt";
  static String downloadStudentResult = "${databaseUrl}student-exan-result-pdf";
  static String downloadStudentIdCard = "${databaseUrl}student/id-card";

  /// Student Leave
  /// Parent applies, lists and cancels leave on behalf of a child. Approval is
  /// taken on the staff side, so the parent app never writes a leave status.
  static String studentLeave = "${databaseUrl}parent/student/leave";
  static String cancelStudentLeave =
      "${databaseUrl}parent/student/leave/cancel";

  /// School-wide leave configuration: the weekly off days and the public
  /// holiday calendar. Shared with the staff app, which reads the same
  /// endpoint when a staff member applies for leave.
  static String getLeaveSettings = "${databaseUrl}leave-settings";

  /// Certificate
  static String getCertificateAssignments = "${databaseUrl}certificate/assign";
  static String generateCertificate = "${databaseUrl}certificate/generate";

  static String getDiaries = "${databaseUrl}diaries";
  static String getStudentDetails = "${databaseUrl}student-details";
  static String getStudentDiaryCategories =
      "${databaseUrl}student/diary-categories";
  static String getParentDiaryCategories =
      "${databaseUrl}parent/diary-categories";

  /// Transportation
  static String getPickupPoints = "${databaseUrl}pickup-points";
  static String getTransportationShifts = "${databaseUrl}transportation-shifts";
  static String getTransportationFees = "${databaseUrl}transportation-fees";
  static String payTransportationFees = "${databaseUrl}transportation-payments";
  static String getTransportDashboard = "${databaseUrl}transport/dashboard";
  static String getVehicleAssignmentStatus =
      "${databaseUrl}get-vehicle-assignment-status";
  static String getCurrentTransportPlan =
      "${databaseUrl}transport/plans/current";
  static String getRouteStops = "${databaseUrl}transport/routes/stops";
  static String getLiveRoute = "${databaseUrl}transportation/live-route";

  /// Mints a short-lived, tracking-only link to the web live map for one
  /// student, so it can be opened in a WebView with no web login. The link
  /// carries its own scoped token; the app never sends that token itself.
  static String createLiveTrackingLink =
      "${databaseUrl}transportation/live-tracking/link";
  static String getTransportAttendanceList =
      "${databaseUrl}transport/user/attendance-list";
  static String getTransportRequests = "${databaseUrl}transport/requests";
  static String storeTripReports = "${databaseUrl}transport/store-trip-reports";
  static String getTransportReceipt = "${databaseUrl}transport/receipt";

  //

  static Future<Map<String, dynamic>> post({
    required Map<String, dynamic> body,
    required String url,
    required bool useAuthToken,
    bool sendAppType = false,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Function(int, int)? onSendProgress,
    Function(int, int)? onReceiveProgress,
  }) async {
    try {
      // Block all API calls if user has been logged out due to 401
      if (useAuthToken && UnauthenticatedAccessManager().isLoggedOut) {
        throw ApiException(
          ErrorMessageKeysAndCode.unauthenticatedErrorCode,
        );
      }

      final Dio dio = Dio();
      final FormData formData =
          FormData.fromMap(body, ListFormat.multiCompatible);
      if (kDebugMode) {
        debugPrint("API Called POST: $url with $body");
        debugPrint("Body Params: $body");
      }
      dio.interceptors.add(CurlLoggerInterceptor(
        printOnSuccess: true,
        printOnError: true,
        convertFormData: true,
      ));

      final response = await dio.post(
        url,
        data: formData,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
        onSendProgress: onSendProgress,
        options: Options(
          headers: requestHeaders(
            useAuthToken: useAuthToken,
            sendAppType: sendAppType,
          ),
        ),
      );

      if (bool.parse(response.data['error'].toString())) {
        // Check if the error is a 401 (Unauthenticated) in the JSON body
        final responseCode = response.data['code']?.toString();
        if (responseCode == '401' && useAuthToken) {
          UnauthenticatedAccessManager().handleUnauthorizedAccess();
          throw ApiException(
            ErrorMessageKeysAndCode.unauthenticatedErrorCode,
          );
        }
        throw ApiException(response.data['message'].toString());
      }

      if (kDebugMode) {
        debugPrint("Response: ${response.data}");
      }
      return Map.from(response.data);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(e.response?.data?.toString());
      }
      if (e.response?.statusCode == 401 && useAuthToken) {
        UnauthenticatedAccessManager().handleUnauthorizedAccess();
        throw ApiException(ErrorMessageKeysAndCode.unauthenticatedErrorCode);
      }
      if (e.response?.statusCode == 503 || e.response?.statusCode == 500) {
        throw ApiException(ErrorMessageKeysAndCode.internetServerErrorCode);
      }

      throw ApiException(
        e.error is SocketException
            ? ErrorMessageKeysAndCode.noInternetCode
            : ErrorMessageKeysAndCode.defaultErrorMessageCode,
      );
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage);
    } catch (e) {
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageCode);
    }
  }

  /// Same as [post] but returns the raw response body as a
  /// [String] instead of parsing JSON. Use this for endpoints
  /// that return non-JSON responses (e.g. HTML).
  static Future<String> postRaw({
    required Map<String, dynamic> body,
    required String url,
    required bool useAuthToken,
  }) async {
    try {
      if (useAuthToken && UnauthenticatedAccessManager().isLoggedOut) {
        throw ApiException(
          ErrorMessageKeysAndCode.unauthenticatedErrorCode,
        );
      }

      final Dio dio = Dio();
      final FormData formData =
          FormData.fromMap(body, ListFormat.multiCompatible);
      if (kDebugMode) {
        debugPrint("API Called POST Raw: $url with $body");
      }
      dio.interceptors.add(CurlLoggerInterceptor(
        printOnSuccess: true,
        printOnError: true,
        convertFormData: true,
      ));

      final response = await dio.post(
        url,
        data: formData,
        options: Options(
          headers: useAuthToken ? headers() : null,
          responseType: ResponseType.plain,
        ),
      );

      if (kDebugMode) {
        debugPrint("Raw Response length: ${response.data?.toString().length}");
      }

      final rawBody = response.data?.toString() ?? '';

      // The API may return a JSON error even though we requested
      // a plain-text response.  Detect that case and throw so the
      // caller never accidentally treats the error JSON as valid HTML.
      try {
        final decoded = jsonDecode(rawBody);
        if (decoded is Map<String, dynamic>) {
          final isError = decoded['error'] == true ||
              decoded['error']?.toString() == 'true';
          if (isError) {
            final message = decoded['message']?.toString() ??
                ErrorMessageKeysAndCode.defaultErrorMessageCode;
            throw ApiException(message);
          }
        }
      } on ApiException {
        rethrow;
      } catch (_) {
        // Not valid JSON — that's fine, it's the HTML we expect.
      }

      return rawBody;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(e.response?.data?.toString());
      }
      if (e.response?.statusCode == 401 && useAuthToken) {
        UnauthenticatedAccessManager().handleUnauthorizedAccess();
        throw ApiException(ErrorMessageKeysAndCode.unauthenticatedErrorCode);
      }
      if (e.response?.statusCode == 503 || e.response?.statusCode == 500) {
        throw ApiException(ErrorMessageKeysAndCode.internetServerErrorCode);
      }

      throw ApiException(
        e.error is SocketException
            ? ErrorMessageKeysAndCode.noInternetCode
            : ErrorMessageKeysAndCode.defaultErrorMessageCode,
      );
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage);
    } catch (e) {
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageCode);
    }
  }

  /// [schoolCode] names the school on a request made before login, where
  /// there is no signed-in user to take it from.
  static Future<Map<String, dynamic>> get({
    required String url,
    required bool useAuthToken,
    bool sendAppType = false,
    String? schoolCode,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      // Block all API calls if user has been logged out due to 401
      if (useAuthToken && UnauthenticatedAccessManager().isLoggedOut) {
        throw ApiException(
          ErrorMessageKeysAndCode.unauthenticatedErrorCode,
        );
      }

      final Dio dio = Dio();

      if (kDebugMode) {
        debugPrint(url);
        debugPrint(queryParameters.toString());
      }
      dio.interceptors.add(CurlLoggerInterceptor(
        printOnSuccess: true,
        printOnError: true,
        convertFormData: true,
      ));
      final response = await dio.get(
        url,
        queryParameters: queryParameters,
        options: Options(
          headers: requestHeaders(
            useAuthToken: useAuthToken,
            sendAppType: sendAppType,
            schoolCode: schoolCode,
          ),
        ),
      );

      if (response.data['error']) {
        if (kDebugMode) {
          debugPrint("Url $url");
          debugPrint(response.data.toString());
        }
        // Check if the error is a 401 (Unauthenticated) in the JSON body
        final responseCode = response.data['code']?.toString();
        if (responseCode == '401' && useAuthToken) {
          UnauthenticatedAccessManager().handleUnauthorizedAccess();
          throw ApiException(
            ErrorMessageKeysAndCode.unauthenticatedErrorCode,
          );
        }
        throw ApiException(response.data['code'].toString());
      }

      return Map.from(response.data);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint("Url is $url");
        debugPrint(e.response?.data?.toString());
        debugPrint(e.response?.statusCode.toString());
      }

      if (e.response?.statusCode == 401 && useAuthToken) {
        UnauthenticatedAccessManager().handleUnauthorizedAccess();
        throw ApiException(ErrorMessageKeysAndCode.unauthenticatedErrorCode);
      }
      if (e.response?.statusCode == 503 || e.response?.statusCode == 500) {
        throw ApiException(ErrorMessageKeysAndCode.internetServerErrorCode);
      }
      throw ApiException(
        e.error is SocketException
            ? ErrorMessageKeysAndCode.noInternetCode
            : ErrorMessageKeysAndCode.defaultErrorMessageCode,
      );
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageCode);
    }
  }

  static Future<void> download({
    required String url,
    required CancelToken cancelToken,
    required String savePath,
    required Function updateDownloadedPercentage,
  }) async {
    try {
      final Dio dio = Dio();

      await dio.download(
        url,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: (count, total) {
          final double percentage = (count / total) * 100;
          updateDownloadedPercentage(percentage < 0.0 ? 99.0 : percentage);
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        UnauthenticatedAccessManager().handleUnauthorizedAccess();
        throw ApiException(ErrorMessageKeysAndCode.unauthenticatedErrorCode);
      }
      if (e.response?.statusCode == 503 || e.response?.statusCode == 500) {
        throw ApiException(ErrorMessageKeysAndCode.internetServerErrorCode);
      }
      if (e.response?.statusCode == 404) {
        throw ApiException(ErrorMessageKeysAndCode.fileNotFoundErrorCode);
      }
      throw ApiException(
        e.error is SocketException
            ? ErrorMessageKeysAndCode.noInternetCode
            : ErrorMessageKeysAndCode.defaultErrorMessageCode,
      );
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage);
    } catch (e) {
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageCode);
    }
  }
}
