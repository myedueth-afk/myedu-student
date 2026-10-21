import 'dart:convert';
import 'dart:io';

import 'package:eschool/data/repositories/feeRepository.dart';
import 'package:eschool/utils/errorMessageKeysAndCodes.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

abstract class DownloadFeeTransactionReceiptState {}

class DownloadFeeTransactionReceiptInitial
    extends DownloadFeeTransactionReceiptState {}

class DownloadFeeTransactionReceiptInProgress
    extends DownloadFeeTransactionReceiptState {}

class DownloadFeeTransactionReceiptSuccess
    extends DownloadFeeTransactionReceiptState {
  final String downloadedFilePath;

  DownloadFeeTransactionReceiptSuccess({required this.downloadedFilePath});
}

class DownloadFeeTransactionReceiptFailure
    extends DownloadFeeTransactionReceiptState {
  final String errorMessage;

  DownloadFeeTransactionReceiptFailure(this.errorMessage);
}

/// Fetches the receipt for a settled payment and writes it to a file the
/// device can open.
///
/// Mirrors [DownloadFeeReceiptCubit] step for step — the endpoint returns the
/// pdf as base64 rather than a link, so it has to be written out before
/// anything can show it. The file is named after the transaction so a second
/// look at the same payment overwrites its own file rather than piling up
/// copies.
class DownloadFeeTransactionReceiptCubit
    extends Cubit<DownloadFeeTransactionReceiptState> {
  final FeeRepository _feeRepository;

  DownloadFeeTransactionReceiptCubit(this._feeRepository)
      : super(DownloadFeeTransactionReceiptInitial());

  Future<void> downloadReceipt({
    required String type,
    required int transactionId,
  }) async {
    try {
      emit(DownloadFeeTransactionReceiptInProgress());

      final receiptContent = await _feeRepository.getTransactionReceipt(
        type: type,
        transactionId: transactionId,
      );

      //an empty body is a receipt the backend could not produce; writing it
      //out would hand the parent a file that opens to nothing
      if (receiptContent.isEmpty) {
        emit(DownloadFeeTransactionReceiptFailure(receiptNotAvailableKey));
        return;
      }

      final path = (await getApplicationDocumentsDirectory()).path;
      final file = File("$path/Fees-Receipts/transaction-$transactionId.pdf");

      await file.create(recursive: true);
      await file.writeAsBytes(base64Decode(receiptContent));

      emit(
        DownloadFeeTransactionReceiptSuccess(downloadedFilePath: file.path),
      );
    } catch (e) {
      emit(
        DownloadFeeTransactionReceiptFailure(
          ErrorMessageKeysAndCode.defaultErrorMessageKey,
        ),
      );
    }
  }
}
