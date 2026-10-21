import 'package:eschool/data/models/subject.dart';

class TimeTableSlot {
  TimeTableSlot({
    required this.startTime,
    required this.endTime,
    required this.day,
    required this.subject,
    required this.teacherFirstName,
    required this.teacherLastName,
  });
  late final String startTime;
  late final String endTime;
  late final String day;
  late final Subject subject;
  late final String teacherFirstName;
  late final String teacherLastName;
  late final String note;
  late final String? startDate;
  late final String? endDate;
  late final String repeat;
  late final String meetingLink;

  TimeTableSlot.fromJson(Map<String, dynamic> json) {
    startTime = json['start_time'] ?? "";
    teacherLastName = json['teacher_last_name'] ?? "";
    endTime = json['end_time'] ?? "";
    day = json['day'] ?? "";
    note = json['note'] ?? "";
    subject = Subject.fromJson(Map.from(json['subject'] ?? {}));
    teacherFirstName = json['teacher_first_name'] ?? "";
    startDate = json['start_date'];
    endDate = json['end_date'];
    repeat = json['repeat'] ?? "";
    meetingLink = json['meeting_link'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['start_time'] = startTime;
    _data['end_time'] = endTime;
    _data['day'] = day;
    _data['note'] = note;
    _data['subject'] = subject.toJson();
    _data['teacher_first_name'] = teacherFirstName;
    _data['teacher_last_name'] = teacherLastName;
    _data['start_date'] = startDate;
    _data['end_date'] = endDate;
    _data['repeat'] = repeat;
    _data['meeting_link'] = meetingLink;
    return _data;
  }

  ///Whether the "Online Class" label should be shown for the given [date].
  ///
  ///- When only [startDate] is set (and [endDate] is null), the label is shown
  ///  only on the [startDate].
  ///- When both [startDate] and [endDate] are set, the label is shown for every
  ///  date from [startDate] to [endDate] (inclusive). After [endDate] it is
  ///  no longer shown.
  bool showOnlineClassLabelOnDate(DateTime date) {
    if (startDate == null || startDate!.isEmpty) return false;

    final parsedStart = DateTime.tryParse(startDate!);
    if (parsedStart == null) return false;

    final start =
        DateTime(parsedStart.year, parsedStart.month, parsedStart.day);
    final target = DateTime(date.year, date.month, date.day);

    final parsedEnd = (endDate == null || endDate!.isEmpty)
        ? null
        : DateTime.tryParse(endDate!);

    ///[Only start date available] -> show only on the start date
    if (parsedEnd == null) {
      return target.isAtSameMomentAs(start);
    }

    ///[Both dates available] -> show for the inclusive start..end range
    final end = DateTime(parsedEnd.year, parsedEnd.month, parsedEnd.day);
    return !target.isBefore(start) && !target.isAfter(end);
  }

  ///How many minutes before the start time the "Join Class" link appears.
  static const int joinClassVisibleBeforeInMinutes = 30;

  ///Builds a [DateTime] for [time] ("HH:mm:ss") on the same day as [date].
  DateTime? _dateTimeOnDate(DateTime date, String time) {
    if (time.isEmpty) return null;
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    final second = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;
    if (hour == null || minute == null) return null;
    return DateTime(date.year, date.month, date.day, hour, minute, second);
  }

  ///Whether [now] is inside the lecture's [startTime]–[endTime] window
  ///(i.e. the class is currently in progress / "Live").
  bool isLiveAt(DateTime now) {
    final start = _dateTimeOnDate(now, startTime);
    final end = _dateTimeOnDate(now, endTime);
    if (start == null || end == null) return false;
    return !now.isBefore(start) && now.isBefore(end);
  }

  ///Whether the lecture is still upcoming at [now] (i.e. it hasn't started yet).
  bool isUpcomingAt(DateTime now) {
    final start = _dateTimeOnDate(now, startTime);
    if (start == null) return false;
    return now.isBefore(start);
  }

  ///Whether the lecture has already finished at [now] (i.e. [now] is at or
  ///after the end time).
  bool isCompletedAt(DateTime now) {
    final end = _dateTimeOnDate(now, endTime);
    if (end == null) return false;
    return !now.isBefore(end);
  }

  ///Whether the "Join Class" link should be shown for [now]: from
  ///[joinClassVisibleBeforeInMinutes] minutes before the start time until the
  ///lecture ends.
  bool isJoinableAt(DateTime now) {
    final start = _dateTimeOnDate(now, startTime);
    final end = _dateTimeOnDate(now, endTime);
    if (start == null || end == null) return false;
    final joinableFrom = start.subtract(
      const Duration(minutes: joinClassVisibleBeforeInMinutes),
    );
    return !now.isBefore(joinableFrom) && now.isBefore(end);
  }

  ///Live / upcoming / completed / joinable status at [now], computed with a
  ///single parse of [startTime] / [endTime]. Equivalent to calling
  ///[isLiveAt], [isUpcomingAt], [isCompletedAt] and [isJoinableAt] but without
  ///re-parsing the time strings for each — preferred when several are needed.
  ({bool isLive, bool isUpcoming, bool isCompleted, bool isJoinable})
      onlineClassStatusAt(DateTime now) {
    final start = _dateTimeOnDate(now, startTime);
    final end = _dateTimeOnDate(now, endTime);
    final joinableFrom = start?.subtract(
      const Duration(minutes: joinClassVisibleBeforeInMinutes),
    );
    return (
      isLive: start != null &&
          end != null &&
          !now.isBefore(start) &&
          now.isBefore(end),
      isUpcoming: start != null && now.isBefore(start),
      isCompleted: end != null && !now.isBefore(end),
      isJoinable: start != null &&
          end != null &&
          !now.isBefore(joinableFrom!) &&
          now.isBefore(end),
    );
  }
}
