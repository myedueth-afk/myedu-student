import 'package:eschool/data/models/childFeeDetails.dart';
import 'package:eschool/ui/widgets/statusChip.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';

/// One fee on the fee list: what it is, and where it stands.
///
/// A payment the school has not confirmed yet is called out here rather than
/// left to the fee screen. Without it the list says only "Pending" — the same
/// thing it says for a fee nobody has touched — so a parent who paid by cheque
/// last week reads the list as though their money never arrived, and the only
/// way to find out otherwise is to open every fee in turn.
///
/// The chip sits where the fee screen puts its own status, so the two read as
/// the same thing seen from a distance and then close up. It says which side of
/// the fee the money belongs to when the status line is not already talking
/// about that side — see [ChildFeeDetails.paymentUnderReviewLabelKey].
class ChildFeeCard extends StatelessWidget {
  final ChildFeeDetails fee;
  final VoidCallback onTap;

  const ChildFeeCard({super.key, required this.fee, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final valueTextStyle = TextStyle(
      fontSize: 13.0,
      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.9),
    );
    final feePaymentStatusKey = fee.getFeePaymentStatus();
    final feePaymentStatusColor =
        Utils.getFeePaymentStatusColor(feePaymentStatusKey);
    final underReviewLabelKey = fee.paymentUnderReviewLabelKey();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12.5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) => Row(
                children: [
                  Expanded(
                    child: Text(
                      fee.name ?? "",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                  //money already sent that the school has still to confirm. The
                  //same blue the transaction sheet gives Under Review, and set
                  //apart from the amber status below it, because it is not a
                  //fourth fee status — it is news about a payment
                  if (underReviewLabelKey != null) ...[
                    const SizedBox(width: 8.0),
                    //the fee name is what yields to the chip, but only so far:
                    //a name ellipsized to nothing identifies no fee, and a
                    //translation longer than the card would otherwise push the
                    //chip off its edge
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth * 0.55,
                      ),
                      child: StatusChip(
                        label: Utils.getTranslatedLabel(underReviewLabelKey),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  "${Utils.getTranslatedLabel(classKey)} : ${fee.classDetails?.name ?? '-'}",
                  style: valueTextStyle,
                ),
                const Spacer(),
                Text(
                  fee.sessionYear?.name ?? "",
                  style: valueTextStyle,
                ),
              ],
            ),
            const SizedBox(height: 2.5),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Text(
                        "${Utils.getTranslatedLabel(statusKey)} : ",
                        style: valueTextStyle,
                      ),
                      Flexible(
                        child: Text(
                          Utils.getTranslatedLabel(feePaymentStatusKey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: valueTextStyle.copyWith(
                            color: feePaymentStatusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                //an installment fee has no single due date worth showing —
                //each installment carries its own
                if (feePaymentStatusKey != paidKey &&
                    !fee.isBeingPaidInInstallments())
                  Expanded(
                    flex: 3,
                    child: Text(
                      "${Utils.getTranslatedLabel(dueDateKey)} : ${fee.dueDate ?? ''}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: valueTextStyle,
                      textAlign: TextAlign.end,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
