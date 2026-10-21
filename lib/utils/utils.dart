import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:eschool/cubits/appLocalizationCubit.dart';
import 'package:eschool/cubits/downloadFileCubit.dart';
import 'package:eschool/cubits/schoolConfigurationCubit.dart';
import 'package:eschool/data/models/studyMaterial.dart';
import 'package:eschool/data/repositories/subjectRepository.dart';
import 'package:eschool/ui/styles/colors.dart';
import 'package:eschool/ui/widgets/audioPlayerBottomsheetContainer.dart';
import 'package:eschool/ui/widgets/downloadFileBottomsheetContainer.dart';
import 'package:eschool/ui/widgets/errorMessageOverlayContainer.dart';
import 'package:eschool/utils/appLanguages.dart';
import 'package:eschool/utils/constants.dart';
import 'package:eschool/utils/errorMessageKeysAndCodes.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/systemModules.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';

// ignore: avoid_classes_with_only_static_members
class Utils {
  //This extra padding will add to MediaQuery.of(context).padding.top in orderto give same top padding in every screen

  static double screenContentTopPadding = 15.0;
  static double screenContentHorizontalPadding = 25.0;
  static double screenTitleFontSize = 18.0;
  static double screenOnbordingTitleFontSize = 25.0;
  static double screenContentHorizontalPaddingInPercentage = 0.075;

  static double screenSubTitleFontSize = 14.0;
  static double extraScreenContentTopPaddingForScrolling = 0.0275;
  static double appBarSmallerHeightPercentage = 0.15;

  static double appBarMediumtHeightPercentage = 0.18;

  static double bottomNavigationHeightPercentage = 0.08;
  static double bottomNavigationBottomMargin = 25;

  static double appBarBiggerHeightPercentage = 0.215;
  static double appBarContentTopPadding = 25.0;
  static double bottomSheetTopRadius = 20.0;
  static double subjectFirstLetterFontSize = 20;

  static double defaultProfilePictureHeightAndWidthPercentage = 0.175;

  static double questionContainerHeightPercentage = 0.725;

  static Duration tabBackgroundContainerAnimationDuration =
      const Duration(milliseconds: 300);

  static Duration showCaseDisplayDelayInDuration =
      const Duration(milliseconds: 350);
  static Curve tabBackgroundContainerAnimationCurve = Curves.easeInOut;

  static double shimmerLoadingContainerDefaultHeight = 7;

  static int defaultShimmerLoadingContentCount = 6;

  // static GlobalKey<NavigatorState> rootNavigatorKey =
  //     GlobalKey<NavigatorState>();

  static final List<String> weekDays = [
    mondayKey,
    tuesdayKey,
    wednesdayKey,
    thursdayKey,
    fridayKey,
    saturdayKey,
    sundayKey
  ];

