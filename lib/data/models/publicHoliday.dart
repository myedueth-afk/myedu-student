import 'package:eschool/utils/utils.dart';

/// One school holiday from the shared `leave-settings` endpoint. The backend
/// sends the date under `dmyFormat`, which is a display format rather than
/// ISO 8601, so it goes through [Utils.parseApiDate].
class PublicHoliday {
  final DateTime? date;
  final String? title;

  PublicHoliday({this.date, this.title});

  PublicHoliday.fromJson(Map<String, dynamic> json)
      : date = json['dmyFormat'] != null
            ? Utils.parseApiDate(json['dmyFormat'].toString())
            : null,
        title = json['title'] as String?;
}
