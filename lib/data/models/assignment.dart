import 'package:eschool/data/models/studyMaterial.dart';
import 'package:eschool/data/models/subject.dart';

class Assignment {
  Assignment({
    required this.id,
    required this.classSectionId,
    required this.subjectId,
    required this.name,
    required this.instructions,
    required this.dueDate,
    required this.dueDateOriginal,
    required this.points,
    required this.resubmission,
    required this.extraDaysForResubmission,
    required this.sessionYearId,
    required this.subject,
    required this.createdAt,
    required this.createdAtOriginal,
    required this.assignmentSubmission,
    required this.referenceMaterials,
    required this.schoolId,
  });

  late final int id;
  late final int classSectionId;
  late final int subjectId;
  late final String name;
  late final String createdAt; //It will work as assigned date
  late final String
      createdAtOriginal; //Original date for parsing (from created_at_original)
  late final List<StudyMaterial> referenceMaterials;
  late final String instructions;
  late final String dueDate; // Formatted date for display (from due_date)
  late final String
      dueDateOriginal; // Original date for parsing (from due_date_original)
  late final int points;
  late final int resubmission;
  late final int extraDaysForResubmission;
  late final int sessionYearId;
  late final int schoolId;
  late final AssignmentSubmission assignmentSubmission;
  late final Subject subject;

  Assignment updateAssignmentSubmission(
    AssignmentSubmission newAssignmentSubmission,
  ) {
    return Assignment(
      schoolId: schoolId,
      createdAt: createdAt,
      createdAtOriginal: createdAtOriginal,
      id: id,
      classSectionId: classSectionId,
      subjectId: subjectId,
      name: name,
      instructions: instructions,
      dueDate: dueDate,
      dueDateOriginal: dueDateOriginal,
      points: points,
      resubmission: resubmission,
      extraDaysForResubmission: extraDaysForResubmission,
      sessionYearId: sessionYearId,
      subject: subject,
      assignmentSubmission: newAssignmentSubmission,
      referenceMaterials: referenceMaterials,
    );
  }

