import 'package:flutter/material.dart';

/// Border colour of the outlined cards used across the fee details screen and
/// its sub-widgets (Fee Breakdown, Installments, Fee Relief).
const Color feeCardBorderColor = Color(0xFFDFDFDF);

/// Outlined card container (1.5px [feeCardBorderColor] border, 16 radius,
/// 16 padding) shared by the fee details screen and [FeeReliefContainer].
class FeeSectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const FeeSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        border: Border.all(width: 1.5, color: feeCardBorderColor),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: child,
    );
  }
}

/// 1px divider line used inside the fee cards.
class FeeCardDivider extends StatelessWidget {
  const FeeCardDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(height: 1.0, color: feeCardBorderColor);
  }
}
