import 'package:eschool/cubits/schoolConfigurationCubit.dart';
import 'package:eschool/data/models/childFeeDetails.dart';
import 'package:eschool/data/models/feeTransaction.dart';
import 'package:eschool/data/repositories/schoolRepository.dart';
import 'package:eschool/ui/screens/childFeeDetails/widgets/transactionDetailsBottomsheet.dart';
import 'package:eschool/ui/widgets/customRoundedButton.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// The two rows the endpoint returns against fee 25, verbatim.
final _chequePending = {
  'id': 67,
  'type': 'compulsory',
  'fee_name': 'Instalment 2',
  'amount': 5000,
  'due_charges': 0,
  'mode': 'Cheque',
  'status': 'Pending',
  'date': '27-08-2026',
  'cheque_no': 'op',
  'payment_transaction_id': 60,
  'notes': 'op',
  'reason': null,
  'file': null,
  'receipt_url': null,
};

final _manualApproved = {
  'id': 66,
  'type': 'compulsory',
  'fee_name': 'Instalment 1',
  'amount': 5000,
  'due_charges': 0,
  'mode': 'Manual',
  'status': 'Success',
  'date': '27-08-2026',
  'cheque_no': null,
  //approved, but with no payment transaction to ask a receipt against
  'payment_transaction_id': null,
  'notes': 'pay 5000',
  'reason': null,
  'receipt_url':
      'https://dev-eschool-saas.wrteam.net/storage/629/manual_receipt/x.jpg',
};

Widget _wrap(Map<String, dynamic> json) => MaterialApp(
      home: BlocProvider<SchoolConfigurationCubit>(
        create: (_) => SchoolConfigurationCubit(SchoolRepository()),
        child: Scaffold(
          body: SizedBox(
            width: 375,
            child: TransactionDetailsBottomsheet(
              transaction: FeeTransaction.fromJson(json),
            ),
          ),
        ),
      ),
    );

/// Puts the sheet on screen for one transaction.
///
/// One frame, not pumpAndSettle: an uploaded receipt shows a loading shimmer
/// that never stops animating, while the sheet itself builds in one pass.
Future<void> _show(WidgetTester tester, Map<String, dynamic> json) async {
  await tester.pumpWidget(_wrap(json));
  await tester.pump();
}

