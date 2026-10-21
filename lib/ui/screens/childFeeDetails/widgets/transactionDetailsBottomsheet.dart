import 'package:eschool/cubits/downloadFeeTransactionReceiptCubit.dart';
import 'package:eschool/cubits/schoolConfigurationCubit.dart';
import 'package:eschool/data/models/feeTransaction.dart';
import 'package:eschool/data/repositories/feeRepository.dart';
import 'package:eschool/ui/screens/childFeeDetails/widgets/feeSectionCard.dart';
import 'package:eschool/ui/screens/childFeeDetails/widgets/transactionBreakdown.dart';
import 'package:eschool/ui/styles/colors.dart';
import 'package:eschool/ui/widgets/customCircularProgressIndicator.dart';
import 'package:eschool/ui/widgets/customRoundedButton.dart';
import 'package:eschool/ui/widgets/networkImageHandler.dart';
import 'package:eschool/ui/widgets/statusChip.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_file/open_file.dart';

/// The method, date and cheque number under the heading — everything about the
/// payment that is not money.
const TextStyle _captionStyle = TextStyle(
  fontSize: 12.0,
  letterSpacing: 0.4,
  color: captionColor,
);

/// What became of one payment, and what the parent can do about it.
///
/// The three states differ in more than a colour:
///
/// * **Paid** — settled. The school's receipt is not on the transaction, only
///   the ids needed to ask for one, so it is downloaded on demand — and only
///   when those ids are there to ask with.
/// * **Rejected** — the school's reason, and the receipt the parent uploaded.
///   There is no school receipt to download for money that was never accepted.
/// * **Under review** — nothing to download and nothing to act on yet, so it
///   says so rather than offering a button that cannot work.
///
/// Whatever the parent uploaded is shown in all three: it is theirs, and on an
/// approved manual payment it is frequently the only receipt there is.
class TransactionDetailsBottomsheet extends StatelessWidget {
  final FeeTransaction transaction;

  const TransactionDetailsBottomsheet({super.key, required this.transaction});

  static Widget routeInstance(FeeTransaction transaction) {
    return BlocProvider<DownloadFeeTransactionReceiptCubit>(
      create: (_) => DownloadFeeTransactionReceiptCubit(FeeRepository()),
      child: TransactionDetailsBottomsheet(transaction: transaction),
    );
  }

  String _currencySymbol(BuildContext context) =>
      context
          .read<SchoolConfigurationCubit>()
          .getSchoolConfiguration()
          .schoolSettings
          .currencySymbol ??
      '';

  ///[The status chip, in the parent's language rather than the API's]
  ({String labelKey, Color color}) _status(BuildContext context) {
    if (transaction.isSucceeded) {
      return (labelKey: paidKey, color: transactionPaidColor);
    }
    if (transaction.isRejected) {
      return (labelKey: rejectedKey, color: transactionRejectedColor);
    }
    if (transaction.isPending) {
      return (
        labelKey: underReviewKey,
        color: Theme.of(context).colorScheme.primary
      );
    }
    return (labelKey: pendingKey, color: captionColor);
  }

  String _modeLabel() {
    switch ((transaction.mode ?? '').toLowerCase()) {
      case 'manual':
        return Utils.getTranslatedLabel(manualPaymentKey);
      case 'online':
        return Utils.getTranslatedLabel(onlinePaymentKey);
      case 'cash':
        return Utils.getTranslatedLabel(cashKey);
      case 'cheque':
        return Utils.getTranslatedLabel(chequeKey);
      default:
        //a mode the app has not been taught yet reads better as the backend's
        //own word than as a blank
        return transaction.mode ?? '';
    }
  }

