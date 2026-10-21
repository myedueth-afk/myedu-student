import 'package:eschool/ui/screens/childFeeDetails/widgets/rejectedPaymentBottomsheet.dart';
import 'package:eschool/ui/widgets/rejectedPaymentBanner.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: SizedBox(width: 343, child: child)),
    );

void main() {
  group('RejectedPaymentBanner', () {
    testWidgets('states the refusal and points onward', (tester) async {
      await tester.pumpWidget(_wrap(RejectedPaymentBanner(onTap: () {})));
      await tester.pumpAndSettle();

      expect(find.text(lastTransactionRejectedKey), findsOneWidget);
      //forward chevron: the banner opens something rather than unfolding
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });

    testWidgets('the whole banner is the target, not just the chevron',
        (tester) async {
      var taps = 0;
      await tester
          .pumpWidget(_wrap(RejectedPaymentBanner(onTap: () => taps++)));
      await tester.pumpAndSettle();

      await tester.tap(find.text(lastTransactionRejectedKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();

      expect(taps, 2);
    });

    testWidgets('does not carry the reason itself', (tester) async {
      await tester.pumpWidget(_wrap(RejectedPaymentBanner(onTap: () {})));
      await tester.pumpAndSettle();

      //the reason belongs to the sheet, so the banner stays one line however
      //much the school wrote
      expect(find.text('reject admin'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('RejectedPaymentBottomsheet', () {
    testWidgets('shows the school\'s own words', (tester) async {
      await tester.pumpWidget(
        _wrap(
          RejectedPaymentBottomsheet(
            reason: 'reject admin',
            onViewTransaction: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(lastTransactionRejectedKey), findsOneWidget);
      expect(find.text(reasonKey), findsOneWidget);
      expect(find.text('reject admin'), findsOneWidget);
      expect(find.text(viewTransactionKey), findsOneWidget);
    });

    testWidgets('drops the reason block when the school gave none',
        (tester) async {
      for (final blank in [null, '', '   ']) {
        await tester.pumpWidget(
          _wrap(
            RejectedPaymentBottomsheet(
              reason: blank,
              onViewTransaction: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(reasonKey), findsNothing);
        //the refusal and the way onward still stand
        expect(find.text(lastTransactionRejectedKey), findsOneWidget);
        expect(find.text(viewTransactionKey), findsOneWidget);
      }
    });

    testWidgets('reaches the payment history', (tester) async {
      var opened = 0;

      await tester.pumpWidget(
        _wrap(
          RejectedPaymentBottomsheet(
            reason: 'reject admin',
            onViewTransaction: () => opened++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(viewTransactionKey));
      await tester.pumpAndSettle();

      expect(opened, 1);
    });

    testWidgets('a long reason wraps rather than overflowing', (tester) async {
      await tester.pumpWidget(
        _wrap(
          RejectedPaymentBottomsheet(
            reason: 'The amount on the receipt does not match the fee due, and '
                'the transfer reference could not be found on the bank '
                'statement for that date. Please send a corrected receipt.',
            onViewTransaction: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(RejectedPaymentBottomsheet)).width,
        343,
      );
    });
  });
}