void main() {
  group('a cheque payment', () {
    test('is read off the row the way the school recorded it', () {
      final transaction = FeeTransaction.fromJson(_chequePending);

      expect(transaction.mode, 'Cheque');
      expect(transaction.chequeNo, 'op');
      //recorded by the school, so it is not the parent's manual receipt
      expect(transaction.isManual, isFalse);
      expect(transaction.isPending, isTrue);
    });

    testWidgets('names the method in the parent\'s language, not the api\'s',
        (tester) async {
      await _show(tester, _chequePending);

      //the label key, not the backend's raw "Cheque" — an untranslated string
      //would stay English whatever language the school runs the app in
      expect(find.text(chequeKey), findsOneWidget);
    });

    testWidgets('shows which cheque it was', (tester) async {
      await _show(tester, _chequePending);

      expect(find.text(chequeNoKey), findsOneWidget);
      expect(find.text('op'), findsOneWidget);
    });

    testWidgets('is told its own cheque is clearing, not a manual payment',
        (tester) async {
      await _show(tester, _chequePending);

      //the note used to be the manual payment one whatever the mode, so a
      //parent who handed over a cheque was told to wait on a manual payment
      expect(find.text(chequePendingNoteKey), findsOneWidget);
      expect(find.text(manualPaymentPendingNoteKey), findsNothing);
    });

    testWidgets('leaves the cheque row out when there is no number',
        (tester) async {
      //every other mode reports a null cheque_no, and an empty row reads as a
      //fault rather than as nothing to say
      await _show(tester, _manualApproved);

      expect(find.text(chequeNoKey), findsNothing);
    });
  });

  group('the note under an unconfirmed payment', () {
    testWidgets('names a manual payment as one', (tester) async {
      await _show(tester, {..._manualApproved, 'status': 'Pending'});

      expect(find.text(manualPaymentPendingNoteKey), findsOneWidget);
    });

    testWidgets('falls back to wording that fits any mode', (tester) async {
      //cash and gateway payments can sit unconfirmed too
      await _show(
          tester, {..._chequePending, 'mode': 'Cash', 'cheque_no': null});

      expect(find.text(paymentPendingNoteKey), findsOneWidget);
      expect(find.text(manualPaymentPendingNoteKey), findsNothing);
      expect(find.text(chequePendingNoteKey), findsNothing);
    });

    testWidgets('says nothing at all once the payment is settled',
        (tester) async {
      await _show(tester, _manualApproved);

      for (final note in [
        manualPaymentPendingNoteKey,
        chequePendingNoteKey,
        paymentPendingNoteKey,
      ]) {
        expect(find.text(note), findsNothing);
      }
    });
  });

  group('an approved manual payment with no payment transaction', () {
    testWidgets('is not offered a receipt it can never fetch', (tester) async {
      await _show(tester, _manualApproved);

      final transaction = FeeTransaction.fromJson(_manualApproved);
      expect(transaction.isSucceeded, isTrue);
      expect(transaction.paymentTransactionId, isNull);

      //the endpoint is asked by payment transaction id; without one the button
      //could only ever answer "receipt is not available"
      expect(find.text(downloadReceiptKey), findsNothing);
      expect(find.byType(CustomRoundedButton), findsNothing);
    });

    testWidgets('shows the parent their own receipt instead', (tester) async {
      await _show(tester, _manualApproved);

      //it used to appear only against a refusal, which left an approved manual
      //payment showing no receipt at all
      expect(find.text(submittedReceiptKey), findsOneWidget);
    });
  });

  group('a cheque the school has not cleared yet', () {
    /// Fee 27 as the endpoint returns it: one Cheque payment for the whole
    /// ₹78,000, still Pending, and nothing booked against the fee yet.
    final fee = ChildFeeDetails.fromJson({
      'id': 27,
      'name': 'Third FEES - 9 English',
      'status': 'Pending',
      'fees_paid': [
        {
          'id': 39,
          'is_fully_paid': 0,
          'amount': 0,
          'compulsory_fee': [
            {
              'id': 69,
              'payment_transaction_id': 61,
              'type': 'Full Payment',
              'mode': 'Cheque',
              'cheque_no': '989898989898989',
              'amount': 78000,
              'notes': 'Under review',
              'reason': null,
              'status': 'Pending',
            }
          ],
          'optional_fee': [],
        }
      ],
    });

    test('stops the fee offering to be paid again', () {
      //the reported bug: the pay section only stood down for a *manual*
      //receipt, so a cheque for the full amount left Pay Now on screen and the
      //parent could commit the same ₹78,000 twice
      expect(fee.hasPendingPayment(compulsory: true), isTrue);
    });

    test('is named by its own mode, so the note can say cheque', () {
      expect(fee.pendingPaymentMode(compulsory: true), 'cheque');
      expect(
        Utils.pendingPaymentNoteLabelKey(
          fee.pendingPaymentMode(compulsory: true),
        ),
        chequePendingNoteKey,
      );
    });

    test('is not mistaken for a receipt the parent filed', () {
      //the school recorded this cheque; there is no uploaded receipt behind it
      //and nothing for the parent to re-file, so the rejection path stays shut
      expect(fee.hasRejectedPayment(compulsory: true), isFalse);
      //and it reads as still owing, not as money received
      expect(fee.getFeePaymentStatus(), pendingKey);
    });

    test('leaves the other tab payable', () {
      expect(fee.hasPendingPayment(compulsory: false), isFalse);
    });
  });

  group('a cheque the bank sent back', () {
    /// Fee 27 once the cheque bounced: the school marked it Failed and typed a
    /// reason, and nothing was ever booked against the fee.
    ChildFeeDetails bouncedFee({String? reason = 'cheque bounced'}) =>
        ChildFeeDetails.fromJson({
          'id': 27,
          'status': 'Failed',
          'fees_paid': [
            {
              'id': 39,
              'is_fully_paid': 0,
              'amount': 0,
              'compulsory_fee': [
                {
                  'id': 69,
                  'payment_transaction_id': 61,
                  'type': 'Full Payment',
                  'mode': 'Cheque',
                  'cheque_no': '989898989898989',
                  'amount': 78000,
                  'notes': 'Under review',
                  'reason': reason,
                  'status': 'Failed',
                }
              ],
              'optional_fee': [],
            }
          ],
        });

    test('raises the same banner a refused receipt does', () {
      //it used to be shown only for a manual receipt, so a bounced cheque left
      //the parent with a fee that had quietly gone back to owing, unexplained
      expect(bouncedFee().hasRejectedPayment(compulsory: true), isTrue);
    });

    test('carries the school\'s own words through to the sheet', () {
      expect(
        bouncedFee().rejectedPaymentReason(compulsory: true),
        'cheque bounced',
      );
    });

    test('states the refusal even when the school gave no reason', () {
      final fee = bouncedFee(reason: null);

      expect(fee.hasRejectedPayment(compulsory: true), isTrue);
      expect(fee.rejectedPaymentReason(compulsory: true), isNull);
    });

    test('leaves the fee owing and payable again', () {
      final fee = bouncedFee();

      //nothing cleared, so the money is still owed
      expect(fee.getFeePaymentStatus(), pendingKey);
      //and the cheque is no longer outstanding, so Pay Now comes back
      expect(fee.hasPendingPayment(compulsory: true), isFalse);
    });

    test('shows on the tab the cheque was written against, not the other', () {
      expect(bouncedFee().hasRejectedPayment(compulsory: false), isFalse);
      expect(bouncedFee().rejectedPaymentReason(compulsory: false), isNull);
    });

    test('a declined card raises nothing', () {
      //a gateway failure is transient, the school has nothing to explain, and
      //the payment flow already reports it as it happens
      final fee = ChildFeeDetails.fromJson({
        'id': 27,
        'fees_paid': [
          {
            'id': 39,
            'is_fully_paid': 0,
            'amount': 0,
            'compulsory_fee': [
              {
                'id': 70,
                'mode': 'Online',
                'amount': 78000,
                'status': 'Failed',
                'reason': null,
              }
            ],
            'optional_fee': [],
          }
        ],
      });

      expect(fee.hasRejectedPayment(compulsory: true), isFalse);
    });
  });
}
