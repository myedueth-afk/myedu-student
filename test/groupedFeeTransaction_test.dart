import 'package:eschool/cubits/feeTransactionsCubit.dart';
import 'package:eschool/cubits/schoolConfigurationCubit.dart';
import 'package:eschool/data/models/feeTransaction.dart';
import 'package:eschool/data/repositories/feeRepository.dart';
import 'package:eschool/data/repositories/schoolRepository.dart';
import 'package:eschool/ui/screens/childFeeDetails/feeTransactionsScreen.dart';
import 'package:eschool/ui/screens/childFeeDetails/widgets/feeSectionCard.dart';
import 'package:eschool/ui/screens/childFeeDetails/widgets/transactionBreakdown.dart';
import 'package:eschool/ui/screens/childFeeDetails/widgets/transactionDetailsBottomsheet.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// The history endpoint returns one row per *payment*, with the fees it settled
/// nested inside it. Paying an overdue installment together with the current
/// one is one payment of two lines — and read as a single flat row it lost both
/// of them: no fee name at the top level, so the card was headed by a blank,
/// and nothing anywhere naming the installments that were actually paid.

Map<String, dynamic> _line({
  required int id,
  required String feeName,
  int? installmentId,
  double amount = 9000,
  double dueCharges = 0,
  String type = 'compulsory',
}) =>
    {
      'id': id,
      'type': type,
      'fee_name': feeName,
      'fees_id': 30,
      'installment_id': installmentId,
      'amount': amount,
      'due_charges': dueCharges,
      'mode': 'Manual',
      'status': 'Success',
      'date': '2026/02/09',
    };

/// Payment 108 as the endpoint returns it: two installments settled together,
/// a late fee on the overdue one.
Map<String, dynamic> _payment({
  List<Map<String, dynamic>>? compulsory,
  List<Map<String, dynamic>>? optional,
  double? totalAmount = 18500,
  String paymentType = 'Compulsory Fees',
  String status = 'Success',
}) =>
    {
      'id': 108,
      'payment_transaction_id': 108,
      'payment_reference': 'MANUAL-20260902-JZVLLI',
      'payment_gateway': 'manual',
      'payment_status': 'succeed',
      'payment_type': paymentType,
      'amount': 18500,
      if (totalAmount != null) 'total_amount': totalAmount,
      'mode': 'Manual',
      'status': status,
      'date': '2026/02/09',
      'cheque_no': null,
      'notes': null,
      'reason': null,
      'receipt_url': 'https://dev-eschool-saas.wrteam.net/manual_receipt/x.jpg',
      'compulsory_fees': compulsory ??
          [
            _line(id: 125, feeName: 'installment 2', installmentId: 53),
            _line(
                id: 124,
                feeName: 'installment 1',
                installmentId: 52,
                dueCharges: 500),
          ],
      'optional_fees': optional ?? const [],
      'created_at': '2026/02/09 04:48 PM',
    };

Map<String, dynamic> _page(List<Map<String, dynamic>> rows) => {
      'current_page': 1,
      'last_page': 1,
      'per_page': 15,
      'total': rows.length,
      'data': rows,
    };

class _FakeFeeRepository extends FeeRepository {
  final List<Map<String, dynamic>> rows;

  _FakeFeeRepository(this.rows);

  @override
  Future<Map<String, dynamic>> getFeeTransactionsPage({
    required int childId,
    int? feesId,
    int? page,
  }) async =>
      FeeRepository.parseFeeTransactionsPage(_page(rows));
}

Widget _wrap(Widget child) => MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<SchoolConfigurationCubit>(
            create: (_) => SchoolConfigurationCubit(SchoolRepository()),
          ),
        ],
        child: Scaffold(body: SizedBox(width: 400, child: child)),
      ),
    );

