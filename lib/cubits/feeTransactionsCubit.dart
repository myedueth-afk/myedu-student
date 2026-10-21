import 'package:eschool/data/models/feeTransaction.dart';
import 'package:eschool/data/repositories/feeRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FeeTransactionsState {}

class FeeTransactionsInitial extends FeeTransactionsState {}

class FeeTransactionsFetchInProgress extends FeeTransactionsState {}

class FeeTransactionsFetchSuccess extends FeeTransactionsState {
  final List<FeeTransaction> transactions;
  final int childId;

  ///[The fee this history is scoped to, null when it spans every fee]
  final int? feesId;

  ///[Paging position, so the list knows whether another page exists]
  final int currentPage;
  final int totalPage;
  final bool fetchMoreTransactionsInProgress;
  final bool moreTransactionsFetchError;

  FeeTransactionsFetchSuccess({
    required this.transactions,
    required this.childId,
    required this.feesId,
    required this.currentPage,
    required this.totalPage,
    required this.fetchMoreTransactionsInProgress,
    required this.moreTransactionsFetchError,
  });

  FeeTransactionsFetchSuccess copyWith({
    List<FeeTransaction>? newTransactions,
    int? newCurrentPage,
    int? newTotalPage,
    bool? newFetchMoreTransactionsInProgress,
    bool? newMoreTransactionsFetchError,
  }) {
    return FeeTransactionsFetchSuccess(
      childId: childId,
      feesId: feesId,
      transactions: newTransactions ?? transactions,
      currentPage: newCurrentPage ?? currentPage,
      totalPage: newTotalPage ?? totalPage,
      fetchMoreTransactionsInProgress:
          newFetchMoreTransactionsInProgress ?? fetchMoreTransactionsInProgress,
      moreTransactionsFetchError:
          newMoreTransactionsFetchError ?? moreTransactionsFetchError,
    );
  }
}

class FeeTransactionsFetchFailure extends FeeTransactionsState {
  final String errorMessage;

  FeeTransactionsFetchFailure(this.errorMessage);
}

class FeeTransactionsCubit extends Cubit<FeeTransactionsState> {
  final FeeRepository _feeRepository;

  FeeTransactionsCubit(this._feeRepository) : super(FeeTransactionsInitial());

  void fetchFeeTransactions({required int childId, int? feesId}) async {
    try {
      emit(FeeTransactionsFetchInProgress());

      final result = await _feeRepository.getFeeTransactionsPage(
        childId: childId,
        feesId: feesId,
      );

      emit(
        FeeTransactionsFetchSuccess(
          childId: childId,
          feesId: feesId,
          transactions: result['transactions'] as List<FeeTransaction>,
          currentPage: result['currentPage'] as int,
          totalPage: result['totalPage'] as int,
          fetchMoreTransactionsInProgress: false,
          moreTransactionsFetchError: false,
        ),
      );
    } catch (e) {
      emit(FeeTransactionsFetchFailure(e.toString()));
    }
  }

  ///[Whether a page beyond the one already loaded exists]
  bool hasMore() {
    if (state is FeeTransactionsFetchSuccess) {
      final successState = state as FeeTransactionsFetchSuccess;
      return successState.currentPage < successState.totalPage;
    }
    return false;
  }

  Future<void> fetchMoreFeeTransactions() async {
    if (state is! FeeTransactionsFetchSuccess) {
      return;
    }

    final successState = state as FeeTransactionsFetchSuccess;

    //a second request for the same page would append the same rows twice
    if (successState.fetchMoreTransactionsInProgress || !hasMore()) {
      return;
    }

    try {
      emit(successState.copyWith(newFetchMoreTransactionsInProgress: true));

      final result = await _feeRepository.getFeeTransactionsPage(
        childId: successState.childId,
        //the next page has to stay inside the same fee, or it would pull in
        //payments belonging to other fees
        feesId: successState.feesId,
        page: successState.currentPage + 1,
      );

      emit(
        successState.copyWith(
          newTransactions: [
            ...successState.transactions,
            ...result['transactions'] as List<FeeTransaction>,
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

  /// Re-reads the first page, leaving the history on screen while it runs —
  /// unlike [fetchFeeTransactions], which replaces it with a spinner.
  /// Returns the error when it failed, null when it succeeded.
  ///
  /// [childId] and [feesId] apply only when nothing is loaded yet. Once
  /// something is, the refresh keeps the scope it was fetched under, so a pull
  /// cannot widen one fee's payments into every payment the child made.
  Future<String?> refreshFeeTransactions({
    required int childId,
    int? feesId,
  }) async {
    //nothing on screen to preserve, so this is really a first load
    if (state is! FeeTransactionsFetchSuccess) {
      fetchFeeTransactions(childId: childId, feesId: feesId);
      return null;
    }

    final successState = state as FeeTransactionsFetchSuccess;
    final loadedChildId = successState.childId;
    final loadedFeesId = successState.feesId;

    try {
      final result = await _feeRepository.getFeeTransactionsPage(
        childId: loadedChildId,
        feesId: loadedFeesId,
      );

      emit(
        FeeTransactionsFetchSuccess(
          childId: loadedChildId,
          feesId: loadedFeesId,
          transactions: result['transactions'] as List<FeeTransaction>,
          currentPage: result['currentPage'] as int,
          totalPage: result['totalPage'] as int,
          fetchMoreTransactionsInProgress: false,
          moreTransactionsFetchError: false,
        ),
      );
      return null;
    } catch (e) {
      //the payments already loaded stay exactly as they were
      emit(successState.copyWith(newMoreTransactionsFetchError: false));
      return e.toString();
    }
  }
}
