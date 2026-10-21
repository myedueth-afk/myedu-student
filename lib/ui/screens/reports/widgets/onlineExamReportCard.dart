import 'package:eschool/data/models/subjectWiseReport.dart';
import 'package:eschool/ui/screens/reports/widgets/graphSegment.dart';
import 'package:eschool/ui/screens/reports/widgets/multiSegmentCircularGraph.dart';
import 'package:eschool/ui/screens/reports/widgets/reportCardTitle.dart';
import 'package:eschool/ui/screens/reports/widgets/reportDivider.dart';
import 'package:eschool/ui/screens/reports/widgets/reportLegendItem.dart';
import 'package:eschool/ui/screens/reports/widgets/reportPerformanceBox.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';

class OnlineExamReportCard extends StatelessWidget {
  final OnlineExamReport? report;

  /// Called when the user taps "View Exam Result".
  /// Navigation logic lives in SubjectWiseDetailedReport.
  final VoidCallback onViewExamResult;

  const OnlineExamReportCard({
    Key? key,
    required this.report,
    required this.onViewExamResult,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (report == null || report!.summary == null) {
      return const SizedBox.shrink();
    }

    final summary = report!.summary!;
    final total = summary.totalExams ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReportCardTitle(title: Utils.getTranslatedLabel(onlineExamKey)),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MultiSegmentCircularGraph(
                      title: Utils.getTranslatedLabel(totalKey),
                      value: total.toString(),
                      segments: [
                        GraphSegment(
                            value: summary.completedExams?.toDouble() ?? 0,
                            color: Utils.getColorScheme(context).primary),
                        GraphSegment(
                            value: summary.missedExams?.toDouble() ?? 0,
                            color: Colors.red),
                      ],
                      total: total.toDouble(),
                      bgColor: Colors.red.withValues(alpha: 0.2),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ReportLegendItem(
                              color: Utils.getColorScheme(context).primary,
                              text:
                                  "${Utils.getTranslatedLabel(completedKey)} : ${summary.completedExams ?? 0}"),
                          ReportLegendItem(
                              color: Colors.red,
                              text:
                                  "${Utils.getTranslatedLabel(missedKey)} : ${summary.missedExams ?? 0}"),
                        ],
                      ),
                    ),
                  ],
                ),
                const ReportDivider(),
                ReportPerformanceBox(
                  title: Utils.getTranslatedLabel(bestExamPerformanceKey),
                  performanceList: report!.bestPerformance,
                  badgeColor: Colors.green,
                ),
                const SizedBox(height: 16),
                ReportPerformanceBox(
                  title: Utils.getTranslatedLabel(weakExamPerformanceKey),
                  performanceList: report!.weakPerformance,
                  badgeColor: Colors.redAccent,
                ),
              ],
            ),
          ),

          // ── View Exam Result button — outside the card border ──────────
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onViewExamResult,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    Utils.getTranslatedLabel(viewExamResultKey),
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