  /// Parse the due date from dueDateOriginal for date comparisons
  DateTime? getParsedDueDate() {
    if (dueDateOriginal.isEmpty) return null;

    try {
      // Try parsing as ISO format first: "2025-09-20 10:44:00" or similar
      if (dueDateOriginal.contains('-') && dueDateOriginal.contains(':')) {
        try {
          DateTime parsed = DateTime.parse(dueDateOriginal);
          return parsed;
        } catch (e) {
          // If ISO parsing fails, try custom format
        }
      }

      // Parse the date from dueDateOriginal format: "20-09-2025 10:44 AM"
      if (dueDateOriginal.contains(' ') &&
          dueDateOriginal.toUpperCase().contains('M')) {
        List<String> dateTimeParts = dueDateOriginal.split(' ');

        if (dateTimeParts.length >= 3) {
          String datePart = dateTimeParts[0];
          String timePart = dateTimeParts[1];
          String amPmPart = dateTimeParts[2];

          // Parse date part (dd-mm-yyyy format)
          List<String> dateComponents = datePart.split('-');
          if (dateComponents.length == 3) {
            int day = int.parse(dateComponents[0]);
            int month = int.parse(dateComponents[1]);
            int year = int.parse(dateComponents[2]);

            // Parse time part
            List<String> timeComponents = timePart.split(':');
            if (timeComponents.length == 2) {
              int hour = int.parse(timeComponents[0]);
              int minute = int.parse(timeComponents[1]);

              if (amPmPart.toUpperCase() == 'PM' && hour != 12) {
                hour += 12;
              } else if (amPmPart.toUpperCase() == 'AM' && hour == 12) {
                hour = 0;
              }

              DateTime parsed = DateTime(year, month, day, hour, minute);
              return parsed;
            }
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Calculate the effective deadline for assignment submission.
  /// When [includeResubmissionDays] is true and resubmission is allowed with
  /// extra days, the deadline is extended to end-of-day (23:59:59) of the
  /// final extra day to ensure the user gets the full extra calendar day(s).
  DateTime? getEffectiveDeadline({bool includeResubmissionDays = false}) {
    DateTime? dueDate = getParsedDueDate();
    if (dueDate == null) return null;

    if (includeResubmissionDays &&
        resubmission == 1 &&
        extraDaysForResubmission > 0) {
      // Add extra days to the due date
      DateTime extended = dueDate.add(
        Duration(days: extraDaysForResubmission),
      );
      // Extend to end of that day (23:59:59) so the user gets the full day
      return DateTime(
        extended.year,
        extended.month,
        extended.day,
        23,
        59,
        59,
      );
    }

    return dueDate;
  }

  /// Calculate remaining days until due date
  /// Returns null if due date cannot be parsed
  int? getRemainingDays() {
    DateTime? dueDateTime = getParsedDueDate();
    if (dueDateTime == null) return null;

    // Get current date without time component for accurate day calculation
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime dueDateOnly =
        DateTime(dueDateTime.year, dueDateTime.month, dueDateTime.day);

    // Calculate difference in days
    int daysDifference = dueDateOnly.difference(today).inDays;

    return daysDifference;
  }

  /// Get formatted due date text for display
  /// Shows "X days left" if remaining days <= 15
  /// Shows "X days overdue" only for first 10 days of overdue
  /// Shows actual date if remaining days > 15 or overdue > 10 days or cannot calculate
  /// Returns a map with 'type' and 'value' to support proper localization
  Map<String, dynamic> getFormattedDueDateInfo() {
    int? remainingDays = getRemainingDays();

    // If we can't calculate remaining days, return the original formatted date
    if (remainingDays == null) {
      return {'type': 'date', 'value': dueDateOriginal};
    }

    // If more than 15 days remaining, show the actual date
    if (remainingDays > 15) {
      return {'type': 'date', 'value': dueDateOriginal};
    }

    // If 15 or fewer days remaining, show remaining days
    if (remainingDays == 0) {
      return {'type': 'dueToday', 'value': null};
    } else if (remainingDays == 1) {
      return {'type': 'dayLeft', 'value': 1};
    } else if (remainingDays < 0) {
      // Overdue
      int overdueDays = remainingDays.abs();

      // Show "Overdue" only for first 10 days, after that show actual date
      if (overdueDays > 10) {
        return {'type': 'date', 'value': dueDateOriginal};
      }

      return {
        'type': overdueDays == 1 ? 'dayOverdue' : 'daysOverdue',
        'value': overdueDays
      };
    } else {
      return {'type': 'daysLeft', 'value': remainingDays};
    }
  }

  /// Returns the `class_subject.subject` map of [source], or null when any
  /// level of that path is missing.
  static Map<String, dynamic>? _subjectJsonOf(dynamic source) {
    final classSubject = source is Map ? source['class_subject'] : null;
    final subject = classSubject is Map ? classSubject['subject'] : null;
    return subject is Map ? Map<String, dynamic>.from(subject) : null;
  }

  /// An assignment can be shared across class sections, so the API now sends
  /// its class section / class subject in `assignment_commons` and leaves the
  /// top-level fields null. Picks the first entry that carries a subject so
  /// the ids and the subject all come from the same entry.
  static Map<String, dynamic> _primaryAssignmentCommon(
    Map<String, dynamic> json,
  ) {
    final rawCommons = json['assignment_commons'];
    final commons = rawCommons is List
        ? rawCommons
            .whereType<Map>()
            .map((common) => Map<String, dynamic>.from(common))
            .toList()
        : <Map<String, dynamic>>[];

    return commons.firstWhere(
      (common) => _subjectJsonOf(common) != null,
      orElse: () => commons.isNotEmpty ? commons.first : <String, dynamic>{},
    );
  }

  Assignment.fromJson(Map<String, dynamic> json) {
    // Top-level values win so older API responses keep working.
    final primaryCommon = _primaryAssignmentCommon(json);

    id = json['id'] ?? 0;
    classSectionId =
        json['class_section_id'] ?? primaryCommon['class_section_id'] ?? 0;
    subjectId =
        json['class_subject_id'] ?? primaryCommon['class_subject_id'] ?? 0;
    name = json['name'] ?? "";
    instructions = json['instructions'] ?? "";
    // Use due_date (formatted string) for display
    dueDate = json['due_date'] ?? "";
    // Use due_date_original for date comparisons and parsing
    dueDateOriginal = json['due_date_original'] ?? "";
    points = json['points'] ?? 0;
    resubmission = json['resubmission'] ?? -1;
    extraDaysForResubmission = json['extra_days_for_resubmission'] ?? 0;
    sessionYearId = json['session_year_id'] ?? 0;
    referenceMaterials = ((json['file'] ?? []) as List)
        .map((file) => StudyMaterial.fromJson(Map.from(file)))
        .toList();
    assignmentSubmission =
        AssignmentSubmission.fromJson(Map.from(json['submission'] ?? {}));

    subject = Subject.fromJson(
      _subjectJsonOf(json) ?? _subjectJsonOf(primaryCommon) ?? {},
    );
    createdAt = json['created_at'] ?? ""; // Keep as string for display
    createdAtOriginal = json['created_at_original'] ?? "";
    schoolId = json['school_id'] ?? 0;
  }
}

class AssignmentSubmission {
  AssignmentSubmission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.sessionYearId,
    required this.feedback,
    required this.status,
    required this.createdAt,
    required this.createdAtOriginal,
    required this.updatedAt,
    required this.points,
    required this.submittedFiles,
  });
  late final int id;
  late final List<StudyMaterial> submittedFiles;
  late final int assignmentId;
  late final int studentId;
  late final int sessionYearId;
  late final String feedback;
  late final int status;
  late final String createdAt;
  late final int points;
  late final String updatedAt;
  late final String createdAtOriginal;

  AssignmentSubmission.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? 0;
    points = json['points'] ?? 0;
    assignmentId = json['assignment_id'] ?? 0;
    studentId = json['student_id'] ?? 0;
    sessionYearId = json['session_year_id'] ?? 0;
    feedback = json['feedback'] ?? "";
    status = json['status'] ?? -1;
    createdAt = json['created_at'] == null
        ? DateTime.now().toString()
        : json['created_at'];
    createdAtOriginal = json['created_at_original'] ?? "";
    updatedAt = json['updated_at'] == null
        ? DateTime.now().toString()
        : json['updated_at'];
    submittedFiles = ((json['file'] ?? []) as List)
        .map(
          (submittedFiles) => StudyMaterial.fromJson(Map.from(submittedFiles)),
        )
        .toList();
  }
}
