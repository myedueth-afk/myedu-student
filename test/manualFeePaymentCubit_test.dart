import 'dart:convert';

import 'package:eschool/cubits/manualFeePaymentCubit.dart';
import 'package:eschool/data/models/manualFeePaymentArguments.dart';
import 'package:eschool/data/repositories/feeRepository.dart';
import 'package:eschool/utils/api.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records which endpoint the cubit chose and what it sent, without going near
/// the network.
class _RecordingFeeRepository extends FeeRepository {
  final List<String> calls = [];
  Map<String, dynamic>? lastArgs;
  Object? errorToThrow;

  @override
  Future<void> payCompulsoryFeeManually({
    required int childId,
    required int feeId,
    required String receiptFilePath,
    List<int>? installmentIds,
    double? advanceAmount,
    String? notes,
  }) async {
    calls.add('compulsory');
    lastArgs = {
      'child_id': childId,
      'fees_id': feeId,
      'receipt': receiptFilePath,
      'installment_ids': installmentIds,
      'advance': advanceAmount,
      'notes': notes,
    };
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
  }

  @override
  Future<void> payOptionalFeesManually({
    required int childId,
    required int feeId,
    required List<int> optionalFeeIds,
    required String receiptFilePath,
    String? notes,
  }) async {
    calls.add('optional');
    lastArgs = {
      'child_id': childId,
      'fees_id': feeId,
      'optional_id': optionalFeeIds,
      'receipt': receiptFilePath,
      'notes': notes,
    };
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
  }
}

void main() {
  group('ManualFeePaymentCubit', () {
    late _RecordingFeeRepository repository;
    late ManualFeePaymentCubit cubit;

    setUp(() {
      repository = _RecordingFeeRepository();
      cubit = ManualFeePaymentCubit(repository);
    });

    test(
        'sends a compulsory fee to the compulsory endpoint, carrying the '
        'installments and advance the fee screen resolved', () async {
      await cubit.submitManualFeePayment(
        arguments: const ManualFeePaymentArguments(
          childId: 46,
          feeId: 7,
          compulsoryFee: true,
          payableAmount: 8500,
          installmentIds: [11, 12],
          advanceAmount: 500,
        ),
        receiptFilePath: '/tmp/receipt.png',
      );

      expect(repository.calls, ['compulsory']);
      expect(repository.lastArgs, {
        'child_id': 46,
        'fees_id': 7,
        'receipt': '/tmp/receipt.png',
        'installment_ids': [11, 12],
        'advance': 500.0,
        'notes': null,
      });
      expect(cubit.state, isA<ManualFeePaymentSuccess>());
    });

    test('sends optional fees to the optional endpoint with the selected ids',
        () async {
      await cubit.submitManualFeePayment(
        arguments: const ManualFeePaymentArguments(
          childId: 46,
          feeId: 7,
          compulsoryFee: false,
          payableAmount: 1200,
          optionalFeeIds: [3, 4],
        ),
        receiptFilePath: '/tmp/receipt.pdf',
        notes: 'UTR 12345',
      );

      expect(repository.calls, ['optional']);
      expect(repository.lastArgs, {
        'child_id': 46,
        'fees_id': 7,
        'optional_id': [3, 4],
        'receipt': '/tmp/receipt.pdf',
        'notes': 'UTR 12345',
      });
      expect(cubit.state, isA<ManualFeePaymentSuccess>());
    });

    test('trims the note before sending it', () async {
      await cubit.submitManualFeePayment(
        arguments: const ManualFeePaymentArguments(
          childId: 46,
          feeId: 7,
          compulsoryFee: true,
          payableAmount: 8500,
        ),
        receiptFilePath: '/tmp/receipt.png',
        notes: '   UTR 998877   ',
      );

      expect(repository.lastArgs!['notes'], 'UTR 998877');
    });

    test('sends no note at all when the field was left alone', () async {
      for (final untouched in [null, '', '   ', '\n ']) {
        repository = _RecordingFeeRepository();
        cubit = ManualFeePaymentCubit(repository);

        await cubit.submitManualFeePayment(
          arguments: const ManualFeePaymentArguments(
            childId: 46,
            feeId: 7,
            compulsoryFee: true,
            payableAmount: 8500,
          ),
          receiptFilePath: '/tmp/receipt.png',
          notes: untouched,
        );

        //an empty string is not a note — the endpoint should never receive one
        expect(
          repository.lastArgs!['notes'],
          isNull,
          reason: 'note ${jsonEncode(untouched)} should not be sent',
        );
      }
    });

    test('carries the note on an optional fee payment too', () async {
      await cubit.submitManualFeePayment(
        arguments: const ManualFeePaymentArguments(
          childId: 46,
          feeId: 7,
          compulsoryFee: false,
          payableAmount: 1200,
          optionalFeeIds: [3],
        ),
        receiptFilePath: '/tmp/receipt.pdf',
        notes: ' paid by UPI ',
      );

      expect(repository.calls, ['optional']);
      expect(repository.lastArgs!['notes'], 'paid by UPI');
    });

    test('never sends an optional payment down the compulsory endpoint',
        () async {
      await cubit.submitManualFeePayment(
        arguments: const ManualFeePaymentArguments(
          childId: 1,
          feeId: 1,
          compulsoryFee: false,
          payableAmount: 10,
          optionalFeeIds: [9],
        ),
        receiptFilePath: '/tmp/r.png',
      );

      expect(repository.calls, isNot(contains('compulsory')));
    });

    test('reports the backend message so a rejected receipt explains itself',
        () async {
      repository.errorToThrow =
          ApiException('The receipt must not be greater than 5120 kilobytes.');

      await cubit.submitManualFeePayment(
        arguments: const ManualFeePaymentArguments(
          childId: 46,
          feeId: 7,
          compulsoryFee: true,
          payableAmount: 8500,
        ),
        receiptFilePath: '/tmp/huge.png',
      );

      expect(cubit.state, isA<ManualFeePaymentFailure>());
      expect(
        (cubit.state as ManualFeePaymentFailure).errorMessage,
        contains('5120 kilobytes'),
      );
    });
  });
}
