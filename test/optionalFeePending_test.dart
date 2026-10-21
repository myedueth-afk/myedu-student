import 'package:eschool/data/models/childFeeDetails.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fee 28 as the endpoint returns it.
///
/// Two optional fees — Sports (62) and GYM (63) — and a manual payment sent
/// for Sports alone, still waiting on the school. GYM has had nothing sent for
/// it and must stay payable.
///
/// The compulsory side has its own manual receipt outstanding, which is what
/// makes this fee worth keeping: the two sides must not read each other's
/// state.
ChildFeeDetails _fee({
  String sportsPaymentStatus = 'Pending',
  bool gymAlsoSent = false,
}) =>
    ChildFeeDetails.fromJson({
      'id': 28,
      'name': 'optional FESS TEST - 9 English',
      'status': 'Pending',
      'optional_fees': [
        {
          'id': 62,
          'fees_id': 28,
          'amount': 900,
          'optional': 1,
          'is_paid': false,
          'is_pending': true,
          'status': 'Pending',
          'net_payable_amount': 900,
          'fees_type_name': 'Sports',
        },
        {
          'id': 63,
          'fees_id': 28,
          'amount': 900,
          'optional': 1,
          'is_paid': false,
          'is_pending': false,
          'status': 'Unpaid',
          'net_payable_amount': 900,
          'fees_type_name': 'GYM',
        },
      ],
      'fees_paid': [
        {
          'id': 56,
          'is_fully_paid': 0,
          'amount': 0,
          'compulsory_fee': [
            {
              'id': 113,
              'type': 'Full Payment',
              'mode': 'Manual',
              'amount': 12000,
              'status': 'Pending',
              'reason': null,
            }
          ],
          'optional_fee': [
            {
              'id': 4,
              //the link back to the optional fee it was sent for
              'fees_class_id': 62,
              //the endpoint really does send this empty, with mode_name set
              'mode': '',
              'mode_name': 'Online',
              'amount': 900,
              'status': sportsPaymentStatus,
              'reason': null,
            },
            if (gymAlsoSent)
              {
                'id': 5,
                'fees_class_id': 63,
                'mode': '',
                'mode_name': 'Online',
                'amount': 900,
                'status': 'Pending',
                'reason': null,
              },
          ],
        }
      ],
    });

void main() {
  group('one optional fee under review does not lock the rest', () {
    test('the fee that was paid for is under review', () {
      expect(_fee().isOptionalFeePending(optionalFeeId: 62), isTrue);
    });

    test('the one that was not is untouched', () {
      //the reported bug: sending a receipt for Sports took GYM out of the
      //parent's reach, though nothing had been sent for it
      expect(_fee().isOptionalFeePending(optionalFeeId: 63), isFalse);
    });

    test('so the pay section stays up', () {
      expect(_fee().hasPayableOptionalFee(), isTrue);
    });

    test('and stands down only once every optional fee is spoken for', () {
      final fee = _fee(gymAlsoSent: true);

      expect(fee.isOptionalFeePending(optionalFeeId: 62), isTrue);
      expect(fee.isOptionalFeePending(optionalFeeId: 63), isTrue);
      expect(fee.hasPayableOptionalFee(), isFalse);
    });

    test('a settled optional fee is not payable either', () {
      final fee = ChildFeeDetails.fromJson({
        'id': 28,
        'optional_fees': [
          {'id': 62, 'amount': 900, 'optional': 1, 'is_paid': true},
        ],
        'fees_paid': [],
      });

      expect(fee.hasPayableOptionalFee(), isFalse);
      //paid, not pending — the row shows the tick, not the hourglass
      expect(fee.isOptionalFeePending(optionalFeeId: 62), isFalse);
    });

    test('once the school confirms, the fee stops being under review', () {
      final fee = _fee(sportsPaymentStatus: 'Success');

      expect(fee.isOptionalFeePending(optionalFeeId: 62), isFalse);
      expect(fee.hasPayableOptionalFee(), isTrue);
    });

    test('a refused optional payment is not under review', () {
      //refused is over, not waiting: the fee goes back to being payable
      final fee = _fee(sportsPaymentStatus: 'Failed');

      expect(fee.isOptionalFeePending(optionalFeeId: 62), isFalse);
      expect(fee.hasPayableOptionalFee(), isTrue);
    });
  });

  group('the two sides of a fee keep their own state', () {
    test('the compulsory receipt still blocks the compulsory tab', () {
      expect(_fee().hasPendingPayment(compulsory: true), isTrue);
    });

    test('and an optional payment does not reach across to it', () {
      final fee = ChildFeeDetails.fromJson({
        'id': 28,
        'optional_fees': [
          {'id': 62, 'amount': 900, 'optional': 1, 'is_paid': false},
        ],
        'fees_paid': [
          {
            'id': 56,
            'is_fully_paid': 0,
            'amount': 0,
            'compulsory_fee': [],
            'optional_fee': [
              {'id': 4, 'fees_class_id': 62, 'amount': 900, 'status': 'Pending'}
            ],
          }
        ],
      });

      expect(fee.hasPendingPayment(compulsory: false), isTrue);
      expect(fee.hasPendingPayment(compulsory: true), isFalse);
    });

    test('a payment with no fee behind it belongs to no optional fee', () {
      //fees_class_id is what ties a payment to its fee; without one it cannot
      //be allowed to lock an arbitrary row
      final fee = ChildFeeDetails.fromJson({
        'id': 28,
        'optional_fees': [
          {'id': 62, 'amount': 900, 'optional': 1, 'is_paid': false},
        ],
        'fees_paid': [
          {
            'id': 56,
            'is_fully_paid': 0,
            'amount': 0,
            'compulsory_fee': [],
            'optional_fee': [
              {'id': 4, 'fees_class_id': null, 'status': 'Pending'}
            ],
          }
        ],
      });

      expect(fee.isOptionalFeePending(optionalFeeId: 62), isFalse);
      expect(fee.hasPayableOptionalFee(), isTrue);
    });
  });
}
