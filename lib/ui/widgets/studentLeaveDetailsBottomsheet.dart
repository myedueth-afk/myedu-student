import 'package:eschool/data/models/studentLeave.dart';
import 'package:eschool/ui/styles/colors.dart';
import 'package:eschool/ui/widgets/bottomsheetTopTitleAndCloseButton.dart';
import 'package:eschool/ui/widgets/customRoundedButton.dart';
import 'package:eschool/ui/widgets/customTextContainer.dart';
import 'package:eschool/ui/widgets/downloadFileButton.dart';
import 'package:eschool/ui/widgets/studentLeaveStatusChip.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Read-only breakdown of one leave request. The sheet stays presentational:
/// cancelling is handed back to the screen through [onTapCancelRequest] so the
/// cubit lives with the list that has to refresh afterwards.
class StudentLeaveDetailsBottomsheet extends StatelessWidget {
  final StudentLeave leave;
  final VoidCallback? onTapCancelRequest;

  const StudentLeaveDetailsBottomsheet({
    Key? key,
    required this.leave,
    this.onTapCancelRequest,
  }) : super(key: key);

  static const TextStyle _labelTextStyle = TextStyle(
    color: captionColor,
    fontSize: 12.0,
    height: 16 / 12,
    letterSpacing: 0.4,
  );

  TextStyle _valueTextStyle(BuildContext context) => TextStyle(
        color: Theme.of(context).colorScheme.secondary,
        fontSize: 14.0,
        height: 20 / 14,
        letterSpacing: 0.1,
        fontWeight: FontWeight.w500,
      );

  Widget _buildLabelAndValue({
    required BuildContext context,
    required String labelKey,
    required String value,
    Widget? trailing,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextContainer(textKey: labelKey, style: _labelTextStyle),
        const SizedBox(height: 4.0),
        Text(value, style: _valueTextStyle(context)),
      ],
    );

    if (trailing == null) {
      return content;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: content),
        const SizedBox(width: 8.0),
        trailing,
      ],
    );
  }

  /// "Class Teacher on 10 Aug 2026" — the approver name and the day they
  /// acted. Either half can be missing, so the line adapts to what is there.
  String _buildActionByValue() {
    final name = (leave.actionByName ?? "").trim();
    final date = Utils.formatDayMonthYear(leave.actionDate);

    if (name.isEmpty && date.isEmpty) {
      return "-";
    }
    if (date.isEmpty) {
      return name;
    }
    if (name.isEmpty) {
      return date;
    }

    return "$name ${Utils.getTranslatedLabel(onKey)} $date";
  }

  Widget _buildRejectedReason(BuildContext context) {
    return Container(
      width: double.maxFinite,
      margin: const EdgeInsets.only(top: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: leaveRejectedReasonBackgroundColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextContainer(
            textKey: rejectedReasonKey,
            style: _labelTextStyle,
          ),
          const SizedBox(height: 4.0),
          Text(leave.note!.trim(), style: _valueTextStyle(context)),
        ],
      ),
    );
  }

  Widget _buildAttachments(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16.0),
        CustomTextContainer(textKey: attachmentKey, style: _labelTextStyle),
        ...leave.attachments.map(
          (attachment) => Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    attachment.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _valueTextStyle(context),
                  ),
                ),
                const SizedBox(width: 8.0),
                DownloadFileButton(studyMaterial: attachment),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasRejectionNote =
        leave.isRejected && (leave.note ?? "").trim().isNotEmpty;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BottomsheetTopTitleAndCloseButton(
              titleKey: leaveDetailsKey,
              onTapCloseButton: () => Get.back(),
            ),
            _buildLabelAndValue(
              context: context,
              labelKey: submittedOnKey,
              value: Utils.formatDayMonthYear(leave.createdAt).isEmpty
                  ? "-"
                  : Utils.formatDayMonthYear(leave.createdAt),
              trailing: StudentLeaveStatusChip(status: leave.leaveStatus),
            ),
            const SizedBox(height: 16.0),
            _buildLabelAndValue(
              context: context,
              labelKey: leaveDurationKey,
              value:
                  "${Utils.formatLeaveDateRange(fromDate: leave.fromDate, toDate: leave.toDate)} (${leave.totalDays} ${Utils.getTranslatedLabel(leave.totalDays == 1 ? leaveDayKey : leaveDaysKey)})",
            ),
            const SizedBox(height: 16.0),
            _buildLabelAndValue(
              context: context,
              labelKey: reasonKey,
              value: (leave.reason ?? "").trim().isEmpty
                  ? "-"
                  : leave.reason!.trim(),
            ),
            if (!leave.isPending) ...[
              const SizedBox(height: 16.0),
              _buildLabelAndValue(
                context: context,
                labelKey: leave.isApproved ? approvedByKey : rejectedByKey,
                value: _buildActionByValue(),
              ),
            ],
            if (hasRejectionNote) _buildRejectedReason(context),
            if (leave.attachments.isNotEmpty) _buildAttachments(context),
            if (leave.isPending && onTapCancelRequest != null) ...[
              const SizedBox(height: 24.0),
              CustomRoundedButton(
                onTap: onTapCancelRequest,
                height: 48.0,
                widthPercentage: 1.0,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                buttonTitle: Utils.getTranslatedLabel(cancelRequestKey),
                titleColor: leaveRejectedColor,
                borderColor: leaveRejectedColor,
                showBorder: true,
                radius: 8.0,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
