import 'package:eschool/data/models/subjectWiseReport.dart';
import 'package:eschool/data/models/subject.dart';
import 'package:eschool/ui/screens/reports/widgets/reportCardTitle.dart';
import 'package:eschool/ui/screens/reports/widgets/reportDivider.dart';
import 'package:eschool/ui/screens/reports/widgets/reportPerformanceBox.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';

class OfflineExamReportCard extends StatelessWidget {
  final OfflineExamReport? report;
  final Subject subject;

  /// Called when the user taps "View Exam Result".
  /// Navigation logic lives in SubjectWiseDetailedReport.
  final VoidCallback onViewExamResult;

  const OfflineExamReportCard({
    Key? key,
    required this.report,
    required this.subject,
    required this.onViewExamResult,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (report == null || report!.summary == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReportCardTitle(title: Utils.getTranslatedLabel(offlineExamKey)),
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
                Text(
                  Utils.getTranslatedLabel(averageMarkKey),
                  style: TextStyle(
                      fontSize: 12,
                      color: Utils.getColorScheme(context)
                          .onSurface
                          .withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Utils.getColorScheme(context).surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject
                                  .getSubjectName(context: context)
                                  .replaceAll('(', '')
                                  .replaceAll(')', ''),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${Utils.getTranslatedLabel(totalKey)} : ${report!.summary?.obtainedMarks ?? 0}/${report!.summary?.totalMarks ?? 0}",
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Utils.getColorScheme(context)
                                      .onSurface
                                      .withValues(alpha: 0.5)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Utils.getColorScheme(context).primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "${report!.summary?.percentage ?? 0}%",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
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
