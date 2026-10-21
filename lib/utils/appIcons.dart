/// Asset paths of the app's icon set, so a screen never spells a file name.
///
/// Every icon here is drawn in a single colour and is painted at runtime by
/// `AppIcon`, which defaults to the theme's primary colour. The bottom
/// navigation icons are two-tone and go through `BottomNavIcon` instead.
class AppIcons {
  const AppIcons._();

  static const String _dir = "assets/icons";

  //Menu (student more-menu and the parent's child menu)
  static const String assignment = "$_dir/menu_assignment.svg";
  static const String attendance = "$_dir/menu_attendance.svg";
  static const String certificate = "$_dir/menu_certificate.svg";
  static const String diary = "$_dir/menu_diary.svg";
  static const String exam = "$_dir/menu_exam.svg";
  static const String fees = "$_dir/menu_fees.svg";
  static const String gallery = "$_dir/menu_gallery.svg";
  static const String guardian = "$_dir/menu_guardian.svg";
  static const String holiday = "$_dir/menu_holiday.svg";
  static const String leave = "$_dir/menu_leave.svg";
  static const String noticeBoard = "$_dir/menu_notice_board.svg";
  static const String reports = "$_dir/menu_reports.svg";
  static const String result = "$_dir/menu_result.svg";
  static const String settings = "$_dir/menu_settings.svg";
  static const String teachers = "$_dir/menu_teachers.svg";
  static const String timetable = "$_dir/menu_timetable.svg";
  static const String transportation = "$_dir/menu_transportation.svg";

  //Bottom navigation
  static const String navHome = "$_dir/nav_home.svg";
  static const String navHomeActive = "$_dir/nav_home_active.svg";
  static const String navAssignment = "$_dir/nav_assignment.svg";
  static const String navAssignmentActive = "$_dir/nav_assignment_active.svg";
  static const String navMenu = "$_dir/nav_menu.svg";
  static const String navMenuActive = "$_dir/nav_menu_active.svg";
}

/// Asset paths of the full-size empty and error state illustrations, rendered
/// by `AppIllustration` so their brand-coloured parts follow the theme.
class AppIllustrations {
  const AppIllustrations._();

  static const String _dir = "assets/illustrations";

  static const String maintenance = "$_dir/maintenance.svg";
  static const String noData = "$_dir/no_data.svg";
  static const String noInternet = "$_dir/no_internet.svg";
  static const String somethingWentWrong = "$_dir/something_went_wrong.svg";
}
