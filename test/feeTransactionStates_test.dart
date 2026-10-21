import 'dart:convert';

import 'package:eschool/data/models/feeTransaction.dart';
import 'package:eschool/data/repositories/feeRepository.dart';
import 'package:flutter_test/flutter_test.dart';

/// The two rows the live endpoint returns, verbatim.
final _paidCash = {
  'id': 63,
  'type': 'compulsory',
  'fee_name': 'Full Payment',
  'amount': 8000,
  'due_charges': 0,
  'mode': 'Cash',
  'status': 'Success',
  'date': '26-08-2026',
  'payment_transaction_id': 57,
  'notes': null,
  'reason': null,
  'file': null,
  'receipt_url': null,
};

final _rejectedManual = {
  'id': 62,
  'type': 'compulsory',
  'fee_name': 'Full Payment',
  'amount': 8500,
  'due_charges': 500,
  'mode': 'Manual',
  'status': 'Failed',
  'date': '26-08-2026',
  'payment_transaction_id': 56,
  'notes': 'op in chat',
  'reason': 'reject admin',
  'file': {
    'id': 64,
    'file_name': 'Screenshot_20260826_134417.jpg',
    'file_url': 'https://example.test/manual_receipt/abc.jpg',
    'file_extension': 'jpg',
  },
  'receipt_url': 'https://example.test/manual_receipt/abc.jpg',
};

void main() {
  group('settled payment', () {
    test('is Paid, and carries the ids the receipt endpoint needs', () {
      final transaction = FeeTransaction.fromJson(_paidCash);

      expect(transaction.isSucceeded, isTrue);
      expect(transaction.isRejected, isFalse);
      expect(transaction.isPending, isFalse);
      //the receipt is not on the transaction — only what is needed to ask for
      //one, which is why it is fetched on demand
      expect(transaction.hasUploadedReceipt, isFalse);
      expect(transaction.type, 'compulsory');
      expect(transaction.paymentTransactionId, 57);
    });
  });

  group('rejected payment', () {
    test('is Rejected, with the school\'s reason and the uploaded receipt', () {
      final transaction = FeeTransaction.fromJson(_rejectedManual);

      expect(transaction.isRejected, isTrue);
      expect(transaction.isSucceeded, isFalse);
      expect(transaction.reason, 'reject admin');
      //the parent's own proof is on the transaction, so it needs no fetching
      expect(transaction.hasUploadedReceipt, isTrue);
      expect(transaction.receiptUrl, contains('manual_receipt'));
    });

    test('falls back to the file object when receipt_url is absent', () {
      final transaction = FeeTransaction.fromJson({
        ..._rejectedManual,
        'receipt_url': null,
      });

      expect(transaction.hasUploadedReceipt, isTrue);
      expect(
        transaction.receiptUrl,
        'https://example.test/manual_receipt/abc.jpg',
      );
    });
  });

  group('payment awaiting the school', () {
    test('is Under Review, and neither paid nor rejected', () {
      final transaction = FeeTransaction.fromJson({
        ..._rejectedManual,
        'status': 'Pending',
        'reason': null,
      });

      expect(transaction.isPending, isTrue);
      expect(transaction.isRejected, isFalse);
      expect(transaction.isSucceeded, isFalse);
    });
  });

  group('receipt availability', () {
    test('a transaction with no payment behind it cannot be fetched', () {
      //the download needs a payment_transaction_id; without one there is
      //nothing to ask the endpoint for
      final transaction = FeeTransaction.fromJson({
        ..._paidCash,
        'payment_transaction_id': null,
      });

      expect(transaction.isSucceeded, isTrue);
      expect(transaction.paymentTransactionId, isNull);
    });

    test('a blank receipt url does not count as an uploaded receipt', () {
      for (final blank in [null, '', '   ']) {
        final transaction = FeeTransaction.fromJson({
          ..._rejectedManual,
          'receipt_url': blank,
          'file': null,
        });

        expect(transaction.hasUploadedReceipt, isFalse);
      }
    });
  });

  group('FeeRepository.parseTransactionReceiptContent', () {
    test('reads the base64 pdf the endpoint returns', () {
      //the envelope verbatim: `pdf` sits at the top level, not under `data`,
      //and holds the pdf itself rather than a link to one
      final content = FeeRepository.parseTransactionReceiptContent({
        'error': false,
        'pdf': 'JVBERi0xLjcK',
      });

      expect(content, 'JVBERi0xLjcK');
      //decodes to a real pdf, so what gets written out actually opens
      expect(utf8.decode(base64Decode(content)), startsWith('%PDF-'));
    });

    test('reports nothing rather than writing a file that opens to nothing',
        () {
      expect(FeeRepository.parseTransactionReceiptContent({'pdf': ''}), '');
      expect(FeeRepository.parseTransactionReceiptContent({'pdf': '   '}), '');
      expect(FeeRepository.parseTransactionReceiptContent({'pdf': null}), '');
      expect(
          FeeRepository.parseTransactionReceiptContent({'error': false}), '');
      expect(FeeRepository.parseTransactionReceiptContent(null), '');
    });
  });
}
