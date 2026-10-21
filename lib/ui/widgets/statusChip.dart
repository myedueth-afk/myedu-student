import 'package:flutter/material.dart';

/// States what became of something — a fee, a payment — as a filled pill.
///
/// One widget rather than a Container repeated per screen: a parent meets these
/// on the fee list, the fee itself and its payment history within a few taps,
/// and a chip that changes shape between them reads as a different thing each
/// time.
///
/// The label carries the meaning and the colour reinforces it, so the two must
/// agree; [Utils.getFeePaymentStatusColor] is where a fee's pairing is decided.
class StatusChip extends StatelessWidget {
  /// Already translated — the chip states, it does not look things up.
  final String label;

  /// Fill colour. Dark enough to carry the label on top of it.
  final Color color;

  const StatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Text(
        label,
        //a chip states one token, and its callers lay it out beside content
        //that has to keep its own room — a long translation shortens the chip
        //rather than pushing the row past its edge
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
          //the page's own background, so the label reads as cut out of the fill
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
      ),
    );
  }
}
