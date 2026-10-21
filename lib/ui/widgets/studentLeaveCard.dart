import 'package:eschool/data/models/studentLeave.dart';
import 'package:eschool/ui/styles/colors.dart';
import 'package:eschool/ui/widgets/customTextContainer.dart';
import 'package:eschool/ui/widgets/studentLeaveStatusChip.dart';
import 'package:eschool/utils/animationConfiguration.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Single leave request on the leaves list. Tapping it opens the details
/// bottomsheet handled by [onTap].
class StudentLeaveCard extends StatelessWidget {
  final StudentLeave leave;
  final VoidCallback onTap;

  const StudentLeaveCard({
    Key? key,
    required this.leave,
    required this.onTap,
  }) : super(key: key);

  static const TextStyle _labelTextStyle = TextStyle(
    color: captionColor,
    fontSize: 12.0,
    height: 16 / 12,
    letterSpacing: 0.4,
  );

  Widget _buildLabelAndValue({
    required BuildContext context,
    required String labelKey,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextContainer(textKey: labelKey, style: _labelTextStyle),
        const SizedBox(height: 4.0),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontSize: 14.0,
            height: 20 / 14,
            letterSpacing: 0.1,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = leave.totalDays;

    return Animate(
      effects: customItemFadeAppearanceEffects(),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: onlineClassCardColor,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "$totalDays ${Utils.getTranslatedLabel(totalDays == 1 ? leaveDayKey : leaveDaysKey)}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 16.0,
                        height: 24 / 16,
                        letterSpacing: 0.15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  StudentLeaveStatusChip(status: leave.leaveStatus),
                ],
              ),
              const Divider(height: 24.0, thickness: 1.0),
              _buildLabelAndValue(
                context: context,
                labelKey: datesKey,
                value: Utils.formatLeaveDateRange(
                  fromDate: leave.fromDate,
                  toDate: leave.toDate,
                ),
              ),
              const SizedBox(height: 12.0),
              _buildLabelAndValue(
                context: context,
                labelKey: reasonKey,
                value: (leave.reason ?? "").trim().isEmpty
                    ? "-"
                    : leave.reason!.trim(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