  Widget _buildTitle(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 12.0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: secondaryStrokeColor)),
      ),
      child: Text(
        Utils.getTranslatedLabel(transactionDetailsKey),
        style: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  /// What was paid, how, and when.
  ///
  /// The method and the date are a caption rather than two labelled rows: they
  /// are the least of what is on the sheet, and given rows of their own they
  /// carried the same weight — and the same full width dividers — as the
  /// amounts, which are what the parent came to check.
  Widget _buildHeading(BuildContext context) {
    final status = _status(context);
    final chequeNo = transaction.chequeNumber;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                transaction.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.15,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            StatusChip(
              label: Utils.getTranslatedLabel(status.labelKey),
              color: status.color,
            ),
          ],
        ),
        const SizedBox(height: 6.0),
        //each part is its own Text rather than one joined string, so the method
        //stays the method — named in the parent's language, and findable as
        //such — rather than becoming half of a sentence
        Row(
          children: [
            Flexible(child: Text(_modeLabel(), style: _captionStyle)),
            if ((transaction.date ?? '').trim().isNotEmpty) ...[
              const Text('  •  ', style: _captionStyle),
              Flexible(child: Text(transaction.date!, style: _captionStyle)),
            ],
          ],
        ),
        //which cheque, for a parent chasing one — the one detail the caption
        //above cannot carry without running long
        if (chequeNo != null) ...[
          const SizedBox(height: 8.0),
          Row(
            children: [
              Text(Utils.getTranslatedLabel(chequeNoKey), style: _captionStyle),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  chequeNo,
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  ///[The school's reason for refusing the payment]
  Widget _buildReason(BuildContext context) {
    final reason = transaction.rejectionReason;
    if (!transaction.isRejected || reason == null) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
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
              reason,
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

  /// What the payment came to, itemised.
  ///
  /// Gathered into one card so the money reads as a single statement, and built
  /// by the same widget the history card uses so the two always agree.
  Widget _buildBreakdownCard(BuildContext context) {
    return FeeSectionCard(
      child: TransactionBreakdown(
        transaction: transaction,
        currencySymbol: _currencySymbol(context),
      ),
    );
  }

  /// The receipt the parent uploaded, shown whenever there is one.
  ///
  /// It is the parent's own proof, and it stays worth seeing whatever the
  /// school decided: refused, it is what they have to correct; approved, it is
  /// often the only receipt on the payment, since a manual payment can be
  /// settled without a payment transaction to fetch a school receipt against.
  Widget _buildUploadedReceipt(BuildContext context) {
    if (!transaction.hasUploadedReceipt) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Utils.getTranslatedLabel(submittedReceiptKey),
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 8.0),
          GestureDetector(
            //small on a sheet, so it opens full screen for a proper look
            onTap: () => Utils.showImagePreview(
              context: context,
              imageUrl: transaction.receiptUrl!,
            ),
            child: Container(
              height: 160.0,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                border: Border.all(color: feeCardBorderColor),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetworkImageHandler(
                    imageUrl: transaction.receiptUrl!,
                    fit: BoxFit.cover,
                  ),
                  //nothing else says the crop opens full screen, and a receipt
                  //is exactly the thing a parent wants to read rather than
                  //glance at
                  PositionedDirectional(
                    end: 8.0,
                    bottom: 8.0,
                    child: Container(
                      padding: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Icon(
                        Icons.zoom_out_map_rounded,
                        size: 16.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  ///[Sets the expectation that the school has not confirmed the money yet]
  Widget _buildUnderReviewNote(BuildContext context) {
    if (!transaction.isPending) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: warningContainerColor,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          Utils.getTranslatedLabel(
            Utils.pendingPaymentNoteLabelKey(transaction.mode),
          ),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            height: 16 / 12,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ),
    );
  }

  /// Download, offered only for a settled payment.
  ///
  /// The receipt is asked for here rather than with the list: it is one request
  /// per transaction, and most are never opened. What comes back is a base64
  /// pdf, written out and handed to the device's own viewer — the same steps
  /// the fee receipt takes.
  Widget _buildDownloadButton(BuildContext context) {
    final transactionId = transaction.paymentTransactionId;

    //the endpoint is asked by payment transaction id, and an approved manual
    //payment can arrive without one. Offering a download that can only ever
    //answer "not available" is worse than not offering it: what the parent has
    //in that case is their own submitted receipt, shown above.
    if (!transaction.isSucceeded || transactionId == null) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: BlocConsumer<DownloadFeeTransactionReceiptCubit,
          DownloadFeeTransactionReceiptState>(
        listener: (context, state) {
          if (state is DownloadFeeTransactionReceiptSuccess) {
            OpenFile.open(state.downloadedFilePath);
            return;
          }
          if (state is DownloadFeeTransactionReceiptFailure) {
            Utils.showCustomSnackBar(
              context: context,
              errorMessage: Utils.getErrorMessageFromErrorCode(
                context,
                state.errorMessage,
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            );
          }
        },
        builder: (context, state) {
          final inProgress = state is DownloadFeeTransactionReceiptInProgress;

          return CustomRoundedButton(
            height: 48.0,
            radius: 8.0,
            widthPercentage: (MediaQuery.of(context).size.width - 32.0) /
                MediaQuery.of(context).size.width,
            textSize: 16.0,
            fontWeight: FontWeight.w500,
            backgroundColor: Theme.of(context).colorScheme.primary,
            buttonTitle: Utils.getTranslatedLabel(downloadReceiptKey),
            showBorder: false,
            child: inProgress
                ? CustomCircularProgressIndicator(
                    widthAndHeight: 20,
                    strokeWidth: 2,
                  )
                : null,
            onTap: () {
              if (inProgress) {
                return;
              }

              context
                  .read<DownloadFeeTransactionReceiptCubit>()
                  .downloadReceipt(
                    //a payment row carries no `type` of its own, so this reads
                    //whichever field says which side of the fee it settled
                    type: transaction.receiptType,
                    transactionId: transactionId,
                  );
            },
          );
        },
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
              const SizedBox(height: 20.0),
              _buildHeading(context),
              const SizedBox(height: 16.0),
              _buildReason(context),
              _buildBreakdownCard(context),
              _buildUploadedReceipt(context),
              _buildUnderReviewNote(context),
              _buildDownloadButton(context),
            ],
          ),
        ),
      ),
    );
  }
}
