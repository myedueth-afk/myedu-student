import 'package:flutter/material.dart';

/// A label with a figure set hard against the right edge — the summary line
/// used wherever an amount is stated rather than entered.
///
/// The flex structure is the whole point of this widget. The label is the only
/// flexible child, so it absorbs the leftover width and the amount lands on the
/// right edge. Making the amount flexible too — the obvious way to guard it
/// against overflowing — splits the row in half instead and leaves the figure
/// floating in the middle of its own oversized box, which reads as a layout
/// mistake even though nothing overflows.
///
/// A long amount is handled by the label giving way: it wraps, then ellipsizes.
class LabelledAmountRow extends StatelessWidget {
  final String label;
  final String amount;

  final TextStyle? labelStyle;
  final TextStyle? amountStyle;

  /// Room between the two, so a long label never runs into the figure.
  final double spacing;

  const LabelledAmountRow({
    super.key,
    required this.label,
    required this.amount,
    this.labelStyle,
    this.amountStyle,
    this.spacing = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: labelStyle ??
                TextStyle(
                  fontSize: 14.0,
                  letterSpacing: 0.1,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ),
        SizedBox(width: spacing),
        //inflexible on purpose — see the note on this class
        Text(
          amount,
          maxLines: 1,
          textAlign: TextAlign.end,
          style: amountStyle ??
              TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.15,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }
}
