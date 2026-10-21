import 'package:eschool/ui/widgets/bottomsheetTopTitleAndCloseButton.dart';
import 'package:eschool/ui/widgets/customRoundedButton.dart';
import 'package:eschool/ui/widgets/customTextFieldContainer.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/route_manager.dart';

class AdvanceInstallmentAmountBottomsheet extends StatefulWidget {
  final double advanceInstallmentAmount;
  final double maximumAmountLimit;

  /// Called with the chosen advance amount the moment the user confirms/clears.
  ///
  /// This is the reliable channel for delivering the value back to the caller —
  /// it does not depend on the navigator result ([Get.back] result) propagating
  /// through `.then`, which can silently fail and leave the amount unapplied.
  final ValueChanged<double>? onAmountSelected;

  const AdvanceInstallmentAmountBottomsheet({
    super.key,
    required this.maximumAmountLimit,
    required this.advanceInstallmentAmount,
    this.onAmountSelected,
  });

  @override
  State<AdvanceInstallmentAmountBottomsheet> createState() =>
      _AdvanceInstallmentAmountBottomsheetState();
}

class _AdvanceInstallmentAmountBottomsheetState
    extends State<AdvanceInstallmentAmountBottomsheet> {
  late final TextEditingController _textEditingController =
      TextEditingController(
    // Show empty field if advance amount is 0 so user can type fresh
    text: widget.advanceInstallmentAmount > 0
        ? widget.advanceInstallmentAmount.toString()
        : '',
  );

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    FocusScope.of(context).unfocus();
    final text = _textEditingController.text.trim();

    // Empty field → treat as clear (0)
    if (text.isEmpty) {
      widget.onAmountSelected?.call(0.0);
      Get.back(result: 0.0);
      return;
    }

    final advanceAmount = double.tryParse(text);
    if (advanceAmount == null) {
      Utils.showCustomSnackBar(
        context: context,
        errorMessage: Utils.getTranslatedLabel(pleaseEnterValidAmountKey),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return;
    }

    if (advanceAmount > widget.maximumAmountLimit) {
      Utils.showCustomSnackBar(
        context: context,
        errorMessage:
            "${Utils.getTranslatedLabel(maximumAmountIsKey)} ${widget.maximumAmountLimit.toStringAsFixed(2)}",
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return;
    }

    widget.onAmountSelected?.call(advanceAmount);
    Get.back(result: advanceAmount);
  }

  void _onClear() {
    FocusScope.of(context).unfocus();
    widget.onAmountSelected?.call(0.0);
    Get.back(result: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.only(
        left: MediaQuery.of(context).size.width * 0.075,
        right: MediaQuery.of(context).size.width * 0.075,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 25),
          BottomsheetTopTitleAndCloseButton(
            onTapCloseButton: () => Get.back(),
            titleKey: changeInstallmentAmountKey,
          ),
          CustomTextFieldContainer(
            bottomPadding: 5,
            textEditingController: _textEditingController,
            hideText: false,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            hintTextKey: installmentAmountKey,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Text(
              "${Utils.getTranslatedLabel(maximumAmountIsKey)} ${widget.maximumAmountLimit.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 12.0,
                color: Theme.of(context)
                    .colorScheme
                    .secondary
                    .withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Clear button: only shown when there is an existing advance amount ──
          if (widget.advanceInstallmentAmount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: InkWell(
                onTap: _onClear,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 11.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .error
                          .withValues(alpha: 0.6),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.clear_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        Utils.getTranslatedLabel(clearAdvanceAmountKey),
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Center(
            child: CustomRoundedButton(
              height: 40,
              widthPercentage: 0.3,
              backgroundColor: Theme.of(context).colorScheme.primary,
              buttonTitle: submitKey,
              showBorder: false,
              onTap: _onSubmit,
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
