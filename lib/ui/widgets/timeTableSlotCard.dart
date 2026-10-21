import 'package:eschool/data/models/timeTableSlot.dart';
import 'package:eschool/ui/styles/colors.dart';
import 'package:eschool/ui/widgets/subjectImageContainer.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

/// Controls how the online-class status is presented on the time row.
enum TimeTableSlotCardVariant {
  /// Time Table screen: green "Online Class" pill on the time row and an inline
  /// "Live" indicator next to the subject name.
  timeTable,

  /// Home / student-details "Online Classes" section: a "Live" / "Upcoming"
  /// status pill on the time row, and no inline "Live".
  onlineClasses,
}

/// Reusable timetable slot card shown on the Time Table screen and the Home
/// screen's "Online Classes" section.

class TimeTableSlotCard extends StatelessWidget {
  final TimeTableSlot timeTableSlot;

  /// The date this slot is being displayed for. Drives the
  /// online-class / live / upcoming / join-class logic.
  final DateTime selectedDate;

  /// Card background. Defaults to the scaffold background (white) used on the
  /// Time Table screen; the home / student-details "Online Classes" section
  /// passes a different colour.
  final Color? backgroundColor;

  /// Selects how the online-class status is presented (see
  /// [TimeTableSlotCardVariant]).
  final TimeTableSlotCardVariant variant;

  const TimeTableSlotCard({
    Key? key,
    required this.timeTableSlot,
    required this.selectedDate,
    this.backgroundColor,
    this.variant = TimeTableSlotCardVariant.timeTable,
  }) : super(key: key);

