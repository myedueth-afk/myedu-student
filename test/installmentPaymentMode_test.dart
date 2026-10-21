import 'package:eschool/cubits/schoolConfigurationCubit.dart';
import 'package:eschool/data/models/childFeeDetails.dart';
import 'package:eschool/data/repositories/schoolRepository.dart';
import 'package:eschool/ui/screens/childFeeDetails/widgets/installments.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Which of the two routes a compulsory fee is on — paid in full, or in
/// installments — decides the whole compulsory tab: the Fee Breakdown card
/// against the installments card, and whether the choice is still offered.
///
/// It used to be read from whether an installment was *paid*, so a parent who
/// submitted an installment payment for review came back to the full payment
/// screen: nothing was paid yet, so nothing said installments.

Map<String, dynamic> _payment({
  int id = 124,
  int? installmentId,
  String type = 'Installment Payment',
  String status = 'Success',
  double amount = 5000,
}) =>
    {
      'id': id,
      'installment_id': installmentId,
      'type': type,
      'mode': 'Manual',
      'amount': amount,
      'due_charges': 0,
      'status': status,
      'date': '2026/02/09',
    };

Map<String, dynamic> _installment({
  required int id,
  required String name,
  bool isPaid = false,
}) =>
    {
      'id': id,
      'name': name,
      'installment_amount': 5000,
      'paid_amount': isPaid ? 5000 : 0,
      'is_paid': isPaid,
      'due_date': '2026-09-01',
    };

ChildFeeDetails _fee({
  List<Map<String, dynamic>> payments = const [],
  List<Map<String, dynamic>>? installments,
  int isFullyPaid = 0,
}) =>
    ChildFeeDetails.fromJson({
      'id': 31,
      'name': 'Fees installment TEST - 9 English',
      'include_fee_installments': true,
      'total_compulsory_fees': 10000,
      'installments': installments ??
          [
            _installment(id: 60, name: 'Installment 1'),
            _installment(id: 61, name: 'Installment 2'),
          ],
      'fees_paid': payments.isEmpty
          ? const []
          : [
              {
                'id': 70,
                'is_fully_paid': isFullyPaid,
                'amount': 0,
                'compulsory_fee': payments,
                'optional_fee': const [],
              }
            ],
    });

void main() {
  group('a fee is on the installment route', () {
    test('while an installment payment waits on the school', () {
      //the case from the screen: both installments submitted together for
      //review. Nothing is paid, but the fee is committed to installments and
      //the screen has to keep showing them
      final fee = _fee(payments: [
        _payment(id: 124, installmentId: 60, status: 'Pending'),
        _payment(id: 125, installmentId: 61, status: 'Pending'),
      ]);

      expect(fee.isBeingPaidInInstallments(), isTrue);
      expect(fee.didUserPaidPreviousCompulsoryFeeInInstallment(), isFalse,
          reason: 'nothing is paid yet — which is exactly the trap');
    });

    test('when the payment is filed before the backend allocates an id', () {
      //`type` is set the moment the payment is filed, so it stands in for an
      //installment_id that is not there yet
      final fee = _fee(payments: [
        _payment(id: 124, status: 'Pending'),
      ]);

      expect(fee.isBeingPaidInInstallments(), isTrue);
    });

    test('once the school has approved it', () {
      final fee = _fee(
        payments: [_payment(id: 124, installmentId: 60)],
        installments: [
          _installment(id: 60, name: 'Installment 1', isPaid: true),
          _installment(id: 61, name: 'Installment 2'),
        ],
      );

      expect(fee.isBeingPaidInInstallments(), isTrue);
    });
  });

  group('a fee is not on the installment route', () {
    test('when nothing has been paid or filed', () {
      expect(_fee().isBeingPaidInInstallments(), isFalse);
    });

    test('when the payment filed was for the whole fee', () {
      final fee = _fee(payments: [
        _payment(id: 124, type: 'Full Payment', status: 'Pending'),
      ]);

      expect(fee.isBeingPaidInInstallments(), isFalse);
    });

    test('when the installment payment was refused', () {
      //that money never arrived, so the fee is open to either route again
      final fee = _fee(payments: [
        _payment(id: 124, installmentId: 60, status: 'Failed'),
      ]);

      expect(fee.isBeingPaidInInstallments(), isFalse);
    });
  });

  group('whether the choice of route is still open', () {
    test('it is, while nothing stands against the fee', () {
      expect(_fee().canStillChooseHowToPay(), isTrue);
    });

    test('it is not, once a payment is filed and awaiting the school', () {
      //offering the toggle here would invite a second payment down the other
      //route while the first is still with the school
      final fee = _fee(payments: [
        _payment(id: 124, installmentId: 60, status: 'Pending'),
      ]);

      expect(fee.canStillChooseHowToPay(), isFalse);
    });

    test('it is not, once a payment has settled', () {
      final fee = _fee(payments: [_payment(id: 124, installmentId: 60)]);

      expect(fee.canStillChooseHowToPay(), isFalse);
    });

    test('it opens again after a refusal', () {
      //the row stays on the fee for ever; reading it as a commitment left the
      //parent with no way back to installments
      final fee = _fee(payments: [
        _payment(id: 124, installmentId: 60, status: 'Failed'),
      ]);

      expect(fee.canStillChooseHowToPay(), isTrue);
    });
  });

  group('one installment awaiting the school', () {
    test('is marked, and its neighbours are not', () {
      final fee = _fee(payments: [
        _payment(id: 124, installmentId: 60, status: 'Pending'),
      ]);

      expect(fee.isInstallmentPending(installmentId: 60), isTrue);
      expect(fee.isInstallmentPending(installmentId: 61), isFalse);
    });

    test('is not marked once the payment has settled or been refused', () {
      final settled = _fee(payments: [_payment(id: 124, installmentId: 60)]);
      expect(settled.isInstallmentPending(installmentId: 60), isFalse);

      final refused = _fee(payments: [
        _payment(id: 124, installmentId: 60, status: 'Failed'),
      ]);
      expect(refused.isInstallmentPending(installmentId: 60), isFalse);
    });

    testWidgets('says so on its card instead of showing it as due',
        (tester) async {
      //the money is with the school; a due date here reads as "pay this"
      await tester.pumpWidget(MaterialApp(
        home: BlocProvider<SchoolConfigurationCubit>(
          create: (_) => SchoolConfigurationCubit(SchoolRepository()),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Installments(
                childFeeDetails: _fee(payments: [
                  _payment(id: 124, installmentId: 60, status: 'Pending'),
                ]),
              ),
            ),
          ),
        ),
      ));
      await tester.pump();

      expect(find.text(underReviewKey), findsOneWidget);
      //the second installment is untouched, so it still shows its due date
      expect(find.textContaining(dueDateKey), findsOneWidget);
    });
  });
}
