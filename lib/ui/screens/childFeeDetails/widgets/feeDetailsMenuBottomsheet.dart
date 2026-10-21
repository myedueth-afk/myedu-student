import 'package:eschool/ui/styles/colors.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The actions available on a fee that are not the payment itself.
///
/// These used to be a lone print icon in the app bar. Printing is one of
/// several things a parent may want from a fee — seeing what has been paid
/// against it is another — and an app bar has room for one icon, not a growing
/// row of them. A single menu holds them and has room for the next one.
class FeeDetailsMenuBottomsheet extends StatelessWidget {
  /// Prints or downloads the fee receipt. Null when nothing has been paid
  /// against this fee yet, in which case the option is left out rather than
  /// shown as a dead end.
  final VoidCallback? onPrint;

  final VoidCallback onViewTransactionHistory;

  const FeeDetailsMenuBottomsheet({
    super.key,
    required this.onPrint,
    required this.onViewTransactionHistory,
  });

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String labelKey,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            Icon(icon,
                size: 24.0, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16.0),
            Expanded(
              child: Text(
                Utils.getTranslatedLabel(labelKey),
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.15,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 24.0,
              color: captionColor,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = <Widget>[
      if (onPrint != null)
        _buildOption(
          context,
          icon: CupertinoIcons.printer,
          labelKey: printKey,
          onTap: onPrint!,
        ),
      _buildOption(
        context,
        icon: Icons.history_rounded,
        labelKey: transactionHistoryKey,
        onTap: onViewTransactionHistory,
      ),
    ];

    return SafeArea(
      child: Container(
        width: double.infinity,
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            //the grab handle the app's other sheets use
            Container(
              width: 80.0,
              height: 5.0,
              margin: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .secondary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.5),
              ),
            ),
            for (var index = 0; index < options.length; index++) ...[
              if (index != 0)
                const Divider(height: 1.0, color: secondaryStrokeColor),
              options[index],
            ],
          ],
        ),
      ),
    );
  }
}
