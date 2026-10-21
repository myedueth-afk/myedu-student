import 'package:eschool/cubits/schoolConfigurationCubit.dart';
import 'package:eschool/data/models/childFeeDetails.dart';
import 'package:eschool/data/models/feeTransaction.dart';
import 'package:eschool/data/repositories/schoolRepository.dart';
import 'package:eschool/ui/screens/childFeeDetails/widgets/installments.dart';
import 'package:eschool/ui/screens/childFeeDetails/widgets/transactionDetailsBottomsheet.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// The endpoint keeps a late fee apart from the fee itself all the way down —
/// `total_due_paid_amount` beside `total_paid_amount`, `due_charges` beside
/// `amount` — so anything adding up to "what I paid" has to rejoin them.
///
/// Fee 30 on dev is the case that showed it did not: two installments of 9,000
/// with a 500 late fee, reported as 18,000 against an account debited 18,500.

/// One settled compulsory payment row, shaped the way `fees_paid` carries it.
Map<String, dynamic> _payment({
  required int id,
  required int installmentId,
  double amount = 9000,
  double dueCharges = 0,
  String status = 'Success',
}) =>
    {
      'id': id,
      'installment_id': installmentId,
      'type': 'Installment Payment',
      'mode': 'Manual',
      'amount': amount,
      'due_charges': dueCharges,
      'status': status,
      'date': '2026/02/09',
    };

Map<String, dynamic> _installment({
  required int id,
  required String name,
  double amount = 9000,
  double dueChargeAmount = 0,
  bool isPaid = false,
}) =>
    {
      'id': id,
      'name': name,
      'installment_amount': amount,
      'paid_amount': isPaid ? amount : 0,
      'due_charges': 500,
      'due_charges_amount': dueChargeAmount,
      'is_paid': isPaid,
      'due_date': '2026-09-01',
    };

/// Fee 30: both installments settled, the first one late.
ChildFeeDetails _settledInInstallments({
  bool withBackendTotals = true,
  String status = 'Success',
}) =>
    ChildFeeDetails.fromJson({
      'id': 30,
      'name': 'Fees installment TEST 2 - 9 English',
      'due_charges': 5,
      'due_charges_in_percentage': 5,
      'due_charges_amount': 900,
      'is_overdue': false,
      'include_fee_installments': true,
      'total_compulsory_fees': 18000,
      if (withBackendTotals) 'total_paid_amount': 18000,
      if (withBackendTotals) 'total_due_paid_amount': 500,
      'installments': [
        _installment(
            id: 52, name: 'installment 1', dueChargeAmount: 500, isPaid: true),
        _installment(id: 53, name: 'installment 2', isPaid: true),
      ],
      'fees_paid': [
        {
          'id': 62,
          'is_fully_paid': 1,
          'is_used_installment': 1,
          'amount': 18000,
          'compulsory_fee': [
            _payment(
                id: 124, installmentId: 52, dueCharges: 500, status: status),
            _payment(id: 125, installmentId: 53, status: status),
          ],
          'optional_fee': const [],
        }
      ],
    });

