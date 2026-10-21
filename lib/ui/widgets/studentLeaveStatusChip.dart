import 'package:eschool/data/models/studentLeave.dart';
import 'package:eschool/ui/styles/colors.dart';
import 'package:eschool/ui/widgets/customTextContainer.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:flutter/material.dart';

/// Pill showing the current status of a leave request. Colors follow the
/// leave palette in [colors.dart] so the list card and the details sheet
/// always render a status the same way.
class StudentLeaveStatusChip extends StatelessWidget {
  final StudentLeaveStatus status;

  const StudentLeaveStatusChip({Key? key, required this.status})
      : super(key: key);

  Color get _backgroundColor {
    switch (status) {
      case StudentLeaveStatus.approved:
        return leaveApprovedColor;
      case StudentLeaveStatus.rejected:
        return leaveRejectedColor;
      case StudentLeaveStatus.pending:
        return leavePendingColor;
    }
  }

  String get _labelKey {
    switch (status) {
      case StudentLeaveStatus.approved:
        return acceptedKey;
      case StudentLeaveStatus.rejected:
        return rejectedKey;
      case StudentLeaveStatus.pending:
        return pendingKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: CustomTextContainer(
        textKey: _labelKey,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.0,
          height: 16 / 12,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
