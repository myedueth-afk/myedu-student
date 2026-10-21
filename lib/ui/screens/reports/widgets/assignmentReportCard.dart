import 'package:eschool/data/models/subjectWiseReport.dart';
import 'package:eschool/ui/screens/reports/widgets/graphSegment.dart';
import 'package:eschool/ui/screens/reports/widgets/multiSegmentCircularGraph.dart';
import 'package:eschool/ui/screens/reports/widgets/reportCardTitle.dart';
import 'package:eschool/ui/screens/reports/widgets/reportDivider.dart';
import 'package:eschool/ui/screens/reports/widgets/reportLegendItem.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';

class AssignmentReportCard extends StatelessWidget {
  final AssignmentReport? report;

  /// Called when the user taps "View Assignment".
  /// Navigation logic lives in the parent screen (SubjectWiseDetailedReport)
  /// which has access to AuthCubit, childId, and subjects.
  final VoidCallback onViewAssignment;

  const AssignmentReportCard({
    Key? key,
    required this.report,
    required this.onViewAssignment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (report == null || report!.statistics == null) {
      return const SizedBox.shrink();
    }

    final stats = report!.statistics!;
    final points = report!.points;
    final total = stats.totalAssignments ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReportCardTitle(title: Utils.getTranslatedLabel(assignmentReportKey)),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Utils.getColorScheme(context)
                    .onSurface
                    .withValues(alpha: 0.1),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── Donut chart + legend ──────────────────────────────────
                Row(
                  children: [
                    MultiSegmentCircularGraph(
                      title: Utils.getTranslatedLabel(totalKey),
                      value: total.toString(),
                      segments: [
                        GraphSegment(
                            value: stats.accepted?.toDouble() ?? 0,
                            color: const Color(0XFF57CC99)),
                        GraphSegment(
                            value: stats.inReview?.toDouble() ?? 0,
                            color: Utils.getColorScheme(context).primary),
                        GraphSegment(
                            value: stats.pending?.toDouble() ?? 0,
                            color: const Color(0xffF89E1B)),
                        GraphSegment(
                            value: stats.rejected?.toDouble() ?? 0,
                            color: const Color(0XFFBB1B1B)),
                      ],
                      total: total.toDouble(),
                      bgColor: Utils.getColorScheme(context)
                          .primary
                          .withValues(alpha: 0.2),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ReportLegendItem(
                              color: const Color(0XFF57CC99),
                              text:
                                  "${Utils.getTranslatedLabel(acceptedKey)} : ${stats.accepted ?? 0}"),
                          ReportLegendItem(
                              color: Utils.getColorScheme(context).primary,
                              text:
                                  "${Utils.getTranslatedLabel(inReviewKey)} : ${stats.inReview ?? 0}"),
                          ReportLegendItem(
                              color: const Color(0xffF89E1B),
                              text:
                                  "${Utils.getTranslatedLabel(pendingKey)} : ${stats.pending ?? 0}"),
                          ReportLegendItem(
                              color: const Color(0XFFBB1B1B),
                              text:
                                  "${Utils.getTranslatedLabel(rejectedKey)} : ${stats.rejected ?? 0}"),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Points summary ────────────────────────────────────────
                if (points != null) ...[
                  const ReportDivider(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Utils.getColorScheme(context).surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                Utils.getTranslatedLabel(percentageKey),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Utils.getColorScheme(context)
                                        .onSurface
                                        .withValues(alpha: 0.5)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${points.percentage ?? 0}%",
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1.5,
                          height: 32,
                          color: Utils.getColorScheme(context)
                              .onSurface
                              .withValues(alpha: 0.1),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                Utils.getTranslatedLabel(overallScoreKey),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Utils.getColorScheme(context)
                                        .onSurface
                                        .withValues(alpha: 0.5)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${points.obtainedPoints ?? 0}/${points.totalPoints ?? 0}",
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── View Assignment button — outside the card border ───────────
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onViewAssignment,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    Utils.getTranslatedLabel(viewAssignmentKey),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Utils.getColorScheme(context).primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Utils.getColorScheme(context).primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
