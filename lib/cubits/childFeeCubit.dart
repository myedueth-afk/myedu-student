import 'package:eschool/data/models/childFeeDetails.dart';
import 'package:eschool/data/repositories/feeRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The one fee the fee details screen is showing, kept current — as opposed to
/// [ChildFeeDetailsCubit], which owns the *list*.
///
/// Always holds a fee, seeded with the copy the list handed over, so the screen
/// draws at once and a failed refresh leaves the last good data on it.
class ChildFeeState {
  final ChildFeeDetails fee;

  ///[True while a re-read is in flight]
  final bool refreshInProgress;

  ///[Set when the last refresh failed, cleared when one succeeds]
  final String? refreshError;

  const ChildFeeState({
    required this.fee,
    this.refreshInProgress = false,
    this.refreshError,
  });

  ChildFeeState copyWith({
    ChildFeeDetails? fee,
    bool? refreshInProgress,
    //passing nothing clears it, so a success wipes the previous failure
    String? refreshError,
  }) {
    return ChildFeeState(
      fee: fee ?? this.fee,
      refreshInProgress: refreshInProgress ?? this.refreshInProgress,
      refreshError: refreshError,
    );
  }
}

class ChildFeeCubit extends Cubit<ChildFeeState> {
  final FeeRepository _feeRepository;
  final int childId;

  ChildFeeCubit(
    this._feeRepository, {
    required ChildFeeDetails fee,
    required this.childId,
  }) : super(ChildFeeState(fee: fee));

  /// Re-reads this fee, keeping the current one on screen throughout — so the
  /// same call serves both the read on opening and the parent's pull.
  ///
  /// Overlapping calls are dropped: the two can land within a frame of each
  /// other and fire the same request twice.
  Future<void> refresh() async {
    if (state.refreshInProgress) {
      return;
    }

    emit(state.copyWith(refreshInProgress: true));

    try {
      final fee = await _feeRepository.fetchChildFee(
        childId: childId,
        feeId: state.fee.id ?? 0,
        //fees are listed per session year, so this one is found in its own
        sessionYearId: state.fee.sessionYearId,
      );

      emit(
        ChildFeeState(
          //a fee no longer in the list leaves the copy on screen, not a blank
          fee: fee ?? state.fee,
          refreshInProgress: false,
        ),
      );
    } catch (e) {
      emit(
        ChildFeeState(
          fee: state.fee,
          refreshInProgress: false,
          refreshError: e.toString(),
        ),
      );
    }
  }
}
