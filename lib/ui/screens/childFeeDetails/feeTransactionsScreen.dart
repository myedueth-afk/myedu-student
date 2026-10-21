import 'package:eschool/cubits/feeTransactionsCubit.dart';
import 'package:eschool/cubits/schoolConfigurationCubit.dart';
import 'package:eschool/data/models/feeTransaction.dart';
import 'package:eschool/data/repositories/feeRepository.dart';
import 'package:eschool/ui/screens/childFeeDetails/widgets/feeSectionCard.dart';
import 'package:eschool/ui/screens/childFeeDetails/widgets/transactionBreakdown.dart';
import 'package:eschool/ui/screens/childFeeDetails/widgets/transactionDetailsBottomsheet.dart';
import 'package:eschool/ui/styles/colors.dart';
import 'package:eschool/ui/widgets/customAppbar.dart';
import 'package:eschool/ui/widgets/customCircularProgressIndicator.dart';
import 'package:eschool/ui/widgets/customRefreshIndicator.dart';
import 'package:eschool/ui/widgets/errorContainer.dart';
import 'package:eschool/ui/widgets/noDataContainer.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

/// Every payment recorded against a child's fees, newest first.
///
/// This is where a parent goes to find out what happened to a manual payment:
/// the fee screen only says one is pending, this says whether the school has
/// since approved or rejected it.
class FeeTransactionsScreen extends StatefulWidget {
  final int childId;

  /// Scopes the history to a single fee. Left null, it shows every payment
  /// across every fee.
  final int? feesId;

  const FeeTransactionsScreen({
    Key? key,
    required this.childId,
    this.feesId,
  }) : super(key: key);

  static Widget routeInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;

    return BlocProvider<FeeTransactionsCubit>(
      create: (_) => FeeTransactionsCubit(FeeRepository()),
      child: FeeTransactionsScreen(
        childId: arguments['childId'] as int,
        feesId: arguments['feesId'] as int?,
      ),
    );
  }

  @override
  State<FeeTransactionsScreen> createState() => _FeeTransactionsScreenState();
}

class _FeeTransactionsScreenState extends State<FeeTransactionsScreen> {
  late final ScrollController _scrollController = ScrollController()
    ..addListener(_transactionsScrollListener);

  ///[Pulls the next page in once the list has been scrolled to its end]
  void _transactionsScrollListener() {
    if (_scrollController.offset ==
        _scrollController.position.maxScrollExtent) {
      context.read<FeeTransactionsCubit>().fetchMoreFeeTransactions();
    }
  }

  @override
  void initState() {
    super.initState();
    //asked for as the screen is built, not a turn of the event loop later
    context.read<FeeTransactionsCubit>().fetchFeeTransactions(
          childId: widget.childId,
          feesId: widget.feesId,
        );
  }

