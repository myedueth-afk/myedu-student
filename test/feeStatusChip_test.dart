import 'package:eschool/data/models/childFeeDetails.dart';
import 'package:eschool/ui/styles/colors.dart';
import 'package:eschool/ui/widgets/statusChip.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

/// A fee shaped the way the endpoint returns one, dialled to a given state.
ChildFeeDetails _fee({
  required int isFullyPaid,
  required double paidAmount,
  bool anyPayment = true,
}) =>
    ChildFeeDetails.fromJson({
      'id': 24,
      'fees_paid': anyPayment
          ? [
              {
                'id': 35,
                'is_fully_paid': isFullyPaid,
                'amount': paidAmount,
                'compulsory_fee': [],
                'optional_fee': [],
              }
            ]
          : [],
    });

void main() {
  group('every fee status reaches the screen as a chip', () {
    //the three states a fee can be in, and the colour each one wears

    test('a fee with nothing paid is Pending', () {
      final fee = _fee(isFullyPaid: 0, paidAmount: 0, anyPayment: false);

      expect(fee.getFeePaymentStatus(), pendingKey);
      expect(Utils.getFeePaymentStatusColor(pendingKey), leavePendingColor);
    });

    test('a part paid fee is Partially Paid, and reads as still owing', () {
      final fee = _fee(isFullyPaid: 0, paidAmount: 4250);

      expect(fee.getFeePaymentStatus(), partiallyPaidKey);
      //same colour as Pending on purpose: both mean money is still owed, and
      //the label is what separates them
      expect(
        Utils.getFeePaymentStatusColor(partiallyPaidKey),
        leavePendingColor,
      );
    });

    test('a settled fee is Paid, and the only one that turns green', () {
      final fee = _fee(isFullyPaid: 1, paidAmount: 8000);

      expect(fee.getFeePaymentStatus(), paidKey);
      expect(Utils.getFeePaymentStatusColor(paidKey), transactionPaidColor);
      //the one status a parent does not have to act on
      expect(
        Utils.getFeePaymentStatusColor(paidKey),
        isNot(Utils.getFeePaymentStatusColor(pendingKey)),
      );
    });
  });

  group('StatusChip', () {
    testWidgets('states the status on a filled pill', (tester) async {
      await tester.pumpWidget(
        _wrap(const StatusChip(label: 'Pending', color: leavePendingColor)),
      );

      expect(find.text('Pending'), findsOneWidget);

      final decoration = tester
          .widget<Container>(find.byType(Container))
          .decoration as BoxDecoration;
      expect(decoration.color, leavePendingColor);
      expect(decoration.borderRadius, BorderRadius.circular(6.0));
    });

    testWidgets('sets the label against the fill, not against the page',
        (tester) async {
      //a chip whose label took the page's text colour would read as dark grey
      //on orange — the fill has to carry it
      await tester.pumpWidget(
        _wrap(const StatusChip(label: 'Paid', color: transactionPaidColor)),
      );

      final style = tester.widget<Text>(find.text('Paid')).style!;
      expect(style.color, isNot(secondaryColor));
      expect(style.fontSize, 12.0);
      expect(style.fontWeight, FontWeight.w500);
    });

    testWidgets('stays one line however long the status reads', (tester) async {
      //"Partially Paid" is the longest of the three, and it shares the card
      //with a name and a class
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 375,
            child: Row(
              children: [
                const Expanded(child: Text('Some Long Student Name')),
                const SizedBox(width: 12.0),
                StatusChip(
                  label: Utils.getTranslatedLabel(partiallyPaidKey),
                  color: Utils.getFeePaymentStatusColor(partiallyPaidKey),
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