void main() {
  group('what a fee reports as paid', () {
    test('carries the late fee collected with it', () {
      final fee = _settledInInstallments();

      expect(fee.paidFeeAmount(), 18000.0);
      expect(fee.paidDueChargesAmount(), 500.0);
      //the figure the account was debited, and the one the breakdown states
      expect(fee.totalAmountPaid(), 18500.0);
      expect(fee.hasPaidAnyAmount(), isTrue);
    });

    test('adds up the payment rows when the endpoint sends no totals', () {
      //every settled row records the late fee taken with it, so the rows come
      //to the same figure the totals do
      final fee = _settledInInstallments(withBackendTotals: false);

      expect(fee.paidFeeAmount(), 18000.0);
      expect(fee.paidDueChargesAmount(), 500.0);
      expect(fee.totalAmountPaid(), 18500.0);
    });

    test('counts nothing for a receipt the school has not approved', () {
      //the rows exist the moment a manual payment is filed; counting them
      //would call it settled while the school is still looking at the receipt
      final fee =
          _settledInInstallments(withBackendTotals: false, status: 'Pending');

      expect(fee.totalAmountPaid(), 0.0);
      expect(fee.hasPaidAnyAmount(), isFalse);
    });

    test('counts nothing for a receipt the school refused', () {
      final fee =
          _settledInInstallments(withBackendTotals: false, status: 'Failed');

      expect(fee.totalAmountPaid(), 0.0);
    });
  });

  group('the late fees a fee has attracted', () {
    test('a collected one stays on the fee after it is paid', () {
      //keyed off "overdue right now", the breakdown dropped the charge as soon
      //as it was settled, leaving the card 500 short
      final fee = _settledInInstallments();

      expect(fee.isFeeOverDue(), isFalse, reason: 'nothing is owed any more');
      expect(fee.outstandingDueChargesAmount(inInstallmentMode: true), 0.0);
      expect(fee.totalDueChargesAmount(inInstallmentMode: true), 500.0);
    });

    test('a collected one and one still owed are both counted', () {
      final fee = ChildFeeDetails.fromJson({
        'id': 30,
        'include_fee_installments': true,
        'total_compulsory_fees': 18000,
        'total_paid_amount': 9000,
        'total_due_paid_amount': 500,
        'installments': [
          _installment(
              id: 52,
              name: 'installment 1',
              dueChargeAmount: 500,
              isPaid: true),
          _installment(id: 53, name: 'installment 2', dueChargeAmount: 300),
        ],
        'fees_paid': [
          {
            'id': 62,
            'is_fully_paid': 0,
            'amount': 9000,
            'compulsory_fee': [
              _payment(id: 124, installmentId: 52, dueCharges: 500)
            ],
            'optional_fee': const [],
          }
        ],
      });

      expect(fee.outstandingDueChargesAmount(inInstallmentMode: true), 300.0);
      expect(fee.totalDueChargesAmount(inInstallmentMode: true), 800.0);
      expect(fee.totalAmountPaid(), 9500.0);
    });

    test('a fee paid in one go carries the single charge on the whole fee', () {
      //no installments, so the penalty is the fee level one
      Map<String, dynamic> json({required bool overdue, required int paid}) => {
            'id': 27,
            'total_compulsory_fees': 8000,
            'due_charges_amount': 400,
            'due_charges_in_percentage': 5,
            'is_overdue': overdue,
            'installments': const [],
            'fees_paid': paid == 0
                ? const []
                : [
                    {
                      'id': 39,
                      'is_fully_paid': 1,
                      'amount': 8000,
                      'compulsory_fee': [
                        {
                          'id': 62,
                          'type': 'Full Payment',
                          'amount': 8000,
                          'due_charges': 400,
                          'status': 'Success',
                        }
                      ],
                      'optional_fee': const [],
                    }
                  ],
          };

      final owed = ChildFeeDetails.fromJson(json(overdue: true, paid: 0));
      expect(owed.outstandingDueChargesAmount(inInstallmentMode: false), 400.0);
      expect(owed.totalDueChargesAmount(inInstallmentMode: false), 400.0);

      //settled, it moves from owed to collected: counted once either way
      final settled = ChildFeeDetails.fromJson(json(overdue: false, paid: 1));
      expect(
          settled.outstandingDueChargesAmount(inInstallmentMode: false), 0.0);
      expect(settled.totalDueChargesAmount(inInstallmentMode: false), 400.0);
      expect(settled.totalAmountPaid(), 8400.0);
    });

    test('a fee with no penalty configured reports none', () {
      final fee = ChildFeeDetails.fromJson({
        'id': 27,
        'total_compulsory_fees': 8000,
        'is_overdue': true,
        'due_charges_amount': 0,
        'installments': const [],
        'fees_paid': const [],
      });

      expect(fee.totalDueChargesAmount(inInstallmentMode: false), 0.0);
      expect(fee.totalDueChargesAmount(inInstallmentMode: true), 0.0);
    });
  });

  group('one payment in the history', () {
    test('states what it actually took, not the fee half of it', () {
      final transaction = FeeTransaction.fromJson({
        'id': 124,
        'type': 'compulsory',
        'fee_name': 'installment 1',
        'amount': 9000,
        'due_charges': 500,
        'mode': 'Manual',
        'status': 'Success',
        'date': '2026/02/09',
      });

      expect(transaction.hasDueCharges, isTrue);
      expect(transaction.totalAmountPaid, 9500.0);
    });

    test('reads as the plain amount when no late fee was charged', () {
      final transaction = FeeTransaction.fromJson({
        'id': 125,
        'fee_name': 'installment 2',
        'amount': 9000,
        'due_charges': 0,
        'status': 'Success',
      });

      expect(transaction.hasDueCharges, isFalse);
      expect(transaction.totalAmountPaid, 9000.0);
    });

    testWidgets('itemises the two halves on its receipt', (tester) async {
      //Total Paid alone has to be taken on trust; itemised, it can be checked
      await tester.pumpWidget(_wrapWithSchoolConfig(
        TransactionDetailsBottomsheet(
          transaction: FeeTransaction.fromJson({
            'id': 124,
            'fee_name': 'installment 1',
            'amount': 9000,
            'due_charges': 500,
            'mode': 'Manual',
            'status': 'Success',
            'date': '2026/02/09',
          }),
        ),
      ));
      await tester.pump();

      //labels stand in for translations, and the empty school configuration
      //leaves no currency symbol in front of the figures
      expect(find.text(amountKey), findsOneWidget);
      expect(find.text('9000.00'), findsOneWidget);
      expect(find.text(dueChargesKey), findsOneWidget);
      expect(find.text('+500.00'), findsOneWidget);
      expect(find.text(totalPaidKey), findsOneWidget);
      expect(find.text('9500.00'), findsOneWidget);
    });

    testWidgets('leaves the itemisation off when there was no late fee',
        (tester) async {
      await tester.pumpWidget(_wrapWithSchoolConfig(
        TransactionDetailsBottomsheet(
          transaction: FeeTransaction.fromJson({
            'id': 125,
            'fee_name': 'installment 2',
            'amount': 9000,
            'due_charges': 0,
            'mode': 'Manual',
            'status': 'Success',
          }),
        ),
      ));
      await tester.pump();

      expect(find.text(dueChargesKey), findsNothing);
      expect(find.text(totalPaidKey), findsOneWidget);
      expect(find.text('9000.00'), findsOneWidget);
    });
  });

  group('an installment card', () {
    testWidgets('states what was paid for it, late fee included',
        (tester) async {
      //the headline shows 9,000 with 500 beside it in red; without a row that
      //adds them up the card states neither total
      await tester.pumpWidget(_wrapWithSchoolConfig(
        Installments(childFeeDetails: _settledInInstallments()),
      ));
      await tester.pump();

      expect(find.text(totalPaidKey), findsOneWidget);
      expect(find.text('9500.00'), findsOneWidget);
      //the second carried no late fee, so its headline is the whole story
      expect(find.text(payableAmountKey), findsNothing);
    });
  });
}

/// The widgets read a currency symbol off the school configuration, so one has
/// to be in scope. The default has none, keeping expectations to the figures.
Widget _wrapWithSchoolConfig(Widget child) => MaterialApp(
      home: BlocProvider<SchoolConfigurationCubit>(
        create: (_) => SchoolConfigurationCubit(SchoolRepository()),
        child: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(width: 375, child: child),
          ),
        ),
      ),
    );
