import 'package:eschool/data/models/childFeeDetails.dart';
import 'package:eschool/ui/screens/childFeeDetails/widgets/feeInformationContainer.dart';
import 'package:eschool/data/models/student.dart';
import 'package:eschool/ui/widgets/statusChip.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The compulsory and optional sides of a fee are settled separately, and the
/// backend's `is_fully_paid` speaks only for the compulsory one. Anything that
/// states a status has to say which side it is talking about, or a fee whose
/// compulsory half is paid reads as settled while optional money is still with
/// the school.

/// A fee with an optional catalogue and, optionally, a payment filed against
/// one of its entries.
ChildFeeDetails _fee({
  List<Map<String, dynamic>> optionalFees = const [],
  List<Map<String, dynamic>> optionalPayments = const [],
  int isFullyPaid = 1,
  double paidAmount = 18500,
}) {
  return ChildFeeDetails.fromJson({
    'id': 27,
    'name': 'Fees installment TEST 2 - 9 English',
    'due_date': '03-09-2026',
    'class': {'id': 2, 'name': '9'},
    'session_year': {'id': 1, 'name': '2026'},
    'optional_fees': optionalFees,
    'fees_paid': [
      {
        'id': 39,
        'is_fully_paid': isFullyPaid,
        'amount': paidAmount,
        'compulsory_fee': const [],
        'optional_fee': optionalPayments,
      }
    ],
  });
}

Map<String, dynamic> _optionalFee({
  required int id,
  required String name,
  bool isPaid = false,
}) =>
    {
      'id': id,
      'is_paid': isPaid,
      'fees_type': {'id': id, 'name': name},
    };

Map<String, dynamic> _optionalPayment({
  required int id,
  required int feesClassId,
  required String status,
}) =>
    {
      'id': id,
      'fees_class_id': feesClassId,
      'mode': 'Manual',
      'amount': 500,
      'status': status,
    };

void main() {
  group('the optional side has its own status', () {
    test('money with the school outranks the compulsory "Paid"', () {
      //the screenshot case: compulsory settled in full, GYM and ONLINE filed
      //together and both waiting on the school
      final fee = _fee(
        optionalFees: [
          _optionalFee(id: 62, name: 'GYM'),
          _optionalFee(id: 63, name: 'ONLINE calsss'),
        ],
        optionalPayments: [
          _optionalPayment(id: 70, feesClassId: 62, status: 'Pending'),
          _optionalPayment(id: 71, feesClassId: 63, status: 'Pending'),
        ],
      );

      expect(fee.getFeePaymentStatus(), paidKey,
          reason: 'the compulsory side really is settled');
      expect(fee.getOptionalFeePaymentStatus(), underReviewKey,
          reason: 'and the optional side really is not');
    });

    test('settled once every optional fee is paid', () {
      final fee = _fee(
        optionalFees: [
          _optionalFee(id: 62, name: 'GYM', isPaid: true),
          _optionalFee(id: 63, name: 'ONLINE calsss', isPaid: true),
        ],
      );

      expect(fee.getOptionalFeePaymentStatus(), paidKey);
    });

    test('part paid when some are settled and nothing is waiting', () {
      final fee = _fee(
        optionalFees: [
          _optionalFee(id: 62, name: 'GYM', isPaid: true),
          _optionalFee(id: 63, name: 'ONLINE calsss'),
        ],
      );

      expect(fee.getOptionalFeePaymentStatus(), partiallyPaidKey);
    });

    test('pending when none has been picked up yet', () {
      final fee = _fee(
        optionalFees: [_optionalFee(id: 62, name: 'GYM')],
      );

      expect(fee.getOptionalFeePaymentStatus(), pendingKey);
    });

    test('one waiting alongside one settled still reads as waiting', () {
      //the row for GYM says Under Review, so the summary above it must not
      //say Partially Paid
      final fee = _fee(
        optionalFees: [
          _optionalFee(id: 62, name: 'GYM'),
          _optionalFee(id: 63, name: 'ONLINE calsss', isPaid: true),
        ],
        optionalPayments: [
          _optionalPayment(id: 70, feesClassId: 62, status: 'Pending'),
          //a later payment that went through must not bury the one that has not
          _optionalPayment(id: 71, feesClassId: 63, status: 'Success'),
        ],
      );

      expect(fee.getOptionalFeePaymentStatus(), underReviewKey);
    });

    test('a refused payment is not waiting on anyone', () {
      final fee = _fee(
        optionalFees: [_optionalFee(id: 62, name: 'GYM')],
        optionalPayments: [
          _optionalPayment(id: 70, feesClassId: 62, status: 'Failed'),
        ],
      );

      expect(fee.getOptionalFeePaymentStatus(), pendingKey);
    });

    test('no status at all when the school defined no optional fees', () {
      expect(_fee().getOptionalFeePaymentStatus(), isNull);
    });
  });

  group('the fee list card scopes its chip', () {
    test('names the optional side when only that side is waiting', () {
      final fee = _fee(
        optionalFees: [_optionalFee(id: 62, name: 'GYM')],
        optionalPayments: [
          _optionalPayment(id: 70, feesClassId: 62, status: 'Pending'),
        ],
      );

      expect(fee.paymentUnderReviewLabelKey(), optionalUnderReviewKey);
    });

    test('reads an optional payment the list payload cannot expand', () {
      //the list gives the payments without the optional fee catalogue, so the
      //scope cannot come from the rows
      final fee = _fee(
        optionalPayments: [
          _optionalPayment(id: 70, feesClassId: 62, status: 'Pending'),
        ],
      );

      expect(fee.optionalFees, isEmpty);
      expect(fee.paymentUnderReviewLabelKey(), optionalUnderReviewKey);
    });

    test('says nothing when no money is with the school', () {
      expect(_fee().paymentUnderReviewLabelKey(), isNull);
    });
  });

  group('the fee detail header follows the tab it sits under', () {
    /// The header as the detail screen builds it, on one tab or the other.
    Future<void> showHeader(
      WidgetTester tester,
      ChildFeeDetails fee, {
      required bool compulsory,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              child: FeeInformationContainer(
                child: Student.fromJson(const {
                  'id': 1,
                  'first_name': 'Ato',
                  'last_name': 'Bava',
                }),
                childFeeDetails: fee,
                compulsory: compulsory,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    final settledCompulsoryWaitingOptional = _fee(
      optionalFees: [_optionalFee(id: 62, name: 'GYM')],
      optionalPayments: [
        _optionalPayment(id: 70, feesClassId: 62, status: 'Pending'),
      ],
    );

    testWidgets('states the compulsory settlement on the compulsory tab',
        (tester) async {
      await showHeader(tester, settledCompulsoryWaitingOptional,
          compulsory: true);

      expect(find.text(paidKey), findsOneWidget);
      expect(find.text(underReviewKey), findsNothing);
    });

    testWidgets('states the optional side on the optional tab', (tester) async {
      //a green "Paid" above rows marked Under Review is what this replaces
      await showHeader(tester, settledCompulsoryWaitingOptional,
          compulsory: false);

      expect(find.text(underReviewKey), findsOneWidget);
      expect(find.text(paidKey), findsNothing);
    });

    testWidgets('shows no chip on an optional tab with nothing on it',
        (tester) async {
      await showHeader(tester, _fee(), compulsory: false);

      expect(find.byType(StatusChip), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
