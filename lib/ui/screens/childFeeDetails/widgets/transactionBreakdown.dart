import 'package:eschool/data/models/feeTransaction.dart';
import 'package:eschool/ui/screens/childFeeDetails/widgets/feeSectionCard.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';

/// One line of a payment's money: a fee and what it cost, a late fee, or the
/// total they add up to.
class TransactionAmountLine extends StatelessWidget {
  final String label;
  final String value;

  ///[The figure everything above adds up to]
  final bool isTotal;

  /// A late fee, set under the fee it was charged on rather than floating
  /// between two fees where it reads as belonging to neither.
  final bool isDueCharge;

  ///[A size down, for the history card — the sheet has room to breathe]
  final bool compact;

  const TransactionAmountLine({
    super.key,
    required this.label,
    required this.value,
    this.isTotal = false,
    this.isDueCharge = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = isTotal
        ? TextStyle(
            fontSize: compact ? 14.0 : 16.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
            color: Theme.of(context).colorScheme.secondary,
          )
        : TextStyle(
            fontSize: isDueCharge || compact ? 12.0 : 14.0,
            letterSpacing: 0.25,
            color: isDueCharge
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.onSurface,
          );
    final valueStyle = isTotal
        ? labelStyle
        : labelStyle.copyWith(
            fontWeight: isDueCharge ? FontWeight.w400 : FontWeight.w500,
            color: isDueCharge
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.secondary,
          );

    return Padding(
      padding: EdgeInsetsDirectional.only(start: isDueCharge ? 12.0 : 0.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: labelStyle,
            ),
          ),
          const SizedBox(width: 16.0),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}

/// What a payment came to, itemised: every fee it settled, every late fee under
/// the fee it was charged on, and the total.
///
/// Shared by the history card and the transaction sheet so the two cannot drift
/// apart — a parent checking one against the other has to find the same figures
/// stated the same way, and a card that showed only a line's total left ₹9,500
/// on screen with nothing saying where the extra ₹500 came from.
class TransactionBreakdown extends StatelessWidget {
  final FeeTransaction transaction;
  final String currencySymbol;

  ///[A size down and tighter, for the history card]
  final bool compact;

  const TransactionBreakdown({
    super.key,
    required this.transaction,
    required this.currencySymbol,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    String money(double value) => "$currencySymbol${value.toStringAsFixed(2)}";

    final lines = <Widget>[];

    void addFee({
      required String label,
      required double amount,
      required double dueCharges,
    }) {
      if (lines.isNotEmpty) {
        lines.add(SizedBox(height: compact ? 8.0 : 14.0));
      }
      lines.add(TransactionAmountLine(
        label: label,
        value: money(amount),
        compact: compact,
      ));
      if (dueCharges > 0.0) {
        lines.add(SizedBox(height: compact ? 4.0 : 6.0));
        lines.add(TransactionAmountLine(
          label: Utils.getTranslatedLabel(dueChargesKey),
          value: "+${money(dueCharges)}",
          isDueCharge: true,
          compact: compact,
        ));
      }
    }

    //A payment settling several fees at once — an overdue installment paid
    //together with the current one — names each of them.
    //
    //A payment settling one fee is already named in the heading above, so the
    //only thing left worth stating is the split between the fee and its late
    //fee. Where there is no late fee that is nothing at all: a line here would
    //be the same figure as the total directly beneath it.
    if (transaction.items.length > 1) {
      for (final item in transaction.items) {
        addFee(
          label: item.displayName,
          amount: item.amount ?? 0.0,
          dueCharges: item.dueCharges ?? 0.0,
        );
      }
    } else {
      //the fee line where the payment has one, the payment itself on the older
      //one-row-per-fee shape
      final onlyFee =
          transaction.hasItems ? transaction.items.first : transaction;
      if (onlyFee.hasDueCharges) {
        addFee(
          label: Utils.getTranslatedLabel(amountKey),
          amount: onlyFee.amount ?? 0.0,
          dueCharges: onlyFee.dueCharges ?? 0.0,
        );
      }
    }

    if (lines.isNotEmpty) {
      lines.add(SizedBox(height: compact ? 10.0 : 14.0));
      lines.add(const FeeCardDivider());
      lines.add(SizedBox(height: compact ? 10.0 : 14.0));
    }
    lines.add(TransactionAmountLine(
      label: Utils.getTranslatedLabel(totalPaidKey),
      value: money(transaction.totalAmountPaid),
      isTotal: true,
      compact: compact,
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines,
    );
  }
}
