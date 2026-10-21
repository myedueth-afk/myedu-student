import 'package:eschool/ui/screens/reports/widgets/graphSegment.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';

class MultiSegmentCircularGraph extends StatelessWidget {
  final String title;
  final String value;
  final List<GraphSegment> segments;
  final double total;
  final Color bgColor;

  const MultiSegmentCircularGraph({
    Key? key,
    required this.title,
    required this.value,
    required this.segments,
    required this.total,
    required this.bgColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      width: 116,
      child: Stack(
        children: [
          Center(
            child: SizedBox(
              height: 116,
              width: 116,
              child: CustomPaint(
                painter: MultiSegmentGraphPainter(
                  segments: segments,
                  total: total,
                  backgroundColor: bgColor,
                  strokeWidth: 8.0,
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Utils.getColorScheme(context)
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Utils.getColorScheme(context).onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
