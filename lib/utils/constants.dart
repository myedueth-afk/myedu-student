import 'package:eschool/app/schoolBuildConfig.dart';
import 'package:eschool/utils/labelKeys.dart';

//database urls
//Please add your admin panel url here and make sure you do not add '/' at the end of the url

//Overridable per school by the School Builder addon (runtime.baseUrl).
const String baseUrl = String.fromEnvironment(
  "SCHOOL_BASE_URL",
  defaultValue: "https://myedu.et",
);
const String databaseUrl = "$baseUrl/api/";

// Reverb WebSocket configuration
const String reverbUrl = "wss://myedu.et/app/e2mhe9gu4tb2x2vkncxa";

//error message display duration
const Duration errorMessageDisplayDuration = Duration(milliseconds: 3000);

// Reverb reconnect base delay (used with exponential backoff)
const Duration reverbReconnectDelay = Duration(seconds: 3);

//home menu bottom sheet animation duration
const Duration homeMenuBottomSheetAnimationDuration = Duration(
  milliseconds: 300,
);

//Change slider duration
const Duration changeSliderDuration = Duration(seconds: 5);

//Number of latest notices to show in home container
const int numberOfLatestNoticesInHomeScreen = 3;

//Number of online classes to show in the home/student-details container
//(the "View All" button leads to the full timetable)
const int numberOfOnlineClassesInHomeScreen = 3;

//Maximum characters to show in announcement description before "Read More"
const int maxAnnouncementDescriptionLength = 100;

//notification channel keys
const String notificationChannelKey = "basic_channel";

// //to enable and disable default credentials in login page
//Off for school builds (see SchoolBuildConfig.showDemoCredentials).
const bool showDefaultCredentials = SchoolBuildConfig.showDemoCredentials;

// //default credentials of student
const String defaultStudentGRNumber = "";
const String defaultStudentPassword = "";
//default credentials of parent
const String defaultParentEmail = "";
const String defaultParentPassword = "";
// Default school code
const String defaultSchoolCode = "";

/// When [true], screenshots and screen recording are blocked on
/// sensitive screens (Online Exam, Payment WebView).
/// Set to [false] to disable screen protection.
const bool isScreenProtectionEnabled = true;

//animations configuration
//if this is false all item appearance animations will be turned off
const bool isApplicationItemAnimationOn = true;
//note: do not add Milliseconds values less then 10 as it'll result in errors
const int listItemAnimationDelayInMilliseconds = 100;
const int itemFadeAnimationDurationInMilliseconds = 250;
const int itemZoomAnimationDurationInMilliseconds = 200;
const int itemBouncScaleAnimationDurationInMilliseconds = 200;
const double appContentHorizontalPadding = 15.0;
double bottomsheetBorderRadius = 15.0;
double topPaddingOfErrorAndLoadingContainer = 150;

String getExamStatusTypeKey(String examStatus) {
  if (examStatus == "0") {
    return upComingKey;
  }
  if (examStatus == "1") {
    return onGoingKey;
  }
  return completedKey;
}

List<String> examFilters = [allExamsKey, upComingKey, onGoingKey, completedKey];

int getExamStatusBasedOnFilterKey({required String examFilter}) {
  ///[Exam status: 0- Upcoming, 1-On Going, 2-Completed, 3-All Details]
  if (examFilter == upComingKey) {
    return 0;
  }

  if (examFilter == onGoingKey) {
    return 1;
  }

  if (examFilter == completedKey) {
    return 2;
  }

  return 3;
}

const int minimumPasswordLength = 6;

const String stripePaymentMethodKey = "Stripe";
const String razorpayPaymentMethodKey = "Razorpay";
const String flutterwavePaymentMethodKey = "Flutterwave";
const String paystackPaymentMethodKey = "Paystack";
const String chapaPaymentMethodKey = "Chapa";

/// Manual payment arrives in the same `payment_gateway` list as the online
/// gateways, but it is not one — it has no SDK, no api key and no order to
/// create. Everything that drives a gateway checkout must therefore read
/// [SchoolConfiguration.onlinePaymentGateways], which filters this entry out.
const String manualPaymentMethodKey = "Manual";

///[Payment transaction status this must be in sync with backend]
const String pendingTransactionStatusKey = "pending";
const String failedTransactionStatusKey = "failed";
const String succeedTransactionStatusKey = "succeed";

List<String> months = [
  januaryKey,
  februaryKey,
  marchKey,
  aprilKey,
  mayKey,
  juneKey,
  julyKey,
  augustKey,
  septemberKey,
  octoberKey,
  novemberKey,
  decemberKey,
];

/// File types a parent may attach to a student leave request. Mirrors the
/// validation the leave endpoint applies server side.
const List<String> studentLeaveAllowedFileExtensions = [
  "jpg",
  "jpeg",
  "png",
  "pdf",
  "doc",
  "docx",
];

/// Longest note the manual payment endpoints accept, per their schema.
///
/// Unlike the receipt's size limit — an admin setting the panel can raise —
/// this one is fixed by the API contract, so the field simply stops accepting
/// more rather than letting the parent write a note that would be rejected
/// after the receipt has already uploaded.
const int manualPaymentNoteMaxLength = 1000;

/// File types offered when picking proof of a manual fee payment. This only
/// filters the picker — the receipt's size and type are validated by the
/// backend, whose limits are admin settings and can change without an app
/// release, so nothing here duplicates them.
const List<String> manualPaymentReceiptAllowedFileExtensions = [
  "jpg",
  "jpeg",
  "png",
  "pdf",
  "doc",
  "docx",
];

/// Transport Report Issue Label Keys
const List<String> transportReportIssueLabelKeys = [
  unsafeDrivingKey,
  unauthorizedPersonKey,
  missedPickupKey,
  uncleanBusInteriorKey,
  busBreakdownKey,
];
