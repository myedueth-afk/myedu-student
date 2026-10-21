/// Model for a single semester returned by the `/semester` endpoint.
///
/// Sample response item:
/// ```json
/// {
///   "id": 1,
///   "name": "First Semester",
///   "start_date": "01-01-2026",
///   "end_date": "31-05-2026",
///   "school_id": 629,
///   "session_year_id": 1,
///   "current": true
/// }
/// ```
class Semester {
  final int? id;
  final String? name;
  final String? startDate;
  final String? endDate;
  final int? schoolId;
  final int? sessionYearId;
  final String? createdAt;
  final String? updatedAt;
  final dynamic deletedAt;
  final bool? current;

  Semester({
    this.id,
    this.name,
    this.startDate,
    this.endDate,
    this.schoolId,
    this.sessionYearId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.current,
  });

  Semester copyWith({
    int? id,
    String? name,
    String? startDate,
    String? endDate,
    int? schoolId,
    int? sessionYearId,
    String? createdAt,
    String? updatedAt,
    dynamic deletedAt,
    bool? current,
  }) {
    return Semester(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      schoolId: schoolId ?? this.schoolId,
      sessionYearId: sessionYearId ?? this.sessionYearId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      current: current ?? this.current,
    );
  }

  Semester.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        name = json['name'] as String?,
        startDate = json['start_date'] as String?,
        endDate = json['end_date'] as String?,
        schoolId = json['school_id'] as int?,
        sessionYearId = json['session_year_id'] as int?,
        createdAt = json['created_at'] as String?,
        updatedAt = json['updated_at'] as String?,
        deletedAt = json['deleted_at'],
        current = json['current'] as bool?;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'start_date': startDate,
        'end_date': endDate,
        'school_id': schoolId,
        'session_year_id': sessionYearId,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
        'current': current,
      };
}
