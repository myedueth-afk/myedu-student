import 'package:eschool/data/models/subjectWiseReport.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';

class ReportPerformanceBox extends StatelessWidget {
  final String title;
  final List<dynamic>? performanceList;
  final Color badgeColor;

  const ReportPerformanceBox({
    Key? key,
    required this.title,
    required this.performanceList,
    required this.badgeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (performanceList == null || performanceList!.isEmpty) {
      return const SizedBox.shrink();
    }

    final item = performanceList!.first;

    String name = '';
    String marks = '';
    String? examDate;
    String? grade;

    if (item is OnlineExamPerformance) {
      name = item.examName ?? '-';
      marks = "${item.obtainedMarks ?? 0}/${item.totalMarks ?? 0}";
      // Online exams have no date or grade
    } else if (item is OfflineExamPerformance) {
      name = item.examName ?? '-';
      marks = "${item.obtainedMarks ?? 0}/${item.totalMarks ?? 0}";
      examDate = (item.examDate != null && item.examDate!.isNotEmpty)
          ? item.examDate
          : null;
      grade =
          (item.grade != null && item.grade!.isNotEmpty) ? item.grade : null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color:
                Utils.getColorScheme(context).onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Utils.getColorScheme(context).surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Left: exam name + optional date ──────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (examDate != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        examDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Utils.getColorScheme(context)
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // ── Right: grade badge (offline only) + score badge ───────────
              if (grade != null) ...[
                _Badge(
                  label: grade,
                  color: Utils.getColorScheme(context).primary,
                ),
                const SizedBox(width: 6),
              ],
              _Badge(
                label: marks,
                color: badgeColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Small rounded badge used for grade and score.
class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