  static final List<String> weekDaysFullForm = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday"
  ];

  //to give bottom scroll padding in screen where
  //bottom navigation bar is displayed
  static double getScrollViewBottomPadding(BuildContext context) {
    return MediaQuery.of(context).size.height *
            (Utils.bottomNavigationHeightPercentage) +
        Utils.bottomNavigationBottomMargin * (1.5);
  }

  //to give top scroll padding to screen content
  //
  static double getScrollViewTopPadding({
    required BuildContext context,
    required double appBarHeightPercentage,
  }) {
    return MediaQuery.of(context).size.height *
        (appBarHeightPercentage + extraScreenContentTopPaddingForScrolling);
  }

  static String getImagePath(String imageName) {
    return "assets/images/$imageName";
  }

  /// Returns the appropriate icon path based on the field type
  /// Used for displaying dynamic icons for form fields
  static String getIconForFieldType(String? fieldType) {
    switch (fieldType?.toLowerCase()) {
      case 'textarea':
        return getImagePath('text_fields.svg');
      case 'checkbox':
        return getImagePath('checkbox.svg');
      case 'radio':
        return getImagePath('radio_button_checked.svg');
      case 'text':
        return getImagePath('title.svg');
      case 'number':
        return getImagePath('numbers.svg');
      case 'dropdown':
        return getImagePath('chevron-down.svg');
      case 'file':
        return getImagePath('info_pro_icon.svg');
      default:
        return getImagePath('info_pro_icon.svg');
    }
  }

  static ColorScheme getColorScheme(BuildContext context) {
    return Theme.of(context).colorScheme;
  }

  /// Colour for a fee payment status (as returned by
  /// [ChildFeeDetails.getFeePaymentStatus]). Single source of truth so the fee
  /// list and the fee detail header stay in sync.
  ///
  /// These are chip fills on the fee screen, so they are the app's solid status
  /// colours — the ones already carrying white labels on the leave cards and
  /// the payment history — rather than the paler tints that only ever had to
  /// work as text on white.
  ///
  /// Two colours for the three settlement statuses, because there are only two
  /// answers a parent is asking for: settled, or still owing. Which kind of
  /// owing — nothing paid yet or part paid — is what the label says.
  ///
  /// Money waiting on the school is the exception, and gets the app's own blue:
  /// it is not a degree of owing but news about a payment, and it is that blue
  /// wherever else it appears — the list card's chip, the optional fee rows,
  /// the payment history. Amber here would say "still owing" about money the
  /// parent has already handed over.
  static Color getFeePaymentStatusColor(String statusKey) {
    if (statusKey == paidKey) {
      return transactionPaidColor;
    }
    if (statusKey == underReviewKey || statusKey == optionalUnderReviewKey) {
      return primaryColor;
    }
    return leavePendingColor;
  }

  /// The note shown under a payment the school has not confirmed yet.
  ///
  /// It has to name the payment the parent actually made: a cheque told it is
  /// waiting on a *manual payment* reads as a note about someone else's money.
  /// Shared by the fee screen and the transaction sheet so the two cannot
  /// describe the same payment differently.
  static String pendingPaymentNoteLabelKey(String? mode) {
    switch ((mode ?? '').toLowerCase()) {
      case 'manual':
        return manualPaymentPendingNoteKey;
      case 'cheque':
        return chequePendingNoteKey;
      default:
        //cash and gateway payments can sit unconfirmed too, and neither is a
        //manual payment either
        return paymentPendingNoteKey;
    }
  }

  static Locale getLocaleFromLanguageCode(String languageCode) {
    List<String> result = languageCode.split("-");
    return result.length == 1
        ? Locale(result.first)
        : Locale(result.first, result.last);
  }

  static String getTranslatedLabel(String labelKey) {
    return labelKey.tr.trim();
  }

  static Future<dynamic> showBottomSheet({
    required Widget child,
    required BuildContext context,
    bool? enableDrag,
  }) async {
    final result = await Get.bottomSheet(
      // Prevent
      isDismissible: true,
      child,
      enableDrag: enableDrag ?? false,
      isScrollControlled: true,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(bottomSheetTopRadius),
          topRight: Radius.circular(bottomSheetTopRadius),
        ),
      ),
    );
    return result;
  }

  /// Displays a fullscreen image preview with pinch-to-zoom support.
  /// Falls back silently if the [imageUrl] is empty.
  /// Resolves an image reference that may be either a remote url or an inline
  /// `data:` URI into a provider.
  ///
  /// Panel authored HTML embeds images (payment QR codes, for one) straight
  /// into the markup as base64, which [CachedNetworkImageProvider] cannot load
  /// — it would try to fetch the whole data URI as a url. Returns null when the
  /// reference is empty or the payload cannot be decoded, so callers can fall
  /// back rather than render a broken image.
  static ImageProvider? imageProviderFromSource(String source) {
    final trimmedSource = source.trim();
    if (trimmedSource.isEmpty) {
      return null;
    }

    if (!trimmedSource.startsWith('data:')) {
      return CachedNetworkImageProvider(trimmedSource);
    }

    final separatorIndex = trimmedSource.indexOf(',');
    //only base64 payloads are produced by the panel editor; a percent encoded
    //data uri would need different decoding, so it is treated as unusable
    if (separatorIndex == -1 ||
        !trimmedSource.substring(0, separatorIndex).contains('base64')) {
      return null;
    }

    try {
      return MemoryImage(
        base64Decode(
          trimmedSource
              .substring(separatorIndex + 1)
              .replaceAll(RegExp(r'\s'), ''),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> showImagePreview({
    required BuildContext context,
    required String imageUrl,
    String? heroTag,
  }) async {
    if (imageUrl.trim().isEmpty) {
      return;
    }

    await showGeneralDialog(
      context: context,
      barrierLabel: 'image_preview',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) {
        return _ImagePreviewDialog(
          imageUrl: imageUrl,
          heroTag: heroTag,
        );
      },
    );
  }

  static bool isTodayInSessionYear(DateTime firstDate, DateTime lastDate) {
    final currentDate = DateTime.now();

    return (currentDate.isAfter(firstDate) && currentDate.isBefore(lastDate)) ||
        isSameDay(firstDate) ||
        isSameDay(lastDate);
  }

  static bool isSameDay(DateTime dateTime) {
    final currentDate = DateTime.now();
    return (currentDate.day == dateTime.day) &&
        (currentDate.month == dateTime.month) &&
        (currentDate.year == dateTime.year);
  }

  static String getMonthName(int monthNumber) {
    return months[monthNumber - 1];
  }

  static int getMonthNumber(String monthName) {
    return (months.indexWhere((element) => element == monthName)) + 1;
  }

  static List<String> buildMonthYearsBetweenTwoDates(
    DateTime startDate,
    DateTime endDate,
  ) {
    List<String> dateTimes = [];
    DateTime current = startDate;
    while (current.difference(endDate).isNegative) {
      current = current.add(const Duration(days: 24));
      dateTimes.add("${getMonthName(current.month)}, ${current.year}");
    }
    return dateTimes.toSet().toList();
  }

  static String formatTime(String time) {
    final hourMinuteSecond = time.split(":");
    final hour = int.parse(hourMinuteSecond.first) < 13
        ? int.parse(hourMinuteSecond.first)
        : int.parse(hourMinuteSecond.first) - 12;
    final amOrPm = int.parse(hourMinuteSecond.first) > 12 ? "PM" : "AM";
    return "${hour.toString().padLeft(2, '0')}:${hourMinuteSecond[1]} $amOrPm";
  }

  static String extractTimeFromDateString(String dateString) {
    try {
      final parts = dateString.split(' ');
      if (parts.length >= 2) {
        String timePart = parts[1];
        if (parts.length >= 3) {
          timePart += " ${parts[2]}";
        }
        return timePart;
      }
    } catch (e) {
      // If parsing fails, return the original string
    }
    return dateString;
  }

  static String formatApiDateTime(String dateTimeString) {
    try {
      if (dateTimeString.contains('/') && dateTimeString.contains(' ')) {
        final parts = dateTimeString.split(' ');
        if (parts.length >= 2) {
          final timeParts = parts.sublist(1);
          return timeParts.join(' ');
        }
      }
      return dateTimeString;
    } catch (e) {
      debugPrint('Error formatting datetime: $dateTimeString, Error: $e');
      return dateTimeString;
    }
  }

  static String formatAssignmentDueDate(
    DateTime dateTime,
    BuildContext context,
  ) {
    final monthName = Utils.getMonthName(dateTime.month);
    final hour = dateTime.hour < 13 ? dateTime.hour : dateTime.hour - 12;
    final amOrPm = hour > 12 ? "PM" : "AM";
    return "${Utils.getTranslatedLabel(dueKey)}, ${dateTime.day} $monthName ${dateTime.year}, ${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $amOrPm";
  }

  static Future<void> showCustomSnackBar({
    required BuildContext context,
    required String errorMessage,
    required Color backgroundColor,
    Duration delayDuration = errorMessageDisplayDuration,
  }) async {
    OverlayState? overlayState = Overlay.of(context);
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => ErrorMessageOverlayContainer(
        backgroundColor: backgroundColor,
        errorMessage: errorMessage,
      ),
    );

    overlayState.insert(overlayEntry);
    await Future.delayed(delayDuration);
    overlayEntry.remove();
  }

  static String getErrorMessageFromErrorCode(
    BuildContext context,
    String errorCode,
  ) {
    final key = ErrorMessageKeysAndCode.getErrorMessageKeyFromCode(errorCode);
    // If no specific mapping was found and the input is not a numeric code,
    // it's already a human-readable message from the API — show it directly.
    if (key == ErrorMessageKeysAndCode.defaultErrorMessageKey &&
        int.tryParse(errorCode) == null) {
      return errorCode;
    }
    return Utils.getTranslatedLabel(key);
  }

  static double appContentTopScrollPadding({required BuildContext context}) {
    return kToolbarHeight + MediaQuery.of(context).padding.top;
  }

  //0 = Pending/In Review , 1 = Accepted , 2 = Rejected
  static String getAssignmentSubmissionStatusKey(int status) {
    if (status == 0) {
      return inReviewKey;
    }
    if (status == 1) {
      return acceptedKey;
    }
    if (status == 2) {
      return rejectedKey;
    }
    if (status == 3) {
      return resubmittedKey;
    }
    return "";
  }

  static String getBackButtonPath(BuildContext context) {
    return Directionality.of(context).name == TextDirection.rtl.name
        ? getImagePath("rtl_back_icon.svg")
        : getImagePath("back_icon.svg");
  }

  static Future<String?> _checkIfFileExists({
    required StudyMaterial studyMaterial,
    required bool storeInExternalStorage,
  }) async {
    try {
      // Always check external storage first (priority for permanent files)
      if (await hasStoragePermissionGiven()) {
        final externalDirectory = Platform.isAndroid
            ? await getExternalStorageDirectory()
            : await getApplicationDocumentsDirectory();
        final externalFilePath =
            "${externalDirectory?.path}/${studyMaterial.fileName}.${studyMaterial.fileExtension}";

        final externalFile = File(externalFilePath);
        if (await externalFile.exists()) {
          return externalFilePath; // Found in external storage
        }
      }

      // If not found in external storage, check temporary directory
      final tempDir = await getTemporaryDirectory();
      final tempFilePath =
          "${tempDir.path}/${studyMaterial.fileName}.${studyMaterial.fileExtension}";

      final tempFile = File(tempFilePath);
      if (await tempFile.exists()) {
        return tempFilePath; // Found in temp storage
      }

      return null; // File not found in either location
    } catch (e) {
      return null;
    }
  }

  /// Plays an audio attachment in the app. If the device can't play it, the
  /// sheet lets the user fall back to downloading and opening it elsewhere.
  static Future<void> openAudioPlayerBottomsheet({
    required BuildContext context,
    required StudyMaterial studyMaterial,
  }) async {
    final downloadInstead = await showBottomSheet(
      context: context,
      child: AudioPlayerBottomsheetContainer(studyMaterial: studyMaterial),
    );

    if (downloadInstead == true && context.mounted) {
      await openDownloadBottomsheet(
        context: context,
        storeInExternalStorage: false,
        studyMaterial: studyMaterial,
      );
    }
  }

  static Future<void> openDownloadBottomsheet({
    required BuildContext context,
    required bool storeInExternalStorage,
    required StudyMaterial studyMaterial,
  }) async {
    // First check if file already exists
    final existingFilePath = await _checkIfFileExists(
      studyMaterial: studyMaterial,
      storeInExternalStorage: storeInExternalStorage,
    );

    if (existingFilePath != null) {
      // File already exists, open it directly
      try {
        OpenFile.open(existingFilePath);
      } catch (e) {
        // If opening fails, show error message
        showCustomSnackBar(
          context: context,
          errorMessage: "Could not open file: ${e.toString()}",
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
      return;
    }

    // File doesn't exist, show download bottom sheet
    showBottomSheet(
      child: BlocProvider<DownloadFileCubit>(
        create: (context) => DownloadFileCubit(SubjectRepository()),
        child: DownloadFileBottomsheetContainer(
          storeInExternalStorage: storeInExternalStorage,
          studyMaterial: studyMaterial,
        ),
      ),
      context: context,
    ).then((result) {
      if (result != null) {
        if (result['error']) {
          debugPrint("This is the result $result");
          debugPrint("This is the result ${result['error']}");
          showCustomSnackBar(
            context: context,
            errorMessage: getErrorMessageFromErrorCode(
              context,
              result['message'].toString(),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          );
        } else {
          try {
            OpenFile.open(result['filePath'].toString());
          } catch (e, st) {
            debugPrint("this is the error $e");
            debugPrint("this is the st $st");
            showCustomSnackBar(
              context: context,
              errorMessage: getTranslatedLabel(
                storeInExternalStorage
                    ? fileDownloadedSuccessfullyKey
                    : unableToOpenKey,
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            );
          }
        }
      }
    });
  }

  static intl.DateFormat hourMinutesDateFormat = intl.DateFormat.jm();

  static String formatDateAndTime(DateTime dateTime) {
    return intl.DateFormat("dd-MM-yyyy  kk:mm").format(dateTime);
  }

  static String formatDate(DateTime dateTime) {
    return "${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}";
  }

  /// Day-month-year for an already parsed date, e.g. "10 Aug 2026".
  static String formatDayMonthYearFromDate(DateTime date) {
    return intl.DateFormat("dd MMM yyyy").format(date);
  }

  /// Day-month-year as shown on the leave screens, e.g. "10 Aug 2026".
  /// Returns an empty string for a date the backend did not send or that
  /// cannot be parsed, so callers can render a placeholder.
  ///
  /// [DateTime.tryParse] runs first so any ISO 8601 value is handled, full
  /// timestamps included. [parseApiDate] then covers the display formats the
  /// api also sends, such as "24-08-2026" and "24-08-2026 04:43 PM" — it
  /// splits on "-" and cannot read an ISO timestamp itself.
  static String formatDayMonthYear(String? date) {
    if (date == null || date.isEmpty) {
      return "";
    }

    final parsedDate = DateTime.tryParse(date) ?? parseApiDate(date);

    return parsedDate == null ? "" : formatDayMonthYearFromDate(parsedDate);
  }

  /// Weekday-qualified date used on the apply-leave date fields,
  /// e.g. "10 Aug 2026 (Mon)".
  static String formatDayMonthYearWithWeekday(DateTime dateTime) {
    return intl.DateFormat("dd MMM yyyy (EEE)").format(dateTime);
  }

  /// Leave period as shown on the leave card and details sheet,
  /// e.g. "10 Aug 2026 – 12 Aug 2026". A single-day leave collapses to one
  /// date so it does not read as a range.
  static String formatLeaveDateRange({
    required String? fromDate,
    required String? toDate,
  }) {
    final from = formatDayMonthYear(fromDate);
    final to = formatDayMonthYear(toDate);

    if (from.isEmpty && to.isEmpty) {
      return "-";
    }
    if (from.isEmpty) {
      return to;
    }
    if (to.isEmpty || from == to) {
      return from;
    }

    return "$from – $to";
  }

  static DateTime? parseApiDate(String dateString) {
    try {
      // First try ISO 8601 format (yyyy-MM-dd) which is the new API format
      if (dateString.contains('-') &&
          !dateString.contains(' ') &&
          !dateString.contains('/')) {
        List<String> parts = dateString.split('-');
        if (parts.length == 3) {
          // Check if it's yyyy-MM-dd format
          if (parts[0].length == 4) {
            int year = int.parse(parts[0]);
            int month = int.parse(parts[1]);
            int day = int.parse(parts[2]);
            return DateTime(year, month, day);
          }
        }
      }

      // Handle date formats with time (any admin format + HH:mm AM/PM)
      if (dateString.contains(' ') && dateString.contains('M')) {
        List<String> dateTimeParts = dateString.split(' ');
        if (dateTimeParts.length >= 3) {
          String datePart = dateTimeParts[0];
          String timePart = dateTimeParts[1];
          String amPmPart = dateTimeParts[2];

          // Try to detect and parse the date format automatically
          DateTime? parsedDate = _detectAndParseDate(datePart);
          if (parsedDate != null) {
            List<String> timeComponents = timePart.split(':');
            if (timeComponents.length == 2) {
              int hour = int.parse(timeComponents[0]);
              int minute = int.parse(timeComponents[1]);

              if (amPmPart.toUpperCase() == 'PM' && hour != 12) {
                hour += 12;
              } else if (amPmPart.toUpperCase() == 'AM' && hour == 12) {
                hour = 0;
              }

              return DateTime(parsedDate.year, parsedDate.month, parsedDate.day,
                  hour, minute);
            }
          }
        }
      }

      // Handle MM/dd/yyyy HH:mm AM/PM format
      if (dateString.contains('/') && dateString.contains(' ')) {
        List<String> dateTimeParts = dateString.split(' ');
        if (dateTimeParts.length >= 3) {
          String datePart = dateTimeParts[0];
          String timePart = dateTimeParts[1];
          String amPmPart = dateTimeParts[2];

          List<String> dateComponents = datePart.split('/');
          if (dateComponents.length == 3) {
            int month = int.parse(dateComponents[0]);
            int day = int.parse(dateComponents[1]);
            int year = int.parse(dateComponents[2]);

            List<String> timeComponents = timePart.split(':');
            if (timeComponents.length == 2) {
              int hour = int.parse(timeComponents[0]);
              int minute = int.parse(timeComponents[1]);

              if (amPmPart.toUpperCase() == 'PM' && hour != 12) {
                hour += 12;
              } else if (amPmPart.toUpperCase() == 'AM' && hour == 12) {
                hour = 0;
              }

              return DateTime(year, month, day, hour, minute);
            }
          }
        }
      }

      // Handle MM/dd/yyyy format without time
      if (dateString.contains('/') && !dateString.contains(' ')) {
        List<String> parts = dateString.split('/');
        if (parts.length == 3) {
          int month = int.parse(parts[0]);
          int day = int.parse(parts[1]);
          int year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      }

      // Handle date-only formats (any admin format without time)
      if (!dateString.contains(' ')) {
        return _detectAndParseDate(dateString);
      }

      return DateTime.parse(dateString);
    } catch (e) {
      debugPrint('Error parsing date: $dateString, Error: $e');
      return null;
    }
  }

  static String formatApiDate(String dateString) {
    return dateString.isEmpty ? '--' : dateString;
  }

  /// Locale that `intl` actually holds date symbols for.
  ///
  /// Panel-managed languages may use codes that are not real ICU locales — the
  /// panel accepts anything (e.g. "test", "002"). [intl.DateFormat] throws an
  /// `ArgumentError` on those instead of degrading, so unknown codes fall back
  /// to the bundled language.
  static String intlLocaleFor(String languageCode) {
    for (final candidate in [
      languageCode.replaceAll("-", "_"),
      bundledFallbackLanguageCode,
    ]) {
      if (intl.DateFormat.localeExists(candidate)) {
        return candidate;
      }
    }
    return "en_US";
  }

  static String dateConverter(
    DateTime myEndDate,
    BuildContext contxt,
    bool fromResult,
  ) {
    String date;

    final formattedDate = intl.DateFormat(
      'dd MMM, yyyy',
      intlLocaleFor(
          contxt.read<AppLocalizationCubit>().state.language.languageCode),
    ).add_jm().format(myEndDate);

    final formattedTime = intl.DateFormat('hh:mm a').format(myEndDate);
    //check for today or tomorrow or specific date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final checkEndDate =
        DateTime(myEndDate.year, myEndDate.month, myEndDate.day);

    if (checkEndDate == today) {
      date = fromResult
          ? "${Utils.getTranslatedLabel(submittedKey)} : ${Utils.getTranslatedLabel(todayKey)}" //
          : "${Utils.getTranslatedLabel(todayKey)}, $formattedTime";
    } else if (checkEndDate == tomorrow) {
      date = fromResult
          ? "${Utils.getTranslatedLabel(submittedKey)} : ${Utils.getTranslatedLabel(tomorrowKey)}"
          : "${Utils.getTranslatedLabel(tomorrowKey)}, $formattedTime";
    } else {
      date = fromResult
          ? '${Utils.getTranslatedLabel(submittedKey)} : ${formattedDate}'
          : '$formattedDate';
    }
    return date;
  }

  //It will return - if given value is empty
  static String formatEmptyValue(String value) {
    return value.isEmpty ? "-" : value;
  }

  //It will prefix the country code to the mobile number - +91 9876543210
  //Returns empty string if mobile number is empty and
  //returns the mobile number as it is if country code is not available
  static String formatMobileNumber({String? countryCode, String? mobile}) {
    final String number = (mobile ?? "").trim();
    if (number.isEmpty) {
      return "";
    }

    //Country code can come as 91, +91 or 0091 from the backend
    final String code =
        (countryCode ?? "").replaceAll(RegExp(r'[^0-9]'), '').trim();

    //Mobile number already contains the country code
    if (code.isEmpty || number.startsWith("+")) {
      return number;
    }

    return "+$code $number";
  }

  static Future<bool> forceUpdate(String updatedVersion) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String currentVersion = "${packageInfo.version}+${packageInfo.buildNumber}";
    if (updatedVersion.isEmpty) {
      return false;
    }

    final bool updateBasedOnVersion = _shouldUpdateBasedOnVersion(
      currentVersion.split("+").first,
      updatedVersion.split("+").first,
    );

    if (updatedVersion.split("+").length == 1 ||
        currentVersion.split("+").length == 1) {
      return updateBasedOnVersion;
    }

    final bool updateBasedOnBuildNumber = _shouldUpdateBasedOnBuildNumber(
      currentVersion.split("+").last,
      updatedVersion.split("+").last,
    );

    return updateBasedOnVersion || updateBasedOnBuildNumber;
  }

  static bool _shouldUpdateBasedOnVersion(
    String currentVersion,
    String updatedVersion,
  ) {
    List<int> currentVersionList =
        currentVersion.split(".").map((e) => int.parse(e)).toList();
    List<int> updatedVersionList =
        updatedVersion.split(".").map((e) => int.parse(e)).toList();

    if (updatedVersionList[0] > currentVersionList[0]) {
      return true;
    }
    if (updatedVersionList[1] > currentVersionList[1]) {
      return true;
    }
    if (updatedVersionList[2] > currentVersionList[2]) {
      return true;
    }

    return false;
  }

  static bool _shouldUpdateBasedOnBuildNumber(
    String currentBuildNumber,
    String updatedBuildNumber,
  ) {
    return int.parse(updatedBuildNumber) > int.parse(currentBuildNumber);
  }

  static String getLottieAnimationPath(String animationName) {
    return "assets/animations/$animationName";
  }

  static void showFeatureDisableInDemoVersion(BuildContext context) {
    showCustomSnackBar(
      context: context,
      errorMessage: Utils.getTranslatedLabel(featureDisableInDemoVersionKey),
      backgroundColor: Theme.of(context).colorScheme.error,
    );
  }

  //0 = Pending , 1 = Paid, 2 = Partially Paid ˆset according to API response.
  static String getStudentFeesStatusKey(int status) {
    if (status == 0) {
      return pendingKey;
    }
    if (status == 1) {
      return paidKey;
    }
    if (status == 2) {
      return partiallyPaidKey;
    }
    return "";
  }

  static bool isModuleEnabled(
      {required BuildContext context, required String moduleId}) {
    final enabledFeatures = context
        .read<SchoolConfigurationCubit>()
        .getSchoolConfiguration()
        .enabledModules;

    //Module id will have "1" or "1#2".
    final ids = moduleId.split("$moduleIdJoiner").toList();
    if (ids.contains(defaultModuleId.toString())) {
      return true;
    }

    bool featureEnabled = false;
    for (var i = 0; i < ids.length; i++) {
      if (enabledFeatures.containsKey(ids[i].toString())) {
        featureEnabled = true;
        break;
      }
    }

    //
    return featureEnabled;
  }

  static Future<bool> hasStoragePermissionGiven() async {
    if (Platform.isIOS) {
      bool permissionGiven = await Permission.storage.isGranted;
      if (!permissionGiven) {
        permissionGiven = (await Permission.storage.request()).isGranted;
        return permissionGiven;
      }
      return permissionGiven;
    }

    //if it is for android
    final deviceInfoPlugin = DeviceInfoPlugin();
    final androidDeviceInfo = await deviceInfoPlugin.androidInfo;
    if (androidDeviceInfo.version.sdkInt < 33) {
      bool permissionGiven = await Permission.storage.isGranted;
      if (!permissionGiven) {
        permissionGiven = (await Permission.storage.request()).isGranted;
        return permissionGiven;
      }
      return permissionGiven;
    } else {
      bool permissionGiven = await Permission.photos.isGranted;
      if (!permissionGiven) {
        permissionGiven = (await Permission.photos.request()).isGranted;
        return permissionGiven;
      }
      return permissionGiven;
    }
  }

  static Future<bool> hasCameraPermissionGiven() async {
    bool permissionGiven = await Permission.camera.isGranted;
    if (!permissionGiven) {
      permissionGiven = (await Permission.camera.request()).isGranted;
      return permissionGiven;
    }
    return permissionGiven;
  }

  static Future<bool> hasGalleryPermissionGiven() async {
    bool permissionGiven = await Permission.photos.isGranted;
    if (!permissionGiven) {
      permissionGiven = (await Permission.photos.request()).isGranted;
      return permissionGiven;
    }
    return permissionGiven;
  }

  static DateTime? parseAssignmentDueDate(
      String dateString, String dateFormat) {
    try {
      if (dateString.contains(' ')) {
        List<String> parts = dateString.split(' ');
        if (parts.length >= 3) {
          String datePart = parts[0];
          String timePart = parts[1];
          String amPmPart = parts[2];

          DateTime? dateOnly = _parseDateByFormat(datePart, dateFormat);
          if (dateOnly == null) return null;

          List<String> timeComponents = timePart.split(':');
          if (timeComponents.length == 2) {
            int hour = int.parse(timeComponents[0]);
            int minute = int.parse(timeComponents[1]);

            if (amPmPart.toUpperCase() == 'PM' && hour != 12) {
              hour += 12;
            } else if (amPmPart.toUpperCase() == 'AM' && hour == 12) {
              hour = 0;
            }

            return DateTime(
                dateOnly.year, dateOnly.month, dateOnly.day, hour, minute);
          }
        }
      }
      return _parseDateByFormat(dateString, dateFormat);
    } catch (e) {
      debugPrint(
          'Error parsing assignment due date: $dateString with format: $dateFormat, Error: $e');
      return null;
    }
  }

  static DateTime? _parseDateByFormat(String dateString, String format) {
    try {
      switch (format) {
        case 'Y-m-d':
          List<String> parts = dateString.split('-');
          if (parts.length == 3) {
            int year = int.parse(parts[0]);
            int month = int.parse(parts[1]);
            int day = int.parse(parts[2]);
            return DateTime(year, month, day);
          }
          break;
        case 'd/m/Y':
          List<String> parts = dateString.split('/');
          if (parts.length == 3) {
            int day = int.parse(parts[0]);
            int month = int.parse(parts[1]);
            int year = int.parse(parts[2]);
            return DateTime(year, month, day);
          }
          break;
        case 'm/d/Y':
          List<String> parts = dateString.split('/');
          if (parts.length == 3) {
            int month = int.parse(parts[0]);
            int day = int.parse(parts[1]);
            int year = int.parse(parts[2]);
            return DateTime(year, month, day);
          }
          break;
        case 'Y/m/d':
          List<String> parts = dateString.split('/');
          if (parts.length == 3) {
            int year = int.parse(parts[0]);
            int month = int.parse(parts[1]);
            int day = int.parse(parts[2]);
            return DateTime(year, month, day);
          }
          break;
        case 'Y/d/m':
          List<String> parts = dateString.split('/');
          if (parts.length == 3) {
            int year = int.parse(parts[0]);
            int day = int.parse(parts[1]);
            int month = int.parse(parts[2]);
            return DateTime(year, month, day);
          }
          break;
        case 'm-d-Y':
          List<String> parts = dateString.split('-');
          if (parts.length == 3) {
            int month = int.parse(parts[0]);
            int day = int.parse(parts[1]);
            int year = int.parse(parts[2]);
            return DateTime(year, month, day);
          }
          break;
        case 'd-m-Y':
          List<String> parts = dateString.split('-');
          if (parts.length == 3) {
            int day = int.parse(parts[0]);
            int month = int.parse(parts[1]);
            int year = int.parse(parts[2]);
            return DateTime(year, month, day);
          }
          break;
        case 'Y-d-m':
          List<String> parts = dateString.split('-');
          if (parts.length == 3) {
            int year = int.parse(parts[0]);
            int day = int.parse(parts[1]);
            int month = int.parse(parts[2]);
            return DateTime(year, month, day);
          }
          break;
        default:
          return DateTime.parse(dateString);
      }
    } catch (e) {
      debugPrint(
          'Error parsing date with format $format: $dateString, Error: $e');
    }
    return null;
  }

  /// Enhanced date parsing that handles configurable formats from admin panel
  static DateTime? parseApiDateWithFormat(String dateString,
      {String? dateFormat}) {
    if (dateString.isEmpty) return null;

    try {
      // If we have a specific date format from the API, use it
      if (dateFormat != null && dateFormat.isNotEmpty) {
        return _parseWithSpecificFormat(dateString, dateFormat);
      }

      // Fallback to general parsing for backward compatibility
      return parseApiDate(dateString);
    } catch (e) {
      debugPrint(
          'Error parsing date: $dateString with format: $dateFormat, Error: $e');
      return null;
    }
  }

  /// Automatically detect and parse date format from common admin formats
  static DateTime? _detectAndParseDate(String dateString) {
    if (dateString.isEmpty) return null;

    // List of all supported admin date formats
    final supportedFormats = [
      'Y-m-d', // 2025-07-28
      'm-d-Y', // 07-28-2025
      'd-m-Y', // 28-07-2025
      'Y-d-m', // 2025-28-07
      'Y/m/d', // 2025/07/28
      'm/d/Y', // 07/28/2025
      'd/m/Y', // 28/07/2025
      'Y/d/m', // 2025/28/07
    ];

    // Try each format until one works
    for (String format in supportedFormats) {
      try {
        DateTime? result = _parseDateByFormat(dateString, format);
        if (result != null) {
          return result;
        }
      } catch (e) {
        // Continue to next format
        continue;
      }
    }

    return null;
  }

  /// Parse date with specific format provided by admin panel
  static DateTime? _parseWithSpecificFormat(String dateString, String format) {
    try {
      if (!dateString.contains(' ')) {
        // Date only format
        return _parseDateByFormat(dateString, format);
      }

      // Date with time format
      List<String> parts = dateString.split(' ');
      if (parts.length >= 3) {
        String datePart = parts[0];
        String timePart = parts[1];
        String amPmPart = parts[2];

        DateTime? dateOnly = _parseDateByFormat(datePart, format);
        if (dateOnly == null) return null;

        // Parse time part
        List<String> timeComponents = timePart.split(':');
        if (timeComponents.length == 2) {
          int hour = int.parse(timeComponents[0]);
          int minute = int.parse(timeComponents[1]);

          // Handle AM/PM
          if (amPmPart.toUpperCase() == 'PM' && hour != 12) {
            hour += 12;
          } else if (amPmPart.toUpperCase() == 'AM' && hour == 12) {
            hour = 0;
          }

          return DateTime(
              dateOnly.year, dateOnly.month, dateOnly.day, hour, minute);
        }
      }

      return null;
    } catch (e) {
      debugPrint(
          'Error parsing formatted date: $dateString with format: $format, Error: $e');
      return null;
    }
  }

  /// Launch phone dialer with the given phone number
  static Future<void> launchPhoneDialer(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;

    // Clean the phone number (remove spaces, dashes, etc.)
    final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: cleanedNumber);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Could not launch phone dialer';
      }
    } catch (e) {
      debugPrint('Error launching phone dialer: $e');
    }
  }
}

class _ImagePreviewDialog extends StatelessWidget {
  final String imageUrl;
  final String? heroTag;

  const _ImagePreviewDialog({
    required this.imageUrl,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    const errorContent = Icon(
      Icons.broken_image_outlined,
      color: Colors.white70,
      size: 48,
    );

    //the source may be an inline base64 image rather than a url, so it goes
    //through the shared resolver instead of straight to the network loader
    final imageProvider = Utils.imageProviderFromSource(imageUrl);

    Widget content = InteractiveViewer(
      minScale: 0.8,
      maxScale: 4.0,
      child: imageProvider == null
          ? errorContent
          : Image(
              image: imageProvider,
              fit: BoxFit.contain,
              //zooming a QR past its natural size should stay legible
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) => errorContent,
            ),
    );

    if ((heroTag ?? '').isNotEmpty) {
      content = Hero(tag: heroTag!, child: content);
    }

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.92),
      body: SafeArea(
        child: Stack(
          children: [
            Center(child: content),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.35),
                ),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                ),
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension DateTimeExtension on DateTime {
  bool isSameDayAs(DateTime other) =>
      this.day == other.day &&
      this.month == other.month &&
      this.year == other.year;

  String get relativeFormatedDate {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    if (this.isSameDayAs(today)) {
      return "today";
    } else if (this.isSameDayAs(yesterday)) {
      return "yesterday";
    } else {
      return intl.DateFormat('d MMMM yyyy').format(this);
    }
  }
}

extension EmptyPadding on num {
  SizedBox get sizedBoxHeight => SizedBox(height: toDouble());
  SizedBox get sizedBoxWidth => SizedBox(width: toDouble());
}
