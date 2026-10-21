import 'package:eschool/data/models/childFeeDetails.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:flutter_test/flutter_test.dart';

/// A `fees_paid` row holding manual payments, newest last.
Map<String, dynamic> _paidFeeWith(
  List<Map<String, dynamic>> payments, {
  List<Map<String, dynamic>> optional = const [],
}) =>
    {
      'id': 34,
      'is_fully_paid': 0,
      'amount': 0,
      'compulsory_fee': payments,
      'optional_fee': optional,
    };

Map<String, dynamic> _manual({
  required int id,
  required String status,
  String? reason,
}) =>
    {
      'id': id,
      'type': 'Full Payment',
      'mode': 'Manual',
      'amount': 8500,
      'status': status,
      'reason': reason,
    };

ChildFeeDetails _fee(List<Map<String, dynamic>> payments) =>
    ChildFeeDetails.fromJson({
      'id': 24,
      'fees_paid': [_paidFeeWith(payments)],
    });

void main() {
  group('rejected manual payment', () {
    test('carries the school\'s own reason', () {
      final fee = _fee([
        _manual(id: 61, status: 'Failed', reason: 'reject admin'),
      ]);

      expect(fee.hasRejectedPayment(compulsory: true), isTrue);
      expect(fee.rejectedPaymentReason(compulsory: true), 'reject admin');
      //rejected, so it is no longer awaiting the school
      expect(fee.hasPendingPayment(compulsory: true), isFalse);
    });

    test('gives no reason when the school left it blank', () {
      for (final blank in [null, '', '   ']) {
        final fee = _fee([
          _manual(id: 61, status: 'Failed', reason: blank),
        ]);

        expect(fee.hasRejectedPayment(compulsory: true), isTrue);
        //the screen states the fact rather than inventing an explanation
        expect(fee.rejectedPaymentReason(compulsory: true), isNull);
      }
    });

    test('a payment still awaiting the school is not a rejection', () {
      final fee = _fee([_manual(id: 61, status: 'Pending')]);

      expect(fee.hasRejectedPayment(compulsory: true), isFalse);
      expect(fee.rejectedPaymentReason(compulsory: true), isNull);
      expect(fee.hasPendingPayment(compulsory: true), isTrue);
    });

    test('only the newest attempt decides what is shown', () {
      //rejected once, then a fresh receipt sent: the parent is waiting again,
      //not still rejected — showing both would contradict itself
      final fee = _fee([
        _manual(id: 61, status: 'Failed', reason: 'reject admin'),
        _manual(id: 62, status: 'Pending'),
      ]);

      expect(fee.hasPendingPayment(compulsory: true), isTrue);
      expect(fee.hasRejectedPayment(compulsory: true), isFalse);
      expect(fee.rejectedPaymentReason(compulsory: true), isNull);
    });

    test('a rejection after an earlier attempt still surfaces', () {
      final fee = _fee([
        _manual(id: 61, status: 'Pending'),
        _manual(id: 62, status: 'Failed', reason: 'wrong amount'),
      ]);

      expect(fee.hasRejectedPayment(compulsory: true), isTrue);
      expect(fee.rejectedPaymentReason(compulsory: true), 'wrong amount');
      expect(fee.hasPendingPayment(compulsory: true), isFalse);
    });

    test('an approved payment is neither pending nor rejected', () {
      final fee = _fee([_manual(id: 61, status: 'Success')]);

      expect(fee.hasRejectedPayment(compulsory: true), isFalse);
      expect(fee.hasPendingPayment(compulsory: true), isFalse);
    });

    test('an online payment never counts as a manual rejection', () {
      final fee = ChildFeeDetails.fromJson({
        'id': 23,
        'fees_paid': [
          _paidFeeWith([
            {'id': 57, 'mode': 'Online', 'status': 'Failed', 'amount': 3000},
          ]),
        ],
      });

      expect(fee.hasRejectedPayment(compulsory: true), isFalse);
    });
  });

  group('manual payment state belongs to the tab it was filed against', () {
    //the endpoint says which side a payment is for — `"type": "compulsory"` or
    //`"optional"` — and the two are paid through separate endpoints. State from
    //one must not appear on the other's tab: it would tell a parent an optional
    //fee was awaiting the school when nothing had been sent for it.

    test('a refused compulsory receipt shows on the compulsory tab only', () {
      final fee = ChildFeeDetails.fromJson({
        'id': 24,
        'fees_paid': [
          _paidFeeWith([
            _manual(id: 61, status: 'Failed', reason: 'wrong amount'),
          ]),
        ],
      });

      expect(fee.hasRejectedPayment(compulsory: true), isTrue);
      expect(fee.rejectedPaymentReason(compulsory: true), 'wrong amount');

      expect(fee.hasRejectedPayment(compulsory: false), isFalse);
      expect(fee.rejectedPaymentReason(compulsory: false), isNull);
    });

    test('a refused optional receipt shows on the optional tab only', () {
      final fee = ChildFeeDetails.fromJson({
        'id': 24,
        'fees_paid': [
          _paidFeeWith(
            [],
            optional: [_manual(id: 62, status: 'Failed', reason: 'no proof')],
          ),
        ],
      });

      expect(fee.hasRejectedPayment(compulsory: false), isTrue);
      expect(fee.rejectedPaymentReason(compulsory: false), 'no proof');

      expect(fee.hasRejectedPayment(compulsory: true), isFalse);
      expect(fee.rejectedPaymentReason(compulsory: true), isNull);
    });

    test('a receipt awaiting the school does not block the other tab', () {
      //the pay section is replaced while a receipt is unapproved. Scoped wrong,
      //an optional fee with nothing sent for it would lose its pay button
      final fee = ChildFeeDetails.fromJson({
        'id': 24,
        'fees_paid': [
          _paidFeeWith([_manual(id: 61, status: 'Pending')]),
        ],
      });

      expect(fee.hasPendingPayment(compulsory: true), isTrue);
      expect(fee.hasPendingPayment(compulsory: false), isFalse);
    });

    test('each side keeps its own state when both have one', () {
      //compulsory refused, optional still waiting: each tab reports itself
      final fee = ChildFeeDetails.fromJson({
        'id': 24,
        'fees_paid': [
          _paidFeeWith(
            [_manual(id: 61, status: 'Failed', reason: 'wrong amount')],
            optional: [_manual(id: 62, status: 'Pending')],
          ),
        ],
      });

      expect(fee.hasRejectedPayment(compulsory: true), isTrue);
      expect(fee.hasPendingPayment(compulsory: true), isFalse);

      expect(fee.hasPendingPayment(compulsory: false), isTrue);
      expect(fee.hasRejectedPayment(compulsory: false), isFalse);
      //the compulsory refusal must not follow the parent to the optional tab
      expect(fee.rejectedPaymentReason(compulsory: false), isNull);
    });

    test('the newest attempt is decided per side, not across both', () {
      //ids run across the whole fee, so an optional payment filed later must
      //not silently become "the latest" for the compulsory tab
      final fee = ChildFeeDetails.fromJson({
        'id': 24,
        'fees_paid': [
          _paidFeeWith(
            [_manual(id: 61, status: 'Pending')],
            optional: [_manual(id: 99, status: 'Failed', reason: 'no proof')],
          ),
        ],
      });

      expect(fee.hasPendingPayment(compulsory: true), isTrue);
      expect(fee.hasRejectedPayment(compulsory: true), isFalse);
    });
  });

  group('a settled fee reports no rejection', () {
    /// Fee 24 as the endpoint returned it: a manual receipt refused ("reject
    /// admin"), then the whole fee paid off in cash afterwards.
    ChildFeeDetails settledFee() => ChildFeeDetails.fromJson({
          'id': 24,
          'name': 'FEES test - 9 English',
          'status': 'Success',
          'fees_paid': [
            {
              'id': 35,
              'is_fully_paid': 1,
              'amount': 8000,
              'compulsory_fee': [
                {
                  'id': 62,
                  'payment_transaction_id': 56,
                  'type': 'Full Payment',
                  'mode': 'Manual',
                  'amount': 8500,
                  'status': 'Failed',
                  'reason': 'reject admin',
                },
                {
                  'id': 64,
                  'payment_transaction_id': 58,
                  'type': 'Installment Payment',
                  'mode': 'Cash',
                  'amount': 4000,
                  'status': 'Success',
                  'reason': null,
                },
                {
                  'id': 65,
                  'payment_transaction_id': 59,
                  'type': 'Installment Payment',
                  'mode': 'Cash',
                  'amount': 4000,
                  'status': 'Success',
                  'reason': null,
                },
              ],
              'optional_fee': [],
            }
          ],
        });

    test('no banner once the money is in, whatever was refused before', () {
      final fee = settledFee();

      //the fee itself is settled...
      expect(fee.getFeePaymentStatus(), paidKey);
      //...so "your last transaction was rejected" would contradict the status
      //directly above it, and point at nothing the parent can do
      expect(fee.hasRejectedPayment(compulsory: true), isFalse);
      expect(fee.rejectedPaymentReason(compulsory: true), isNull);
      expect(fee.hasRejectedPayment(compulsory: false), isFalse);
    });

    test('the refused payment is still in the record', () {
      //hidden from the fee screen, not erased — the payment history still
      //carries it, which is where a parent goes to ask what happened
      final payments = settledFee().paidFees!.first.compulsoryPaidFees!;
      final refused = payments.firstWhere((payment) => payment.id == 62);

      expect(refused.mode, 'Manual');
      expect(refused.status, 'Failed');
      expect(refused.reason, 'reject admin');
    });

    test('a fee still owing keeps its rejection banner', () {
      //the guard must not swallow the case the banner exists for
      final fee = _fee([
        _manual(id: 61, status: 'Failed', reason: 'reject admin'),
      ]);

      expect(fee.getFeePaymentStatus(), isNot(paidKey));
      expect(fee.hasRejectedPayment(compulsory: true), isTrue);
      expect(fee.rejectedPaymentReason(compulsory: true), 'reject admin');
    });
  });
}