void main() {
  group('a payment that settled several fees at once', () {
    late FeeTransaction payment;

    setUp(() {
      payment = FeeTransaction.fromJson(_payment());
    });

    test('keeps every fee it settled', () {
      expect(payment.items.map((e) => e.feeName),
          ['installment 2', 'installment 1']);
    });

    test('is headed by what it was for, since no one fee names it', () {
      //`fee_name` is a line's field; the payment says `payment_type`. Reading
      //only the former left the card headed by an empty string
      expect(payment.feeName, isNull);
      expect(payment.displayName, 'Compulsory Fees');
    });

    test('states the total the account was debited', () {
      expect(payment.totalAmountPaid, 18500.0);
      expect(payment.totalDueCharges, 500.0);
    });

    test('its lines add up to that total', () {
      //what makes the card honest: the figures listed reconcile with the one
      //underneath them
      final linesTotal = payment.items
          .fold<double>(0.0, (sum, item) => sum + item.totalAmountPaid);

      expect(linesTotal, payment.totalAmountPaid);
    });

    test('each line carries its own late fee', () {
      final overdue =
          payment.items.firstWhere((e) => e.feeName == 'installment 1');
      final current =
          payment.items.firstWhere((e) => e.feeName == 'installment 2');

      expect(overdue.amount, 9000.0);
      expect(overdue.dueCharges, 500.0);
      expect(overdue.totalAmountPaid, 9500.0);
      expect(current.totalAmountPaid, 9000.0);
    });

    test('adds its lines up when it states no total of its own', () {
      final withoutTotal = FeeTransaction.fromJson(_payment(totalAmount: null));

      expect(withoutTotal.totalAmountPaid, 18500.0);
    });
  });

  group('a payment that settled one fee', () {
    test('is headed by that fee, as the history always was', () {
      final payment = FeeTransaction.fromJson(_payment(
        compulsory: [
          _line(id: 124, feeName: 'installment 1', dueCharges: 500),
        ],
        totalAmount: 9500,
      ));

      expect(payment.displayName, 'installment 1');
      expect(payment.totalAmountPaid, 9500.0);
    });
  });

  group('the shape the endpoint used to return', () {
    test('still parses, one row per fee', () {
      //deployments on the older backend must keep working
      final flat = FeeTransaction.fromJson(_line(
        id: 124,
        feeName: 'installment 1',
        dueCharges: 500,
      ));

      expect(flat.hasItems, isFalse);
      expect(flat.displayName, 'installment 1');
      expect(flat.totalAmountPaid, 9500.0);
      expect(flat.receiptType, 'compulsory');
    });
  });

  group('which receipt to ask the school for', () {
    test('a compulsory payment asks for the compulsory one', () {
      expect(FeeTransaction.fromJson(_payment()).receiptType, 'compulsory');
    });

    test('an optional payment does not fall back to compulsory', () {
      //the payment row carries no `type`; defaulting blind fetched the wrong
      //receipt for every optional payment
      final payment = FeeTransaction.fromJson(_payment(
        paymentType: 'Optional Fees',
        compulsory: const [],
        optional: [_line(id: 130, feeName: 'GYM', type: 'optional')],
      ));

      expect(payment.isOptional, isTrue);
      expect(payment.receiptType, 'optional');
    });
  });

  group('the history card', () {
    testWidgets('lists both installments under the payment', (tester) async {
      await tester.pumpWidget(_wrap(
        BlocProvider<FeeTransactionsCubit>(
          create: (_) => FeeTransactionsCubit(_FakeFeeRepository([_payment()])),
          child: const FeeTransactionsScreen(childId: 48, feesId: 30),
        ),
      ));
      await tester.pump();

      expect(find.text('Compulsory Fees'), findsOneWidget);
      expect(find.text('installment 1'), findsOneWidget);
      expect(find.text('installment 2'), findsOneWidget);
      //the same statement the sheet makes: each fee at its own amount, the late
      //fee named rather than folded into the installment it was charged on, and
      //a total the parent can add up. A line reading 9500 with nothing saying
      //where the extra 500 came from is what this replaced
      expect(find.text('9000.00'), findsNWidgets(2));
      expect(find.text(dueChargesKey), findsOneWidget);
      expect(find.text('+500.00'), findsOneWidget);
      expect(find.text(totalPaidKey), findsOneWidget);
      expect(find.text('18500.00'), findsOneWidget);
    });

    testWidgets('states the same figures as the sheet behind it',
        (tester) async {
      //the card and the sheet are built by the same widget, so a parent
      //checking one against the other cannot be shown two different stories
      final payment = FeeTransaction.fromJson(_payment());

      await tester.pumpWidget(_wrap(
        BlocProvider<FeeTransactionsCubit>(
          create: (_) => FeeTransactionsCubit(_FakeFeeRepository([_payment()])),
          child: const FeeTransactionsScreen(childId: 48, feesId: 30),
        ),
      ));
      await tester.pump();
      final onTheCard = tester
          .widgetList<TransactionAmountLine>(find.byType(TransactionAmountLine))
          .map((line) => '${line.label} ${line.value}')
          .toList();

      await tester.pumpWidget(_wrap(
        TransactionDetailsBottomsheet.routeInstance(payment),
      ));
      await tester.pump();
      final onTheSheet = tester
          .widgetList<TransactionAmountLine>(find.byType(TransactionAmountLine))
          .map((line) => '${line.label} ${line.value}')
          .toList();

      expect(onTheCard, onTheSheet);
    });

    testWidgets('leaves a single fee payment as it was', (tester) async {
      //one line is already the card's title; repeating it underneath says
      //nothing
      await tester.pumpWidget(_wrap(
        BlocProvider<FeeTransactionsCubit>(
          create: (_) => FeeTransactionsCubit(_FakeFeeRepository([
            _payment(
              compulsory: [_line(id: 124, feeName: 'Full Payment')],
              totalAmount: 9000,
            )
          ])),
          child: const FeeTransactionsScreen(childId: 48, feesId: 30),
        ),
      ));
      await tester.pump();

      expect(find.text('Full Payment'), findsOneWidget);
    });
  });

  group('the details sheet', () {
    Future<void> showSheet(WidgetTester tester,
        [Map<String, dynamic>? payment]) async {
      await tester.pumpWidget(_wrap(
        TransactionDetailsBottomsheet.routeInstance(
          FeeTransaction.fromJson(payment ?? _payment()),
        ),
      ));
      await tester.pump();
    }

    testWidgets('itemises each fee and its own late fee', (tester) async {
      await showSheet(tester);

      //fee amounts, the late fee against the installment it was charged on,
      //and a total the parent can add up for themselves
      expect(find.text('installment 1'), findsOneWidget);
      expect(find.text('installment 2'), findsOneWidget);
      expect(find.text(dueChargesKey), findsOneWidget);
      expect(find.text('+500.00'), findsOneWidget);
      expect(find.text(totalPaidKey), findsOneWidget);
      expect(find.text('18500.00'), findsOneWidget);
    });

    testWidgets('gathers the money into a single card', (tester) async {
      //the fees, the late fee and the total read as one statement rather than
      //as a run of rows divided edge to edge
      await showSheet(tester);

      expect(find.byType(FeeSectionCard), findsOneWidget);
    });

    testWidgets('says how and when as a caption, not as labelled rows',
        (tester) async {
      await showSheet(tester);

      expect(find.text(manualPaymentKey), findsOneWidget);
      expect(find.text('2026/02/09'), findsOneWidget);
      //given rows of their own these carried the weight of the amounts, which
      //are what the sheet exists to show
      expect(find.text(paymentMethodKey), findsNothing);
      expect(find.text(paymentDateKey), findsNothing);
    });

    testWidgets('states a plain payment once, not twice', (tester) async {
      //no fee lines and no late fee: an "Amount" row above the total would be
      //the same figure written out again
      await showSheet(
        tester,
        _payment(
          compulsory: [_line(id: 124, feeName: 'Full Payment')],
          totalAmount: 9000,
        ),
      );

      expect(find.text('9000.00'), findsOneWidget);
      expect(find.text(amountKey), findsNothing);
      expect(find.text(totalPaidKey), findsOneWidget);
    });
  });
}
