/// School-wide leave configuration returned by the shared `leave-settings`
/// endpoint. [holiday] is a comma separated list of weekday names that are
/// weekly offs, e.g. "Sunday" or "Saturday,Sunday".
class LeaveSettings {
  final int? id;
  final double? leaves;
  final String? holiday;
  final int? sessionYearId;
  final int? schoolId;

  LeaveSettings({
    this.id,
    this.leaves,
    this.holiday,
    this.sessionYearId,
    this.schoolId,
  });

  LeaveSettings.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        leaves = double.tryParse((json['leaves'] ?? 0).toString()),
        holiday = json['holiday'] as String?,
        sessionYearId = json['session_year_id'] as int?,
        schoolId = json['school_id'] as int?;

  Map<String, dynamic> toJson() => {
        'id': id,
        'leaves': leaves,
        'holiday': holiday,
        'session_year_id': sessionYearId,
        'school_id': schoolId,
      };
}
