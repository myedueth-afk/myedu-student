import 'package:eschool/ui/styles/colors.dart';
import 'package:eschool/ui/widgets/customRoundedButton.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// How the parent intends to settle the fee.
///
/// This is the choice between two different *flows*, not between two gateways —
/// picking a specific gateway (Razorpay, Stripe, …) still happens afterwards in
/// [SelectPaymentMethodBottomsheet] when the school has more than one enabled.
enum FeePaymentMethod { online, manual }

/// Asked before payment starts, but only when the school has enabled manual
/// payment alongside the online gateways. With a single route open the fee
/// screen skips this sheet entirely rather than presenting a one-option choice.
class SelectFeePaymentMethodBottomsheet extends StatefulWidget {
  /// Pre-selected when the sheet opens. Defaults to [FeePaymentMethod.online],
  /// which is the flow parents already know.
  final FeePaymentMethod initiallySelectedMethod;

  const SelectFeePaymentMethodBottomsheet({
    super.key,
    this.initiallySelectedMethod = FeePaymentMethod.online,
  });

  @override
  State<SelectFeePaymentMethodBottomsheet> createState() =>
      _SelectFeePaymentMethodBottomsheetState();
}

class _SelectFeePaymentMethodBottomsheetState
    extends State<SelectFeePaymentMethodBottomsheet> {
  late FeePaymentMethod _selectedMethod = widget.initiallySelectedMethod;

  Widget _buildTitle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 12.0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: secondaryStrokeColor)),
      ),
      child: Text(
        Utils.getTranslatedLabel(selectPaymentMethodKey),
        style: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  ///[The filled/hollow radio dot shown at the end of each option]
  Widget _buildRadio({required bool isSelected}) {
    return Container(
      width: 24.0,
      height: 24.0,
      alignment: Alignment.center,
      child: Container(
        width: 18.0,
        height: 18.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            width: isSelected ? 2.0 : 1.0,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : captionColor,
          ),
        ),
        child: isSelected
            ? Container(
                width: 9.0,
                height: 9.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : const SizedBox(),
      ),
    );
  }

  Widget _buildOption({
    required FeePaymentMethod method,
    required String titleKey,
    required String descriptionKey,
  }) {
    final isSelected = _selectedMethod == method;

    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: onlineClassCardColor,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Utils.getTranslatedLabel(titleKey),
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    Utils.getTranslatedLabel(descriptionKey),
                    style: const TextStyle(
                      fontSize: 12.0,
                      letterSpacing: 0.4,
                      color: captionColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            _buildRadio(isSelected: isSelected),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: double.infinity,
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTitle(),
            const SizedBox(height: 16.0),
            _buildOption(
              method: FeePaymentMethod.online,
              titleKey: onlinePaymentKey,
              descriptionKey: onlinePaymentDescriptionKey,
            ),
            const SizedBox(height: 16.0),
            _buildOption(
              method: FeePaymentMethod.manual,
              titleKey: manualPaymentKey,
              descriptionKey: manualPaymentDescriptionKey,
            ),
            const SizedBox(height: 16.0),
            CustomRoundedButton(
              height: 48.0,
              radius: 8.0,
              // CustomRoundedButton sizes itself off the full screen width, so
              // the sheet's 16px horizontal padding has to be discounted here
              // or the button overflows on both edges.
              widthPercentage: (MediaQuery.of(context).size.width - 32.0) /
                  MediaQuery.of(context).size.width,
              textSize: 16.0,
              fontWeight: FontWeight.w500,
              backgroundColor: Theme.of(context).colorScheme.primary,
              buttonTitle: Utils.getTranslatedLabel(continueKey),
              showBorder: false,
              onTap: () => Get.back(result: _selectedMethod),
            ),
          ],
        ),
      ),
    );
  }
}
