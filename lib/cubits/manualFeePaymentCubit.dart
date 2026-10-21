import 'package:equatable/equatable.dart';
import 'package:eschool/data/models/manualFeePaymentArguments.dart';
import 'package:eschool/data/repositories/feeRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ManualFeePaymentState extends Equatable {}

class ManualFeePaymentInitial extends ManualFeePaymentState {
  @override
  List<Object?> get props => [];
}

class ManualFeePaymentInProgress extends ManualFeePaymentState {
  @override
  List<Object?> get props => [];
}

class ManualFeePaymentSuccess extends ManualFeePaymentState {
  @override
  List<Object?> get props => [];
}

class ManualFeePaymentFailure extends ManualFeePaymentState {
  final String errorMessage;

  ManualFeePaymentFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

class ManualFeePaymentCubit extends Cubit<ManualFeePaymentState> {
  final FeeRepository _feeRepository;

  ManualFeePaymentCubit(this._feeRepository) : super(ManualFeePaymentInitial());

  /// Files a fee the parent has already paid the school directly.
  ///
  /// Compulsory and optional fees go to separate endpoints with different
  /// bodies, and [ManualFeePaymentArguments] already knows which of the two the
  /// fee screen raised — so the split is resolved here rather than leaving the
  /// screen to pick the right call.
  Future<void> submitManualFeePayment({
    required ManualFeePaymentArguments arguments,
    required String receiptFilePath,
    String? notes,
  }) async {
    emit(ManualFeePaymentInProgress());

    //an untouched or whitespace-only note is no note: normalised here so the
    //endpoint is never sent an empty string, and so the decision can be tested
    final trimmedNotes = (notes ?? '').trim();
    final notesToSend = trimmedNotes.isEmpty ? null : trimmedNotes;

    try {
      if (arguments.compulsoryFee) {
        await _feeRepository.payCompulsoryFeeManually(
          childId: arguments.childId,
          feeId: arguments.feeId,
          receiptFilePath: receiptFilePath,
          installmentIds: arguments.installmentIds,
          advanceAmount: arguments.advanceAmount,
          notes: notesToSend,
        );
      } else {
        await _feeRepository.payOptionalFeesManually(
          childId: arguments.childId,
          feeId: arguments.feeId,
          optionalFeeIds: arguments.optionalFeeIds,
          receiptFilePath: receiptFilePath,
          notes: notesToSend,
        );
      }
      emit(ManualFeePaymentSuccess());
    } catch (e) {
      emit(ManualFeePaymentFailure(e.toString()));
    }
  }
}
