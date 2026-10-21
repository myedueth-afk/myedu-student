import 'package:eschool/data/models/subjectWiseReport.dart';
import 'package:eschool/ui/screens/reports/widgets/graphSegment.dart';
import 'package:eschool/ui/screens/reports/widgets/multiSegmentCircularGraph.dart';
import 'package:eschool/ui/screens/reports/widgets/reportCardTitle.dart';
import 'package:eschool/ui/screens/reports/widgets/reportDivider.dart';
import 'package:eschool/ui/screens/reports/widgets/reportLegendItem.dart';
import 'package:eschool/ui/screens/reports/widgets/reportProgressBarRow.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';

const List<Color> _categoryBarColors = [
  Color(0xFF22577A), // dark navy
  Color(0xFFFB7020), // deep orange
  Color(0xFFF89E1B), // amber / light orange
  Color(0xFF57CC99), // teal
  Color(0xFF0495E1), // blue
];

class DiaryReportCard extends StatefulWidget {
  final DiaryReport? report;

  /// Called when the user taps "View Diary".
  /// Navigation logic lives in SubjectWiseDetailedReport which knows
  /// the auth state, childId and student profile.
  final VoidCallback onViewDiary;

  const DiaryReportCard({
    Key? key,
    required this.report,
    required this.onViewDiary,
  }) : super(key: key);

  @override
  State<DiaryReportCard> createState() => _DiaryReportCardState();
}

class _DiaryReportCardState extends State<DiaryReportCard> {
  bool _showPositive = true;

  List<DiaryCategory> get _activeCategories => _showPositive
      ? (widget.report?.topPositiveCategories ?? [])
      : (widget.report?.topNegativeCategories ?? []);

  String get _sectionTitle => _showPositive
      ? Utils.getTranslatedLabel(topPositiveCategoryKey)
      : Utils.getTranslatedLabel(topNegativeCategoryKey);

  @override
  Widget build(BuildContext context) {
    if (widget.report == null || widget.report!.summary == null) {
      return const SizedBox.shrink();
    }

    final summary = widget.report!.summary!;
    final total = summary.totalEntries ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReportCardTitle(title: Utils.getTranslatedLabel(diaryReportKey)),
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
                // ── Summary donut + legend ──────────────────────────────────
                Row(
                  children: [
                    MultiSegmentCircularGraph(
                      title: Utils.getTranslatedLabel(totalKey),
                      value: total.toString(),
                      segments: [
                        GraphSegment(
                            value: summary.positiveCount?.toDouble() ?? 0,
                            color: Colors.green),
                        GraphSegment(
                            value: summary.negativeCount?.toDouble() ?? 0,
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
                              color: Colors.green,
                              text:
                                  "${Utils.getTranslatedLabel(positiveKey)} : ${summary.positiveCount ?? 0}"),
                          ReportLegendItem(
                              color: Colors.red,
                              text:
                                  "${Utils.getTranslatedLabel(negativeKey)} : ${summary.negativeCount ?? 0}"),
                        ],
                      ),
                    ),
                  ],
                ),

                const ReportDivider(),

                // ── Category section header with filter pill ────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _sectionTitle,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CategoryFilterPill(
                      isPositive: _showPositive,
                      onChanged: (value) =>
                          setState(() => _showPositive = value),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Category progress bars ──────────────────────────────────
                if (_activeCategories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      Utils.getTranslatedLabel(noDataFoundKey),
                      style: TextStyle(
                        fontSize: 13,
                        color: Utils.getColorScheme(context)
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  )
                else
                  ...List.generate(_activeCategories.length, (index) {
                    final cat = _activeCategories[index];
                    final pct =
                        double.tryParse(cat.percentage.toString()) ?? 0.0;
                    final color =
                        _categoryBarColors[index % _categoryBarColors.length];
                    return ReportProgressBarRow(
                      label: "${cat.categoryName ?? ''} (${cat.count ?? 0})",
                      value: "${pct.toStringAsFixed(0)}%",
                      percentage: pct,
                      color: color,
                    );
                  }),
              ],
            ),
          ),

          // ── View Diary button — outside the card border ────────────────
          const SizedBox(height: 12),
          GestureDetector(
            onTap: widget.onViewDiary,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    Utils.getTranslatedLabel(viewDiaryKey),
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

/// Small pill-shaped dropdown button that toggles between Positive / Negative.
/// Uses a [PopupMenuButton] so the chevron is semantically correct.
class _CategoryFilterPill extends StatelessWidget {
  final bool isPositive;
  final ValueChanged<bool> onChanged;

  const _CategoryFilterPill({
    required this.isPositive,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final label = isPositive
        ? Utils.getTranslatedLabel(positiveKey)
        : Utils.getTranslatedLabel(negativeKey);

    return PopupMenuButton<bool>(
      onSelected: onChanged,
      color: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      offset: const Offset(0, 36),
      itemBuilder: (_) => [
        PopupMenuItem<bool>(
          value: true,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  Utils.getTranslatedLabel(positiveKey),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isPositive ? FontWeight.w600 : FontWeight.normal,
                    color: isPositive
                        ? Utils.getColorScheme(context).primary
                        : Utils.getColorScheme(context).onSurface,
                  ),
                ),
              ),
              if (isPositive)
                Icon(Icons.check,
                    size: 16, color: Utils.getColorScheme(context).primary),
            ],
          ),
        ),
        PopupMenuItem<bool>(
          value: false,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  Utils.getTranslatedLabel(negativeKey),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        !isPositive ? FontWeight.w600 : FontWeight.normal,
                    color: !isPositive
                        ? Utils.getColorScheme(context).primary
                        : Utils.getColorScheme(context).onSurface,
                  ),
                ),
              ),
              if (!isPositive)
                Icon(Icons.check,
                    size: 16, color: Utils.getColorScheme(context).primary),
            ],
          ),
        ),
      ],
      // Custom pill trigger
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Utils.getColorScheme(context).surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                Utils.getColorScheme(context).onSurface.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Utils.getColorScheme(context).onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: Utils.getColorScheme(context)
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
