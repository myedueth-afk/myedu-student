import 'package:eschool/data/models/paymentTransaction.dart';
import 'package:eschool/data/repositories/paymentRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class PaymentTransactionsState {}

class PaymentTransactionsInitial extends PaymentTransactionsState {}

class PaymentTransactionsFetchInProgress extends PaymentTransactionsState {}

class PaymentTransactionsFetchSuccess extends PaymentTransactionsState {
  final List<PaymentTransaction> paymentTransactions;

  ///[Paging position, so the list knows whether another page exists]
  final int currentPage;
  final int totalPage;
  final bool fetchMoreTransactionsInProgress;
  final bool moreTransactionsFetchError;

  PaymentTransactionsFetchSuccess({
    required this.paymentTransactions,
    required this.currentPage,
    required this.totalPage,
    required this.fetchMoreTransactionsInProgress,
    required this.moreTransactionsFetchError,
  });

  PaymentTransactionsFetchSuccess copyWith({
    List<PaymentTransaction>? newPaymentTransactions,
    int? newCurrentPage,
    int? newTotalPage,
    bool? newFetchMoreTransactionsInProgress,
    bool? newMoreTransactionsFetchError,
  }) {
    return PaymentTransactionsFetchSuccess(
      paymentTransactions: newPaymentTransactions ?? paymentTransactions,
      currentPage: newCurrentPage ?? currentPage,
      totalPage: newTotalPage ?? totalPage,
      fetchMoreTransactionsInProgress:
          newFetchMoreTransactionsInProgress ?? fetchMoreTransactionsInProgress,
      moreTransactionsFetchError:
          newMoreTransactionsFetchError ?? moreTransactionsFetchError,
    );
  }
}

class PaymentTransactionsFetchFailure extends PaymentTransactionsState {
  final String errorMessage;

  PaymentTransactionsFetchFailure(this.errorMessage);
}

class PaymentTransactionsCubit extends Cubit<PaymentTransactionsState> {
  final PaymentRepository _paymentRepository;

  PaymentTransactionsCubit(this._paymentRepository)
      : super(PaymentTransactionsInitial());

  void fetchPaymentTransactions() async {
    try {
      emit(PaymentTransactionsFetchInProgress());

      final result = await _paymentRepository.getTransactionsPage();

      emit(
        PaymentTransactionsFetchSuccess(
          paymentTransactions:
              result['transactions'] as List<PaymentTransaction>,
          currentPage: result['currentPage'] as int,
          totalPage: result['totalPage'] as int,
          fetchMoreTransactionsInProgress: false,
          moreTransactionsFetchError: false,
        ),
      );
    } catch (e) {
      emit(PaymentTransactionsFetchFailure(e.toString()));
    }
  }

  ///[Whether a page beyond the one already loaded exists]
  bool hasMore() {
    if (state is PaymentTransactionsFetchSuccess) {
      final successState = state as PaymentTransactionsFetchSuccess;
      return successState.currentPage < successState.totalPage;
    }
    return false;
  }

  Future<void> fetchMorePaymentTransactions() async {
    if (state is! PaymentTransactionsFetchSuccess) {
      return;
    }

    final successState = state as PaymentTransactionsFetchSuccess;

    //a second request for the same page would append the same transactions
    //twice
    if (successState.fetchMoreTransactionsInProgress || !hasMore()) {
      return;
    }

    try {
      emit(successState.copyWith(newFetchMoreTransactionsInProgress: true));

      final result = await _paymentRepository.getTransactionsPage(
        page: successState.currentPage + 1,
      );

      emit(
        successState.copyWith(
          newPaymentTransactions: [
            ...successState.paymentTransactions,
            ...result['transactions'] as List<PaymentTransaction>,
          ],
          newCurrentPage: result['currentPage'] as int,
          newTotalPage: result['totalPage'] as int,
          newFetchMoreTransactionsInProgress: false,
          newMoreTransactionsFetchError: false,
        ),
      );
    } catch (e) {
      //the pages already loaded stay on screen; only the extra page failed
      emit(
        successState.copyWith(
          newFetchMoreTransactionsInProgress: false,
          newMoreTransactionsFetchError: true,
        ),
      );
    }
  }
}