  ///[● Online Class] pill shown on the time row for online lectures.
  Widget _buildOnlineClassLabel(BuildContext context) {
    final labelColor = Theme.of(context).colorScheme.onSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: labelColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 8,
            width: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: labelColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            Utils.getTranslatedLabel(onlineClassKey),
            style: TextStyle(
              color: labelColor,
              fontWeight: FontWeight.w500,
              fontSize: 12.0,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  ///[● Live] indicator shown next to the subject name while the class is
  ///in progress.
  Widget _buildLiveLabel(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 8,
          width: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: liveStatusColor,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          Utils.getTranslatedLabel(liveKey),
          style: TextStyle(
            color: liveStatusColor,
            fontWeight: FontWeight.w500,
            fontSize: 12.0,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  ///[● Live] / [● Upcoming] status pill shown on the time row in the
  ///[TimeTableSlotCardVariant.onlineClasses] variant.
  Widget _buildStatusLabel(
    BuildContext context, {
    required Color color,
    required String labelKey,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 8,
            width: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            Utils.getTranslatedLabel(labelKey),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12.0,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  ///The trailing widget on the time row, depending on the [variant]:
  ///- [TimeTableSlotCardVariant.timeTable] -> green "Online Class" pill.
  ///- [TimeTableSlotCardVariant.onlineClasses] -> "Live" / "Upcoming" status.
  Widget _buildTimeRowTrailing(
    BuildContext context, {
    required bool showOnlineClassLabel,
    required bool isLive,
    required bool isUpcoming,
    required bool isCompleted,
  }) {
    if (variant == TimeTableSlotCardVariant.timeTable) {
      return showOnlineClassLabel
          ? _buildOnlineClassLabel(context)
          : const SizedBox.shrink();
    }

    if (isLive) {
      return _buildStatusLabel(context,
          color: liveStatusColor, labelKey: liveKey);
    }
    if (isUpcoming) {
      return _buildStatusLabel(
        context,
        color: Theme.of(context).colorScheme.onSecondary,
        labelKey: upcomingKey,
      );
    }
    if (isCompleted) {
      return _buildStatusLabel(
        context,
        color: completedStatusColor,
        labelKey: completedKey,
      );
    }
    return const SizedBox.shrink();
  }

  ///Underlined "Join Class" link that opens the meeting link.
  Widget _buildJoinClassButton(BuildContext context) {
    final linkColor = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: () => _joinClass(timeTableSlot.meetingLink),
      child: Text(
        Utils.getTranslatedLabel(joinClassKey),
        style: TextStyle(
          color: linkColor,
          fontWeight: FontWeight.w500,
          fontSize: 14.0,
          letterSpacing: 0.1,
          decoration: TextDecoration.underline,
          decorationColor: linkColor,
        ),
      ),
    );
  }

  Future<void> _joinClass(String meetingLink) async {
    if (meetingLink.isEmpty) return;
    final uri = Uri.parse(meetingLink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    ///[If the subject name is empty then it will consider as break]
    final isBreak =
        timeTableSlot.subject.getSubjectName(context: context).isEmpty;
    const double subjectBoxSize = 44;

    final subjectName = isBreak
        ? timeTableSlot.note
        : timeTableSlot.subject.getSubjectName(context: context);
    final teacherName =
        "${timeTableSlot.teacherFirstName} ${timeTableSlot.teacherLastName}"
            .trim();

    final now = DateTime.now();
    final isSelectedDateToday = DateUtils.isSameDay(selectedDate, now);

    ///[Online Class] pill is date based -> shown all day for the online class.
    final showOnlineClassLabel =
        timeTableSlot.showOnlineClassLabelOnDate(selectedDate);

    ///[Live] / [Upcoming] / [Join Class] are time based -> only valid for
    ///today's online lecture. Parsed once here instead of per status check.
    final isOnlineToday = showOnlineClassLabel && isSelectedDateToday;
    final status = timeTableSlot.onlineClassStatusAt(now);
    final isLive = isOnlineToday && status.isLive;
    final isUpcoming = isOnlineToday && status.isUpcoming;
    final isCompleted = isOnlineToday && status.isCompleted;
    final showJoinClass = isOnlineToday &&
        status.isJoinable &&
        timeTableSlot.meetingLink.isNotEmpty;

    ///Inline "Live" next to the subject name only exists on the Time Table
    ///variant (the home variant surfaces it as a status pill instead).
    final showInlineLiveLabel =
        variant == TimeTableSlotCardVariant.timeTable && isLive;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        ///Shadow only on the Time Table screen; the home "Online Classes"
        ///cards are flat on their grey background.
        boxShadow: variant == TimeTableSlotCardVariant.timeTable
            ? [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.08),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                )
              ]
            : null,
        color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      width: MediaQuery.of(context).size.width * (0.85),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ///[Action container] -> time + online class pill
          Row(
            children: [
              Expanded(
                child: Text(
                  "${timeTableSlot.startTime} - ${timeTableSlot.endTime}",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14.0,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              _buildTimeRowTrailing(
                context,
                showOnlineClassLabel: showOnlineClassLabel,
                isLive: isLive,
                isUpcoming: isUpcoming,
                isCompleted: isCompleted,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            thickness: 1,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 12),

          ///[Subject container] -> icon + details + join class
          Row(
            children: [
              isBreak
                  ? Container(
                      height: subjectBoxSize,
                      width: subjectBoxSize,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      padding: const EdgeInsets.all(10),
                      child: SvgPicture.asset(
                        Utils.getImagePath("lunch-time.svg"),
                        colorFilter: ColorFilter.mode(
                            Theme.of(context).scaffoldBackgroundColor,
                            BlendMode.srcIn),
                      ),
                    )
                  : SubjectImageContainer(
                      showShadow: false,
                      height: subjectBoxSize,
                      width: subjectBoxSize,
                      radius: 8,
                      subject: timeTableSlot.subject,
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            subjectName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                              fontSize: 14.0,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                        if (showInlineLiveLabel) ...[
                          const SizedBox(width: 4),
                          _buildLiveLabel(context),
                        ],
                      ],
                    ),
                    if (teacherName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          SvgPicture.asset(
                            Utils.getImagePath("user_icon.svg"),
                            height: 16,
                            width: 16,
                            colorFilter: ColorFilter.mode(
                              Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              teacherName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                                fontWeight: FontWeight.w400,
                                fontSize: 14.0,
                                letterSpacing: 0.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (showJoinClass) ...[
                const SizedBox(width: 8),
                _buildJoinClassButton(context),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
