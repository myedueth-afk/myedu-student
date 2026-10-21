import 'package:eschool/cubits/schoolConfigurationCubit.dart';
import 'package:eschool/data/models/advanceFee.dart';
import 'package:eschool/data/models/childFeeDetails.dart';
import 'package:eschool/ui/screens/childFeeDetails/widgets/advanceInstallmentPaidAmountBottomsheet.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Installments extends StatelessWidget {
  final ChildFeeDetails childFeeDetails;
  const Installments({super.key, required this.childFeeDetails});

  TextStyle getPaidOnTextStyle({required BuildContext context}) {
    return TextStyle(
        fontSize: 12.0,
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.75));
  }

  TextStyle getPaymentInfoTitleStyle({required BuildContext context}) {
    return TextStyle(
        fontSize: 16.0, color: Theme.of(context).colorScheme.secondary);
  }

  String getCurrencySymbol({required BuildContext context}) {
    return context
            .read<SchoolConfigurationCubit>()
            .getSchoolConfiguration()
            .schoolSettings
            .currencySymbol ??
        '';
  }

  @override
  Widget build(BuildContext context) {
    final installments = childFeeDetails.installments ?? [];

    // Index of the last installment that will actually be rendered (non-zero
    // amount). Used to suppress the trailing divider on the last row.
    int lastVisibleIndex = -1;
    for (var i = 0; i < installments.length; i++) {
      if ((installments[i].installmentAmount ?? 0.0) != 0.0) {
        lastVisibleIndex = i;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Column(
        children: installments.asMap().entries.map((entry) {
          final index = entry.key;
          final installment = entry.value;

          ///[If no amount to pay in installment then show nothing in ui]
          if ((installment.installmentAmount ?? 0.0) == 0.0) {
            return const SizedBox();
          }
          final isLastVisible = index == lastVisibleIndex;
          final isThisCurrentInstallment = installment.isCurrent ?? false;
          final isThisPaidInstallment = installment.isPaid ?? false;
          // Money already sent for this installment that the school has still
          // to confirm. Not paid, but no longer due either — showing its due
          // date in red would tell the parent to pay it again.
          final isThisInstallmentUnderReview = !isThisPaidInstallment &&
              childFeeDetails.isInstallmentPending(
                  installmentId: installment.id ?? 0);

          // Set color based on whether installment is current OR paid
          Color installmentNameColor = isThisPaidInstallment
              ? Theme.of(context).colorScheme.primary
              : (isThisCurrentInstallment
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondary);

          List<AdvanceFee> advanceFees = childFeeDetails
              .installmentAdvancePaidAmount(installmentId: installment.id ?? 0);

          // Summed from the list already fetched above (same value as
          // childFeeDetails.installmentTotalAdvancePaidAmount, without repeating
          // the per-installment lookup).
          final double totalAdvancePaidAmount =
              advanceFees.fold(0.0, (sum, fee) => sum + (fee.amount ?? 0.0));

          // Gross amount for the breakdown "Amount" row: the full decided
          // amount for paid installments, the remaining amount for unpaid
          // ones. Advance and relief are itemised on their own rows below, so
          // they must NOT be pre-deducted here — otherwise the advance would
          // be counted twice and the rows would not add up to the headline.
          final double grossAmount = isThisPaidInstallment
              ? (installment.installmentAmount ?? 0.0)
              : installment.remainingAmount;

          // Headline: what this installment effectively costs after deducting
          // the advance already paid toward it and its relief (never negative).
          final netAfterDeductions = grossAmount -
              totalAdvancePaidAmount -
              (installment.discountAmount ?? 0.0);
          final netAmount = netAfterDeductions > 0.0 ? netAfterDeductions : 0.0;

          // The late fee, and the figure the breakdown rows add up to with it.
          // Added after the clamp above because relief never reduces a penalty,
          // matching the payment summary.
          final dueChargeAmount = installment.isInstallmentOverdue()
              ? (installment.dueChargeAmount ?? 0.0)
              : 0.0;
          final totalAmount = netAmount + dueChargeAmount;

          return Container(
            margin: EdgeInsets.only(bottom: isLastVisible ? 0 : 12),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isThisPaidInstallment
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3)
                      : Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.1),
                  width: isThisPaidInstallment ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top section: Status, Title, Date, Final Amount
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  installment.name ?? "",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.0,
                                      color: installmentNameColor),
                                ),
                                SizedBox(
                                  width: isThisPaidInstallment ||
                                          isThisInstallmentUnderReview
                                      ? 2.5
                                      : 0.0,
                                ),
                                if (isThisPaidInstallment)
                                  Icon(Icons.verified,
                                      size: 14.0,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary)
                                else if (isThisInstallmentUnderReview)
                                  //the same mark the optional fee rows use for
                                  //money the school has yet to confirm
                                  Icon(Icons.hourglass_top_rounded,
                                      size: 14.0,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (isThisPaidInstallment)
                              Text(
                                "${Utils.getTranslatedLabel(paidOnKey)} ${childFeeDetails.installmentPaidDate(installmentId: installment.id ?? 0)}",
                                style: getPaidOnTextStyle(context: context),
                              )
                            else if (isThisInstallmentUnderReview)
                              Text(
                                Utils.getTranslatedLabel(underReviewKey),
                                style: getPaidOnTextStyle(context: context)
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary),
                              )
                            else
                              Text(
                                "${Utils.getTranslatedLabel(dueDateKey)} : ${installment.formatDueDate ?? installment.dueDate ?? '-'}",
                                style: TextStyle(
                                    fontSize: 12.0,
                                    color: installment.isInstallmentOverdue()
                                        ? Theme.of(context).colorScheme.error
                                        : Theme.of(context)
                                            .colorScheme
                                            .secondary
                                            .withValues(alpha: 0.75)),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${getCurrencySymbol(context: context)}${netAmount.toStringAsFixed(2)}",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                                color: isThisPaidInstallment
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.secondary),
                          ),
                          if (installment.isInstallmentOverdue())
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                "${getCurrencySymbol(context: context)}${(installment.dueChargeAmount ?? 0.0).toStringAsFixed(2)}",
                                style: TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.error),
                              ),
                            )
                        ],
                      ),
                    ],
                  ),
                ),

                // Bottom section: Breakdown of amount (if applicable)
                if (installment.hasDiscount() ||
                    advanceFees.isNotEmpty ||
                    installment.isInstallmentOverdue()) ...[
                  Divider(
                      height: 1,
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.1)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.02),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      children: [
                        if (installment.hasDiscount() || advanceFees.isNotEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(Utils.getTranslatedLabel(amountKey),
                                  style: TextStyle(
                                      fontSize: 12.0,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary
                                          .withValues(alpha: 0.75))),
                              Text(
                                "${getCurrencySymbol(context: context)}${grossAmount.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        if (installment.hasDiscount()) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(Utils.getTranslatedLabel(feeRelief),
                                  style: TextStyle(
                                      fontSize: 12.0,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary)),
                              Text(
                                  "-${getCurrencySymbol(context: context)}${(installment.discountAmount ?? 0.0).toStringAsFixed(2)}",
                                  style: TextStyle(
                                      fontSize: 12.0,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary)),
                            ],
                          ),
                        ],
                        if (advanceFees.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                      Utils.getTranslatedLabel(
                                          advancePaidAmountKey),
                                      style: TextStyle(
                                          fontSize: 12.0,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary)),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      Utils.showBottomSheet(
                                          child:
                                              AdvanceInstallmentPaidAmountBottomsheet(
                                                  advanceFees: advanceFees),
                                          context: context);
                                    },
                                    child: Icon(CupertinoIcons.info,
                                        size: 14.0,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary),
                                  ),
                                ],
                              ),
                              Text(
                                  "-${getCurrencySymbol(context: context)}${(totalAdvancePaidAmount).toStringAsFixed(2)}",
                                  style: TextStyle(
                                      fontSize: 12.0,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary)),
                            ],
                          ),
                        ],
                        if (installment.isInstallmentOverdue()) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                    "${Utils.getTranslatedLabel(dueChargeIsKey)} ${installment.dueCharges?.toStringAsFixed(2) ?? '-'} ${Utils.getTranslatedLabel(ofDecidedInstallmentAmountKey)}",
                                    style: TextStyle(
                                        fontSize: 12.0,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary
                                            .withValues(alpha: 0.75))),
                              ),
                              const SizedBox(width: 8.0),
                              Text(
                                  "+${getCurrencySymbol(context: context)}${(installment.dueChargeAmount ?? 0.0).toStringAsFixed(2)}",
                                  style: TextStyle(
                                      fontSize: 12.0,
                                      color:
                                          Theme.of(context).colorScheme.error)),
                            ],
                          ),
                        ],
                        // The figure the rows above add up to. The headline
                        // leaves the late fee out — it is beside it in red —
                        // so without this the card states neither total.
                        const SizedBox(height: 6),
                        Divider(
                            height: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withValues(alpha: 0.1)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                Utils.getTranslatedLabel(isThisPaidInstallment
                                    ? totalPaidKey
                                    : payableAmountKey),
                                style: TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary)),
                            Text(
                                "${getCurrencySymbol(context: context)}${totalAmount.toStringAsFixed(2)}",
                                style: TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ]
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