  /// Re-reads the history without taking the payments on screen away.
  ///
  /// Awaited by the refresh indicator, so its spinner runs for as long as the
  /// request does. A failure is reported and the loaded payments left alone.
  Future<void> _refreshTransactions() async {
    final error =
        await context.read<FeeTransactionsCubit>().refreshFeeTransactions(
              childId: widget.childId,
              feesId: widget.feesId,
            );

    if (error == null || !mounted) {
      return;
    }

    Utils.showCustomSnackBar(
      context: context,
      errorMessage: Utils.getErrorMessageFromErrorCode(context, error),
      backgroundColor: Theme.of(context).colorScheme.error,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_transactionsScrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  String get _currencySymbol =>
      context
          .read<SchoolConfigurationCubit>()
          .getSchoolConfiguration()
          .schoolSettings
          .currencySymbol ??
      '';

  /// The status chip, in the school's language rather than the API's.
  ///
  /// "Pending" is shown as Under Review: to a parent it is not their payment
  /// that is pending, it is the school's verification of it.
  ({String labelKey, Color color}) _statusOf(FeeTransaction transaction) {
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

  ///[How the money was sent, as a parent would name it]
  String _modeLabel(FeeTransaction transaction) {
    switch ((transaction.mode ?? '').toLowerCase()) {
      case 'manual':
        return Utils.getTranslatedLabel(manualPaymentKey);
      case 'online':
        return Utils.getTranslatedLabel(onlinePaymentKey);
      case 'cash':
        return Utils.getTranslatedLabel(cashKey);
      default:
        return transaction.mode ?? '';
    }
  }

  Widget _buildStatusChip(FeeTransaction transaction) {
    final status = _statusOf(transaction);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        Utils.getTranslatedLabel(status.labelKey),
        style: TextStyle(
          fontSize: 12.0,
          letterSpacing: 0.4,
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
      ),
    );
  }

  Widget _buildTransactionCard(FeeTransaction transaction) {
    return GestureDetector(
      //the card is a summary; what became of the payment, and what can be done
      //about it, lives in the sheet
      onTap: () => Utils.showBottomSheet(
        child: TransactionDetailsBottomsheet.routeInstance(transaction),
        context: context,
      ),
      behavior: HitTestBehavior.opaque,
      child: _buildTransactionCardContent(transaction),
    );
  }

  Widget _buildTransactionCardContent(FeeTransaction transaction) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: onlineClassCardColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      transaction.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    //how and when, together, so the amounts below are the only
                    //figures on the card
                    Text(
                      [_modeLabel(transaction), transaction.date ?? '']
                          .where((part) => part.trim().isNotEmpty)
                          .join('  •  '),
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
              _buildStatusChip(transaction),
            ],
          ),
          const SizedBox(height: 12.0),
          const FeeCardDivider(),
          const SizedBox(height: 12.0),
          //every fee the payment settled, every late fee under the fee it was
          //charged on, and the total — the same statement the sheet makes, so
          //the card explains its own total instead of leaving a line at ₹9,500
          //with nothing saying where the extra ₹500 came from
          TransactionBreakdown(
            transaction: transaction,
            currencySymbol: _currencySymbol,
            compact: true,
          ),
          //the school's reason for turning a manual payment down is the whole
          //point of coming back to this screen, so it is never hidden
          if (transaction.isRejected &&
              transaction.rejectionReason != null) ...[
            const SizedBox(height: 12.0),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: errorContainerColor,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                transaction.rejectionReason!,
                style: TextStyle(
                  fontSize: 12.0,
                  letterSpacing: 0.4,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Foot of the list while the next page loads, or a retry when it failed.
  Widget _buildMoreIndicator({required bool failed}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Center(
        child: failed
            ? GestureDetector(
                onTap: () => context
                    .read<FeeTransactionsCubit>()
                    .fetchMoreFeeTransactions(),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    Utils.getTranslatedLabel(retryKey),
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              )
            : CustomCircularProgressIndicator(
                indicatorColor: Theme.of(context).colorScheme.primary,
              ),
      ),
    );
  }

  ///[Clears the app bar, which is stacked over the scroll view]
  double get _scrollViewTopPadding => Utils.getScrollViewTopPadding(
        context: context,
        appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
      );

  /// Makes a screen with no list of its own — "no transactions found", and the
  /// error page — pullable. An empty history is the one most worth re-checking.
  Widget _buildRefreshableMessage(Widget child) {
    return CustomRefreshIndicator(
      displacment: _scrollViewTopPadding,
      onRefreshCallback: _refreshTransactions,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  Widget _buildList(FeeTransactionsFetchSuccess state) {
    if (state.transactions.isEmpty) {
      return _buildRefreshableMessage(
        NoDataContainer(titleKey: noFeeTransactionsFoundKey),
      );
    }

    final showMoreIndicator = state.fetchMoreTransactionsInProgress ||
        state.moreTransactionsFetchError;

    return CustomRefreshIndicator(
      displacment: _scrollViewTopPadding,
      onRefreshCallback: _refreshTransactions,
      child: ListView.builder(
        controller: _scrollController,
        //a single payment does not fill the screen, leaving nothing to pull on
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: 24.0,
          left: Utils.screenContentHorizontalPadding,
          right: Utils.screenContentHorizontalPadding,
          top: _scrollViewTopPadding,
        ),
        itemCount: state.transactions.length + (showMoreIndicator ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.transactions.length) {
            return _buildMoreIndicator(
                failed: state.moreTransactionsFetchError);
          }
          return _buildTransactionCard(state.transactions[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          BlocBuilder<FeeTransactionsCubit, FeeTransactionsState>(
            builder: (context, state) {
              if (state is FeeTransactionsFetchSuccess) {
                return _buildList(state);
              }
              if (state is FeeTransactionsFetchFailure) {
                return _buildRefreshableMessage(
                  ErrorContainer(
                    errorMessageCode: state.errorMessage,
                    onTapRetry: () => context
                        .read<FeeTransactionsCubit>()
                        .fetchFeeTransactions(
                          childId: widget.childId,
                          feesId: widget.feesId,
                        ),
                  ),
                );
              }
              return Center(
                child: CustomCircularProgressIndicator(
                  indicatorColor: Theme.of(context).colorScheme.primary,
                ),
              );
            },
          ),
          Align(
            alignment: Alignment.topCenter,
            child: CustomAppBar(
              title: Utils.getTranslatedLabel(transactionHistoryKey),
            ),
          ),
        ],
      ),
    );
  }
}
