import 'package:eschool/data/models/childFeeDetails.dart';
import 'package:eschool/data/models/feeTransaction.dart';
import 'package:eschool/data/repositories/feeRepository.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:flutter_test/flutter_test.dart';

/// A `fees_paid` row shaped the way the backend records a payment.
Map<String, dynamic> _paidFee({
  required String mode,
  required String status,
  required double amount,
  required double feesPaidAmount,
  int isFullyPaid = 0,
  String? reason,
}) {
  return {
    'id': 34,
    'is_fully_paid': isFullyPaid,
    'is_used_installment': 0,
    'amount': feesPaidAmount,
    'compulsory_fee': [
      {
        'id': 61,
        'type': 'Full Payment',
        'mode': mode,
        'amount': amount,
        'status': status,
        'due_charges': 500,
        'reason': reason,
      }
    ],
    'optional_fee': [],
  };
}

void main() {
  group('ChildFeeDetails.hasPendingManualPayment', () {
    test('spots the manual receipt the school has not approved yet', () {
      //exactly what the endpoint returns after a manual payment is filed: a
      //fees_paid row of 0, and a Manual/Pending payment of the full amount
      final fee = ChildFeeDetails.fromJson({
        'id': 24,
        'fees_paid': [
          _paidFee(
            mode: 'Manual',
            status: 'Pending',
            amount: 8500,
            feesPaidAmount: 0,
          ),
        ],
      });

      expect(fee.hasPendingPayment(compulsory: true), isTrue);
    });

    test('a settled online payment is not pending', () {
      final fee = ChildFeeDetails.fromJson({
        'id': 23,
        'fees_paid': [
          _paidFee(
            mode: 'Online',
            status: 'Success',
            amount: 3000,
            feesPaidAmount: 26000,
            isFullyPaid: 1,
          ),
        ],
      });

      expect(fee.hasPendingPayment(compulsory: true), isFalse);
    });

    test('an approved manual payment is not pending either', () {
      final fee = ChildFeeDetails.fromJson({
        'id': 24,
        'fees_paid': [
          _paidFee(
            mode: 'Manual',
            status: 'Success',
            amount: 8500,
            feesPaidAmount: 8500,
            isFullyPaid: 1,
          ),
        ],
      });

      expect(fee.hasPendingPayment(compulsory: true), isFalse);
    });

    test('a receipt the school turned down is no longer pending', () {
      //rejection arrives as Failed, not Rejected — the parent can pay again
      final fee = ChildFeeDetails.fromJson({
        'id': 24,
        'fees_paid': [
          _paidFee(
            mode: 'Manual',
            status: 'Failed',
            amount: 8500,
            feesPaidAmount: 0,
            reason: 'you have not money',
          ),
        ],
      });

      expect(fee.hasPendingPayment(compulsory: true), isFalse);
    });

    test('a fee with nothing paid at all is not pending manual', () {
      final fee = ChildFeeDetails.fromJson({'id': 24, 'fees_paid': []});

      expect(fee.hasPendingPayment(compulsory: true), isFalse);
    });
  });

  group('ChildFeeDetails.getFeePaymentStatus', () {
    test('reads as Pending, not Partially Paid, while a receipt is unapproved',
        () {
      //the fees_paid row exists but books nothing, so calling it partially paid
      //would tell the parent money had landed when it has not
      final fee = ChildFeeDetails.fromJson({
        'id': 24,
        'fees_paid': [
          _paidFee(
            mode: 'Manual',
            status: 'Pending',
            amount: 8500,
            feesPaidAmount: 0,
          ),
        ],
      });

      expect(fee.getFeePaymentStatus(), pendingKey);
    });

    test('stays Pending after the school rejects the receipt', () {
      //the reported bug: a rejected manual payment leaves a fees_paid row of 0
      //behind, which used to read as Partially Paid — telling the parent money
      //had landed when the school had just refused it
      final fee = ChildFeeDetails.fromJson({
        'id': 24,
        'fees_paid': [
          _paidFee(
            mode: 'Manual',
            status: 'Failed',
            amount: 8500,
            feesPaidAmount: 0,
            reason: 'you have not money',
          ),
        ],
      });

      expect(fee.getFeePaymentStatus(), pendingKey);
    });

    test('a fee cleared entirely by a discount still reads as Paid', () {
      //books nothing either, but is genuinely settled — the zero amount rule
      //must not swallow this case
      final fee = ChildFeeDetails.fromJson({
        'id': 21,
        'fees_paid': [
          _paidFee(
            mode: 'Online',
            status: 'Success',
            amount: 0,
            feesPaidAmount: 0,
            isFullyPaid: 1,
          ),
        ],
      });

      expect(fee.getFeePaymentStatus(), paidKey);
    });

    test('still reports a genuinely part paid fee as partially paid', () {
      final fee = ChildFeeDetails.fromJson({
        'id': 22,
        'fees_paid': [
          _paidFee(
            mode: 'Online',
            status: 'Success',
            amount: 4250,
            feesPaidAmount: 4250,
          ),
        ],
      });

      expect(fee.getFeePaymentStatus(), partiallyPaidKey);
    });

    test('still reports a fully paid fee as paid', () {
      final fee = ChildFeeDetails.fromJson({
        'id': 23,
        'fees_paid': [
          _paidFee(
            mode: 'Online',
            status: 'Success',
            amount: 26000,
            feesPaidAmount: 26000,
            isFullyPaid: 1,
          ),
        ],
      });

      expect(fee.getFeePaymentStatus(), paidKey);
    });
  });

  group('FeeTransaction', () {
    test('reads the row the transaction history endpoint returns', () {
      final transaction = FeeTransaction.fromJson({
        'id': 61,
        'type': 'compulsory',
        'fee_name': 'Full Payment',
        'amount': 8500,
        'due_charges': 500,
        'mode': 'Manual',
        'status': 'Pending',
        'date': '26-08-2026',
        'payment_transaction_id': null,
        'notes': null,
        'reason': null,
      });

      expect(transaction.feeName, 'Full Payment');
      expect(transaction.amount, 8500);
      expect(transaction.isManual, isTrue);
      expect(transaction.isPending, isTrue);
      expect(transaction.isSucceeded, isFalse);
      expect(transaction.isRejected, isFalse);
    });

    test('reads the backend\'s Failed as a rejection', () {
      final transaction = FeeTransaction.fromJson({
        'id': 61,
        'fee_name': 'Full Payment',
        'mode': 'Manual',
        'status': 'Failed',
        'reason': 'you have not money',
      });

      expect(transaction.isRejected, isTrue);
      expect(transaction.isPending, isFalse);
      expect(transaction.isSucceeded, isFalse);
      expect(transaction.reason, 'you have not money');
    });

    test('matches status regardless of how the backend cases it', () {
      //the fee endpoints capitalise status, the payment transaction endpoints
      //do not — the app must not care which one it is reading
      expect(FeeTransaction.fromJson({'status': 'pending'}).isPending, isTrue);
      expect(FeeTransaction.fromJson({'status': 'Pending'}).isPending, isTrue);
      expect(
          FeeTransaction.fromJson({'status': 'SUCCESS'}).isSucceeded, isTrue);
      expect(FeeTransaction.fromJson({'mode': 'MANUAL'}).isManual, isTrue);
      expect(FeeTransaction.fromJson({'status': 'failed'}).isRejected, isTrue);
    });
  });

  group('FeeRepository.parseFeeTransactionsPage', () {
    test('reads the paginator the endpoint returns', () {
      final result = FeeRepository.parseFeeTransactionsPage({
        'current_page': 1,
        'last_page': 3,
        'per_page': 15,
        'total': 38,
        'data': [
          {'id': 61, 'fee_name': 'Full Payment', 'mode': 'Manual'},
          {'id': 60, 'fee_name': 'Installment 4', 'mode': 'Online'},
        ],
      });

      expect((result['transactions'] as List<FeeTransaction>).length, 2);
      expect(result['currentPage'], 1);
      expect(result['totalPage'], 3);
    });

    test('still reads a bare list', () {
      final result = FeeRepository.parseFeeTransactionsPage([
        {'id': 61, 'fee_name': 'Full Payment'},
      ]);

      expect((result['transactions'] as List<FeeTransaction>).length, 1);
      expect(result['totalPage'], 1);
    });
  });
}
