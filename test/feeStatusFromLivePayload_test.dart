import 'package:eschool/data/models/childFeeDetails.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:flutter_test/flutter_test.dart';

/// The three states a fee can be in, in the shape the fees endpoint sends
/// them.
///
/// [getFeePaymentStatus] keys off the `fees_paid` row rather than the fee's own
/// `status` field, so that row is what these carry. Written out here rather
/// than read from a captured payload: the states are what is under test, and a
/// captured fee moves on the moment somebody pays it.
ChildFeeDetails _fee(Map<String, dynamic> paidFeeRow) =>
    ChildFeeDetails.fromJson({
      'id': 24,
      'name': 'FEES test - 9 English',
      'fees_paid': [paidFeeRow],
    });

void main() {
  group('fee status, against the shapes the endpoint sends', () {
    test('a rejected manual receipt leaves the fee Pending', () {
      //a refused receipt leaves a fees_paid row behind that books nothing.
      //Reading that as Partially Paid would tell the parent money had landed
      //when the school had just turned it down
      final fee = _fee({
        'id': 35,
        'is_fully_paid': 0,
        'amount': 0,
        'compulsory_fee': [
          {
            'id': 62,
            'payment_transaction_id': 56,
            'type': 'Full Payment',
            'mode': 'Manual',
            'amount': 8500,
            'status': 'Failed',
            'reason': 'reject admin',
          }
        ],
        'optional_fee': [],
      });

      expect(fee.getFeePaymentStatus(), pendingKey);
      //rejected, so it is no longer awaiting the school — the parent can pay
      //again and the pay section comes back
      expect(fee.hasPendingPayment(compulsory: true), isFalse);
    });

    test('a fee cleared by a full discount is Paid', () {
      //books nothing either, but is genuinely settled: the zero amount rule
      //must not swallow this case, which is why is_fully_paid is read first
      final fee = _fee({
        'id': 35,
        'is_fully_paid': 1,
        'amount': 0,
        'compulsory_fee': [],
        'optional_fee': [],
      });

      expect(fee.getFeePaymentStatus(), paidKey);
    });

    test('a fee with money genuinely against it is Partially Paid', () {
      final fee = _fee({
        'id': 35,
        'is_fully_paid': 0,
        'amount': 4250,
        'compulsory_fee': [
          {
            'id': 61,
            'mode': 'Online',
            'amount': 4250,
            'status': 'Success',
          }
        ],
        'optional_fee': [],
      });

      expect(fee.getFeePaymentStatus(), partiallyPaidKey);
    });

    test('a fee nobody has paid anything against is Pending', () {
      final fee = ChildFeeDetails.fromJson({'id': 23, 'fees_paid': []});

      expect(fee.getFeePaymentStatus(), pendingKey);
    });
  });
}
