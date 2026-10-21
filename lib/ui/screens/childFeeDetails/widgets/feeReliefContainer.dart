import 'package:eschool/cubits/schoolConfigurationCubit.dart';
import 'package:eschool/data/models/childFeeDetails.dart';
import 'package:eschool/data/models/feeDiscount.dart';
import 'package:eschool/ui/screens/childFeeDetails/widgets/feeSectionCard.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// When more than one discount applies to the current scope, each one is shown
/// as its own reason sub-card prefixed with the discount name and amount so the
/// records stay distinguishable. The widget renders nothing when there is no
/// discount for the given scope.
class FeeReliefContainer extends StatelessWidget {
  final ChildFeeDetails childFeeDetails;

  /// When true, shows compulsory scoped discounts, otherwise optional ones.
  final bool compulsory;

  const FeeReliefContainer({
    super.key,
    required this.childFeeDetails,
    required this.compulsory,
  });

  String _currency(BuildContext context) {
    return context
            .read<SchoolConfigurationCubit>()
            .getSchoolConfiguration()
            .schoolSettings
            .currencySymbol ??
        '';
  }

  Widget _reasonCard(
    BuildContext context,
    FeeDiscount discount, {
    required bool showHeader,
  }) {
    final reliefColor = Theme.of(context).colorScheme.onSecondary;
    final currency = _currency(context);
    final description = (discount.description ?? "").trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + amount header (only when multiple discounts are listed).
          if (showHeader) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    discount.discountName ?? "",
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                Text(
                  "-$currency${discount.effectiveDiscountAmount.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: reliefColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
          ],
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
            description.isNotEmpty
                ? description
                : (discount.discountName ?? ""),
            style: TextStyle(
              fontSize: 12.0,
              letterSpacing: 0.4,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final discounts = childFeeDetails.discountsForScope(compulsory: compulsory);
    if (discounts.isEmpty) {
      return const SizedBox();
    }

    final totalRelief = compulsory
        ? childFeeDetails.totalCompulsoryDiscountAmount()
        : childFeeDetails.totalOptionalDiscountAmount();
    final reliefColor = Theme.of(context).colorScheme.onSecondary;
    final currency = _currency(context);
    final showHeader = discounts.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          Utils.getTranslatedLabel(feeReliefKey),
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 8.0),
        // Bordered card
        FeeSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    Utils.getTranslatedLabel(totalReliefKey),
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "$currency${totalRelief.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.1,
                      color: reliefColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              const FeeCardDivider(),
              const SizedBox(height: 12.0),
              ...List.generate(discounts.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 0.0 : 12.0),
                  child: _reasonCard(context, discounts[index],
                      showHeader: showHeader),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
