// ignore_for_file: prefer_const_declarations

import 'package:flutter/material.dart';

//Brand palette, overridable per school by the School Builder addon.
const Color primaryColor = Color(
    int.fromEnvironment('SCHOOL_COLOR_PRIMARY', defaultValue: 0xff22577A));

const Color secondaryColor = Color(
    int.fromEnvironment('SCHOOL_COLOR_SECONDARY', defaultValue: 0xff212121));
const Color pageBackgroundColor = Color(int.fromEnvironment(
    'SCHOOL_COLOR_PAGE_BACKGROUND',
    defaultValue: 0xffFFFFFF));
const Color backgroundColor = Color(
    int.fromEnvironment('SCHOOL_COLOR_BACKGROUND', defaultValue: 0xfff6f6f6));
const Color tertiaryColor = Color(
    int.fromEnvironment('SCHOOL_COLOR_TERTIARY', defaultValue: 0xffEBEEF3));

//
const Color errorColor =
    Color(int.fromEnvironment('SCHOOL_COLOR_ERROR', defaultValue: 0xffff6769));
const Color onBackgroundColor = Color(int.fromEnvironment(
    'SCHOOL_COLOR_ON_BACKGROUND',
    defaultValue: 0xff484848));
const Color onPrimaryColor = Color(
    int.fromEnvironment('SCHOOL_COLOR_ON_PRIMARY', defaultValue: 0xff3bcc97));
const Color onSecondaryColor = Color(
    int.fromEnvironment('SCHOOL_COLOR_ON_SECONDARY', defaultValue: 0xff57cc99));

//Matches the native launch window, so the hand-off to Flutter doesn't flash.
const Color splashBackgroundColor = Color(int.fromEnvironment(
    'SCHOOL_COLOR_SPLASH_BACKGROUND',
    defaultValue: 0xffFFFFFF));

//shimmer loading colors
final Color shimmerBaseColor = Colors.grey.shade300;
final Color shimmerhighlightColor = Colors.grey.shade100;
final Color shimmerContentColor = Colors.white.withValues(alpha: 0.85);

const Color tripTimelineGreenColor = Color(0xff57CC99);

//background of the online classes card on the home / student-details screens
const Color onlineClassCardColor = Color(0xffF5F5F5);

//"Live" status indicator on the online classes card
const Color liveStatusColor = Color(0xffBB1B1B);

//"Completed" status indicator on the online classes card (muted caption grey)
const Color completedStatusColor = Color(0xff9F9F9F);

//muted caption grey used for field labels on the leave cards and details sheet
const Color captionColor = Color(0xff9F9F9F);

//hairline stroke under bottomsheet titles and around dashed upload targets
const Color secondaryStrokeColor = Color(0xffCACACA);

//background of the "under review" callout on the manual payment screen
const Color warningContainerColor = Color(0xffFEEED7);

//student leave status colors
const Color leavePendingColor = Color(0xffF89E1B);
const Color leaveApprovedColor = Color(0xff37C748);
const Color leaveRejectedColor = Color(0xffBB1B1B);

//background of the rejection reason callout on the leave details sheet
const Color leaveRejectedReasonBackgroundColor = Color(0xffFADBDB);

//colors used for status (change to globally apply personalized color)
final Color greenColor = Colors.green;
final Color redColor = Colors.red;
final Color orangeColor = Colors.orange;
final Color blueColor = Colors.blue;

//fee transaction status chips on the transaction history screen
const Color transactionPaidColor = Color(0xff37C748);
const Color transactionRejectedColor = Color(0xffBB1B1B);

//background of an error callout — the rejected payment banner and the reason
//shown against a rejected transaction
const Color errorContainerColor = Color(0xffFADBDB);
