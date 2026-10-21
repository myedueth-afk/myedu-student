import 'package:eschool/ui/screens/childFeeDetails/widgets/feeDetailsMenuBottomsheet.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: SizedBox(width: 375, child: child)),
    );

void main() {
  group('FeeDetailsMenuBottomsheet', () {
    testWidgets('offers both actions once something has been paid',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          FeeDetailsMenuBottomsheet(
            onPrint: () {},
            onViewTransactionHistory: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(printKey), findsOneWidget);
      expect(find.text(transactionHistoryKey), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.printer), findsOneWidget);
      expect(find.byIcon(Icons.history_rounded), findsOneWidget);
    });

    testWidgets('leaves Print out when there is no receipt to print',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          FeeDetailsMenuBottomsheet(
            onPrint: null,
            onViewTransactionHistory: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      //a fee with nothing paid against it has no receipt, so offering Print
      //would be a dead end
      expect(find.text(printKey), findsNothing);
      expect(find.byIcon(CupertinoIcons.printer), findsNothing);
      //the history is always worth reaching
      expect(find.text(transactionHistoryKey), findsOneWidget);
    });

    testWidgets('runs the action the parent picked', (tester) async {
      var printed = 0;
      var opened = 0;

      await tester.pumpWidget(
        _wrap(
          FeeDetailsMenuBottomsheet(
            onPrint: () => printed++,
            onViewTransactionHistory: () => opened++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(printKey));
      await tester.pumpAndSettle();
      expect(printed, 1);
      expect(opened, 0);

      await tester.tap(find.text(transactionHistoryKey));
      await tester.pumpAndSettle();
      expect(opened, 1);
      expect(printed, 1);
    });

    testWidgets('the whole row is the target, not just its label',
        (tester) async {
      var opened = 0;

      await tester.pumpWidget(
        _wrap(
          FeeDetailsMenuBottomsheet(
            onPrint: null,
            onViewTransactionHistory: () => opened++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.history_rounded));
      await tester.pumpAndSettle();

      expect(opened, 1);
      expect(tester.takeException(), isNull);
    });
  });
}
