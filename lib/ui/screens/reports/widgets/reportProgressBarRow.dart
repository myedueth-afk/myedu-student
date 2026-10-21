import 'package:flutter/material.dart';

class ReportProgressBarRow extends StatelessWidget {
  final String label;
  final String value;
  final double percentage;
  final Color color;

  const ReportProgressBarRow({
    Key? key,
    required this.label,
    required this.value,
    required this.percentage,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500)),
              Text(value, style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    height: 8,
                    width: constraints.maxWidth *
                        (percentage.isNaN || percentage.isInfinite
                            ? 0
                            : (percentage / 100).clamp(0.0, 1.0)),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
