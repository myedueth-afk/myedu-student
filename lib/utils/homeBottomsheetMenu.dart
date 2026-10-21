import 'package:eschool/utils/appIcons.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/systemModules.dart';

class Menu {
  final String title;
  final String iconUrl;
  final String menuModuleId; //This is fixed

  Menu(
      {required this.iconUrl, required this.title, required this.menuModuleId});
}

//To add all more menu here

final List<Menu> homeBottomSheetMenu = [
  Menu(
      menuModuleId: attendanceManagementModuleId.toString(),
      iconUrl: AppIcons.attendance,
      title: attendanceKey),
  Menu(
    menuModuleId: timetableManagementModuleId.toString(),
    iconUrl: AppIcons.timetable,
    title: timeTableKey,
  ),
  Menu(
    menuModuleId: announcementManagementModuleId.toString(),
    iconUrl: AppIcons.noticeBoard,
    title: noticeBoardKey,
  ),
  Menu(
    menuModuleId: examManagementModuleId.toString(),
    iconUrl: AppIcons.exam,
    title: examsKey,
  ),
  Menu(
      menuModuleId: examManagementModuleId.toString(),
      iconUrl: AppIcons.result,
      title: resultKey),

  //Report module is combination of assginement and exam
  Menu(
      menuModuleId:
          "$assignmentManagementModuleId$moduleIdJoiner$examManagementModuleId",
      iconUrl: AppIcons.reports,
      title: reportsKey),
  Menu(
    menuModuleId: defaultModuleId.toString(),
    iconUrl: AppIcons.guardian,
    title: guardianDetailsKey,
  ),
  Menu(
      iconUrl: AppIcons.holiday,
      title: holidaysKey,
      menuModuleId: holidayManagementModuleId.toString()),
  Menu(
      iconUrl: AppIcons.gallery,
      title: galleryKey,
      menuModuleId: galleryManagementModuleId.toString()),
  Menu(
      iconUrl: AppIcons.diary,
      title: myDiaryKey,
      menuModuleId: studentManagementModuleId.toString()),
  Menu(
      iconUrl: AppIcons.transportation,
      title: transportationKey,
      menuModuleId: transportationManagementModuleId.toString()),
  Menu(
      iconUrl: AppIcons.certificate,
      title: certificateKey,
      menuModuleId: certificateManagementModuleId.toString()),
  Menu(
      iconUrl: AppIcons.teachers,
      title: teachersKey,
      menuModuleId: defaultModuleId.toString()),
  Menu(
      iconUrl: AppIcons.settings,
      title: settingsKey,
      menuModuleId: defaultModuleId.toString()),
];
