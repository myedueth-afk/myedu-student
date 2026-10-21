import 'package:eschool/ui/styles/colors.dart';
import 'package:eschool/ui/widgets/customRoundedButton.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';

/// Why the school refused the last manual payment, and the way on to the full
/// record of it.
///
/// A sheet rather than something folded into the fee screen: the reason is free
/// text a school types and can run to a paragraph, and it comes with an action
/// worth giving room to. Laid out like [TransactionDetailsBottomsheet] so the
/// two read as the same thing seen from different places.
class RejectedPaymentBottomsheet extends StatelessWidget {
  /// The school's own words. Null when it gave none, in which case the sheet
  /// states the refusal and leaves it there.
  final String? reason;

  /// Opens this fee's payment history.
  final VoidCallback onViewTransaction;

  const RejectedPaymentBottomsheet({
    super.key,
    required this.reason,
    required this.onViewTransaction,
  });

  Widget _buildTitle(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 12.0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: secondaryStrokeColor)),
      ),
      child: Text(
        Utils.getTranslatedLabel(lastTransactionRejectedKey),
        style: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          height: 24 / 16,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _buildReason(BuildContext context) {
    final text = (reason ?? '').trim();
    if (text.isEmpty) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: errorContainerColor,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Utils.getTranslatedLabel(reasonKey),
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              text,
              style: TextStyle(
                fontSize: 12.0,
                letterSpacing: 0.4,
                height: 16 / 12,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTitle(context),
              _buildReason(context),
              const SizedBox(height: 24.0),
              CustomRoundedButton(
                height: 48.0,
                radius: 8.0,
                //CustomRoundedButton sizes off the full screen width, so the
                //sheet's 16px padding on each side has to be discounted
                widthPercentage: (MediaQuery.of(context).size.width - 32.0) /
                    MediaQuery.of(context).size.width,
                textSize: 16.0,
                fontWeight: FontWeight.w500,
                backgroundColor: Theme.of(context).colorScheme.primary,
                buttonTitle: Utils.getTranslatedLabel(viewTransactionKey),
                showBorder: false,
                onTap: onViewTransaction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
