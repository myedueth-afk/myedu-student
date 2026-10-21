import 'package:eschool/data/models/childFeeDetails.dart';
import 'package:eschool/data/models/installment.dart';
import 'package:flutter_test/flutter_test.dart';

/// Due dates are written relative to today so these stay true whenever they
/// run, in both the formats the fees endpoint sends: `due_date` machine
/// ("2026-07-02") and `format_due_date` display ("02-07-2026").
Map<String, String> _dueDates(int daysFromToday) {
  final date = DateTime.now().add(Duration(days: daysFromToday));
  final dd = date.day.toString().padLeft(2, '0');
  final mm = date.month.toString().padLeft(2, '0');
  return {
    'due_date': '${date.year}-$mm-$dd',
    'format_due_date': '$dd-$mm-${date.year}',
  };
}

Map<String, dynamic> _installment({
  required int id,
  required String name,
  required int dueInDays,
  double amount = 5000,
  double dueChargeAmount = 500,
  double discountAmount = 2000,
  bool isPaid = false,
  bool isCurrent = false,
}) =>
    {
      'id': id,
      'name': name,
      'installment_amount': amount,
      'paid_amount': 0,
      'discount_amount': discountAmount,
      'net_payable_amount': amount - discountAmount,
      'due_charges': dueChargeAmount,
      'due_charges_amount': dueChargeAmount,
      'is_paid': isPaid,
      'is_current': isCurrent,
      ..._dueDates(dueInDays),
    };

ChildFeeDetails _fee(List<Map<String, dynamic>> installments) =>
    ChildFeeDetails.fromJson({
      'id': 23,
      'name': 'last time test - 9 English',
      'include_fee_installments': true,
      'total_compulsory_fees': 20000,
      'installments': installments,
      'fees_paid': [],
    });

/// The relief the payment summary shows, derived exactly as
/// `_buildCompulsoryInstallmentPaymentInfoContainer` derives it: per
/// installment, what its relief actually takes off its own payable amount.
double _reliefShownForPayment(ChildFeeDetails fee) =>
    fee.dueInstallments().fold(
          0.0,
          (sum, i) =>
              sum +
              (fee.installmentAmountAfterAdvance(i) -
                  fee.netRemainingOfInstallment(i)),
        );

List<int?> _ids(List<Installment> installments) =>
    installments.map((e) => e.id).toList();

void main() {
  group('outstanding installments, against the shape the endpoint sends', () {
    test(
        'an overdue installment carrying no late fee is still collected, '
        'with its relief', () {
      //fee 23 on the dev server: four unpaid installments, all past their due
      //date, none flagged is_current, and Installment 3 configured with a zero
      //due charge. Keyed off the due charge alone it dropped out of the
      //payment entirely — the summary showed 3 installments (15000) and only
      //6000 of the 8000 relief, and the parent could not pay it at all while
      //paying Installment 4
      final fee = _fee([
        _installment(id: 42, name: 'Installment 1', dueInDays: -60),
        _installment(id: 43, name: 'Installment 2', dueInDays: -60),
        _installment(
            id: 44, name: 'Installment 3', dueInDays: -59, dueChargeAmount: 0),
        _installment(id: 45, name: 'Installment 4', dueInDays: -44),
      ]);

      expect(_ids(fee.dueInstallments()), [42, 43, 44, 45]);
      expect(_reliefShownForPayment(fee), 8000.0);
      //nothing is left over once every installment is being paid, so there is
      //no amount to offer as an advance
      expect(fee.maximumAdvanceInstallmentAmount(), 0.0);
    });

    test('a zero due charge still adds nothing to the payable total', () {
      //the installment joins the payment, but it was never penalised, so it
      //must not pull a due charge in with it
      final fee = _fee([
        _installment(
            id: 44, name: 'Installment 3', dueInDays: -59, dueChargeAmount: 0),
      ]);

      final installment = fee.dueInstallments().single;
      expect(installment.dueChargeAmount, 0.0);
      //display stays keyed on the charge, so no +0.00 penalty row appears
      expect(installment.isInstallmentOverdue(), isFalse);
      expect(installment.isPastDueDate(), isTrue);
    });

    test('an installment due today is the current one, not an outstanding one',
        () {
      //it is not late yet, so it belongs on the "next installment" line — and
      //being the first unpaid one, it is still part of the payment
      final fee = _fee([
        _installment(
            id: 50, name: 'Installment 1', dueInDays: 0, dueChargeAmount: 0),
        _installment(
            id: 51, name: 'Installment 2', dueInDays: 30, dueChargeAmount: 0),
      ]);

      expect(fee.dueInstallments(), isEmpty);
      expect(fee.currentInstallment().id, 50);
      expect(fee.nextUnpaidInstallment().id, 50);
    });

    test('a future installment is left out of the payment', () {
      final fee = _fee([
        _installment(id: 52, name: 'Installment 1', dueInDays: -10),
        _installment(
            id: 53, name: 'Installment 2', dueInDays: 20, dueChargeAmount: 0),
      ]);

      expect(_ids(fee.dueInstallments()), [52]);
      //its 3000 net stays available as an advance instead
      expect(fee.maximumAdvanceInstallmentAmount(), 3000.0);
    });

    test('a paid installment is never collected again', () {
      final fee = _fee([
        _installment(
            id: 54, name: 'Installment 1', dueInDays: -30, isPaid: true),
        _installment(id: 55, name: 'Installment 2', dueInDays: -10),
      ]);

      expect(_ids(fee.dueInstallments()), [55]);
    });

    test('an installment with no readable due date falls back to the old rules',
        () {
      //the backend penalised it, which settles the question on its own
      final fee = _fee([
        {
          'id': 56,
          'name': 'Installment 1',
          'installment_amount': 5000,
          'paid_amount': 0,
          'discount_amount': 2000,
          'due_charges_amount': 500,
          'is_paid': false,
          'is_current': false,
        },
      ]);

      final installment = fee.installments!.single;
      expect(installment.isPastDueDate(), isFalse);
      expect(_ids(fee.dueInstallments()), [56]);
    });
  });
}
