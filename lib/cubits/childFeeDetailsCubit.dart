import 'package:eschool/data/models/childFeeDetails.dart';
import 'package:eschool/data/repositories/feeRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ChildFeeDetailsState {}

class ChildFeeDetailsInitial extends ChildFeeDetailsState {}

class ChildFeeDetailsFetchInProgress extends ChildFeeDetailsState {}

class ChildFeeDetailsFetchSuccess extends ChildFeeDetailsState {
  final List<ChildFeeDetails> fees;
  final int childId;
  final int? sessionYearId;

  ///[Paging position, so the list knows whether another page exists]
  final int currentPage;
  final int totalPage;
  final bool fetchMoreFeesInProgress;
  final bool moreFeesFetchError;

  ChildFeeDetailsFetchSuccess({
    required this.fees,
    required this.childId,
    required this.currentPage,
    required this.totalPage,
    required this.fetchMoreFeesInProgress,
    required this.moreFeesFetchError,
    this.sessionYearId,
  });

  ChildFeeDetailsFetchSuccess copyWith({
    List<ChildFeeDetails>? newFees,
    int? newCurrentPage,
    int? newTotalPage,
    bool? newFetchMoreFeesInProgress,
    bool? newMoreFeesFetchError,
  }) {
    return ChildFeeDetailsFetchSuccess(
      childId: childId,
      sessionYearId: sessionYearId,
      fees: newFees ?? fees,
      currentPage: newCurrentPage ?? currentPage,
      totalPage: newTotalPage ?? totalPage,
      fetchMoreFeesInProgress:
          newFetchMoreFeesInProgress ?? fetchMoreFeesInProgress,
      moreFeesFetchError: newMoreFeesFetchError ?? moreFeesFetchError,
    );
  }
}

class ChildFeeDetailsFetchFailure extends ChildFeeDetailsState {
  final String errorMessage;

  ChildFeeDetailsFetchFailure(this.errorMessage);
}

class ChildFeeDetailsCubit extends Cubit<ChildFeeDetailsState> {
  final FeeRepository _feeRepository;

  ChildFeeDetailsCubit(this._feeRepository) : super(ChildFeeDetailsInitial());

  void fetchChildFeeDetails({
    required int childId,
    int? sessionYearId,
  }) async {
    try {
      emit(ChildFeeDetailsFetchInProgress());

      final result = await _feeRepository.fetchChildFeeDetails(
        childId: childId,
        sessionYearId: sessionYearId,
      );

      emit(
        ChildFeeDetailsFetchSuccess(
          childId: childId,
          sessionYearId: sessionYearId,
          fees: result['fees'] as List<ChildFeeDetails>,
          currentPage: result['currentPage'] as int,
          totalPage: result['totalPage'] as int,
          fetchMoreFeesInProgress: false,
          moreFeesFetchError: false,
        ),
      );
    } catch (e) {
      emit(ChildFeeDetailsFetchFailure(e.toString()));
    }
  }

  ///[Whether a page beyond the one already loaded exists]
  bool hasMore() {
    if (state is ChildFeeDetailsFetchSuccess) {
      final successState = state as ChildFeeDetailsFetchSuccess;
      return successState.currentPage < successState.totalPage;
    }
    return false;
  }

  Future<void> fetchMoreChildFeeDetails() async {
    if (state is! ChildFeeDetailsFetchSuccess) {
      return;
    }

    final successState = state as ChildFeeDetailsFetchSuccess;

    //a second request for the same page would append the same fees twice
    if (successState.fetchMoreFeesInProgress || !hasMore()) {
      return;
    }

    try {
      emit(successState.copyWith(newFetchMoreFeesInProgress: true));

      final result = await _feeRepository.fetchChildFeeDetails(
        childId: successState.childId,
        sessionYearId: successState.sessionYearId,
        page: successState.currentPage + 1,
      );

      emit(
        successState.copyWith(
          newFees: [
            ...successState.fees,
            ...result['fees'] as List<ChildFeeDetails>,
          ],
          newCurrentPage: result['currentPage'] as int,
          newTotalPage: result['totalPage'] as int,
          newFetchMoreFeesInProgress: false,
          newMoreFeesFetchError: false,
        ),
      );
    } catch (e) {
      //the pages already loaded stay on screen; only the extra page failed
      emit(
        successState.copyWith(
          newFetchMoreFeesInProgress: false,
          newMoreFeesFetchError: true,
        ),
      );
    }
  }

  void refreshFees() {
    if (state is ChildFeeDetailsFetchSuccess) {
      final successState = state as ChildFeeDetailsFetchSuccess;
      fetchChildFeeDetails(
        childId: successState.childId,
        sessionYearId: successState.sessionYearId,
      );
    }
  }

  /// Re-reads the first page, leaving what is on screen in place while it runs
  /// — unlike [fetchChildFeeDetails], which replaces it with a spinner.
  /// Returns the error when it failed, null when it succeeded.
  ///
  /// [childId] and [sessionYearId] apply only when nothing is loaded yet. Once
  /// something is, the refresh re-reads *that* list with the values it was
  /// fetched with, so a pull cannot ask for a different year than the load did.
  Future<String?> refreshChildFeeDetails({
    required int childId,
    int? sessionYearId,
  }) async {
    //nothing on screen to preserve, so this is really a first load
    if (state is! ChildFeeDetailsFetchSuccess) {
      fetchChildFeeDetails(childId: childId, sessionYearId: sessionYearId);
      return null;
    }

    final successState = state as ChildFeeDetailsFetchSuccess;
    final loadedChildId = successState.childId;
    final loadedSessionYearId = successState.sessionYearId;

    try {
      final result = await _feeRepository.fetchChildFeeDetails(
        childId: loadedChildId,
        sessionYearId: loadedSessionYearId,
      );

      emit(
        ChildFeeDetailsFetchSuccess(
          childId: loadedChildId,
          sessionYearId: loadedSessionYearId,
          fees: result['fees'] as List<ChildFeeDetails>,
          currentPage: result['currentPage'] as int,
          totalPage: result['totalPage'] as int,
          fetchMoreFeesInProgress: false,
          moreFeesFetchError: false,
        ),
      );
      return null;
    } catch (e) {
      //the fees already loaded stay exactly as they were
      emit(successState.copyWith(newMoreFeesFetchError: false));
      return e.toString();
    }
  }

  /// Replaces one fee in the loaded list with a newer copy of itself.
  ///
  /// How the details screen's own re-read reaches the card behind it, without
  /// reloading the list or losing the parent's place in it.
  void updateFee(ChildFeeDetails fee) {
    if (state is! ChildFeeDetailsFetchSuccess || fee.id == null) {
      return;
    }

    final successState = state as ChildFeeDetailsFetchSuccess;
    final index = successState.fees.indexWhere((e) => e.id == fee.id);
    if (index == -1) {
      return;
    }

    final fees = List<ChildFeeDetails>.from(successState.fees);
    fees[index] = fee;
    emit(successState.copyWith(newFees: fees));
  }
}
