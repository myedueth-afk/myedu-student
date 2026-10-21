import 'package:eschool/ui/styles/colors.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';

/// States that the last payment was refused, and opens the detail behind it.
///
/// The banner itself carries only the fact. The school's reason is free text
/// that can run to a paragraph, and it comes with somewhere to go next, so it
/// belongs in a sheet with room for both rather than folded into a strip near
/// the top of a long, scrolling screen.
///
/// The chevron points the way it opens: forward, into more.
class RejectedPaymentBanner extends StatelessWidget {
  final VoidCallback onTap;

  const RejectedPaymentBanner({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: errorContainerColor,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                Utils.getTranslatedLabel(lastTransactionRejectedKey),
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                  height: 20 / 14,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            Icon(
              Icons.chevron_right_rounded,
              size: 24.0,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }
}
