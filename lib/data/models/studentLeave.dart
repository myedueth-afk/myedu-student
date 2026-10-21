import 'package:eschool/data/models/studyMaterial.dart';
import 'package:eschool/utils/utils.dart';

/// Status of a student leave request as stored by the backend.
/// 0 -> Pending, 1 -> Approved, 2 -> Rejected
enum StudentLeaveStatus { pending, approved, rejected }

StudentLeaveStatus getStudentLeaveStatus(int? status) {
  if (status == 1) {
    return StudentLeaveStatus.approved;
  }
  if (status == 2) {
    return StudentLeaveStatus.rejected;
  }

  return StudentLeaveStatus.pending;
}

class StudentLeave {
  final int? id;
  final int? childId;
  final String? fromDate;
  final String? toDate;
  final String? reason;
  final int? status;
  final String? createdAt;

  /// Number of days the leave spans. Sent by the backend, but derived from the
  /// date range when it is absent so the UI always has a value to show.
  final double? days;

  /// Name of the staff member who approved or rejected the request and the day
  /// they acted on it. Only present once the request leaves [pending].
  final String? actionByName;
  final String? actionDate;

  /// Remark left by the approver. Shown as the rejection reason callout when
  /// the request was rejected.
  final String? note;

  /// Number of `leave_detail` rows the backend sent — one per leave day.
  final int leaveDays;

  final List<StudyMaterial> attachments;

  StudentLeave({
    this.id,
    this.childId,
    this.fromDate,
    this.toDate,
    this.reason,
    this.status,
    this.createdAt,
    this.days,
    this.actionByName,
    this.actionDate,
    this.note,
    this.leaveDays = 0,
    this.attachments = const [],
  });

  StudentLeave.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        childId = json['child_id'] as int? ?? json['student_id'] as int?,
        //`org_*` are the ISO dates; `from_date`/`to_date` come back already
        //formatted for display (dd-MM-yyyy) and are only a fallback.
        fromDate =
            json['org_from_date'] as String? ?? json['from_date'] as String?,
        toDate = json['org_to_date'] as String? ?? json['to_date'] as String?,
        reason = json['reason'] as String?,
        status = int.tryParse((json['status'] ?? 0).toString()),
        createdAt = json['created_at'] as String?,
        days = double.tryParse(
            (json['total_days'] ?? json['days'] ?? '').toString()),
        actionByName = _parseActionByName(json),
        actionDate = json['action_date'] as String? ??
            json['approved_at'] as String? ??
            json['updated_at'] as String?,
        note = json['note'] as String? ?? json['remark'] as String?,
        leaveDays = ((json['leave_detail'] ?? []) as List).length,
        attachments = ((json['file'] ?? json['files'] ?? []) as List)
            .map((file) => StudyMaterial.fromJson(Map.from(file ?? {})))
            .toList();

  /// The approver can come back either as a flat name or as a nested user
  /// relation, depending on the endpoint, so both shapes are accepted.
  static String? _parseActionByName(Map<String, dynamic> json) {
    final user = json['action_by'] ?? json['approved_by'] ?? json['staff'];

    if (user is Map) {
      final fullName = user['full_name'];
      if (fullName is String && fullName.trim().isNotEmpty) {
        return fullName;
      }
      final firstName = (user['first_name'] ?? '').toString().trim();
      final lastName = (user['last_name'] ?? '').toString().trim();
      final name = '$firstName $lastName'.trim();
      return name.isEmpty ? null : name;
    }

    if (user is String && user.trim().isNotEmpty) {
      return user;
    }

    return null;
  }

  StudentLeaveStatus get leaveStatus => getStudentLeaveStatus(status);

  bool get isPending => leaveStatus == StudentLeaveStatus.pending;

  bool get isApproved => leaveStatus == StudentLeaveStatus.approved;

  bool get isRejected => leaveStatus == StudentLeaveStatus.rejected;

  /// Days as shown on the list and details screens. The backend's `total_days`
  /// is authoritative; the `leave_detail` row count and then the date range are
  /// only used when an older payload omits it.
  int get totalDays {
    if (days != null && days! > 0) {
      return days!.round();
    }

    if (leaveDays > 0) {
      return leaveDays;
    }

    final from = Utils.parseApiDate(fromDate ?? '');
    final to = Utils.parseApiDate(toDate ?? '');
    if (from == null || to == null) {
      return 0;
    }

    return to.difference(from).inDays + 1;
  }
}
