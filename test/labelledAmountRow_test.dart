import 'package:eschool/ui/widgets/labelledAmountRow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _boxKey = Key('box');

Widget _wrap(Widget child, {double width = 296}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(key: _boxKey, width: width, child: child),
        ),
      ),
    );

/// Distance between the amount's right edge and the container's.
double _gapFromRightEdge(WidgetTester tester, String amount) {
  final box = tester.getRect(find.byKey(_boxKey));
  final value = tester.getRect(find.text(amount));
  return box.right - value.right;
}

void main() {
  group('LabelledAmountRow', () {
    testWidgets('sets the amount hard against the right edge', (tester) async {
      //deliberately short, so it cannot fill half the row — that is the case a
      //50/50 flex split gets wrong, leaving the figure adrift in the middle
      await tester.pumpWidget(
        _wrap(
            const LabelledAmountRow(label: 'Payable Amount', amount: 'X9.00')),
      );
      await tester.pump();

      expect(_gapFromRightEdge(tester, 'X9.00'), 0.0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps it there as the amount grows', (tester) async {
      for (final amount in ['X9.00', 'X9000.00', 'X999999.00']) {
        await tester.pumpWidget(
          _wrap(LabelledAmountRow(label: 'Payable Amount', amount: amount)),
        );
        await tester.pump();

        expect(
          _gapFromRightEdge(tester, amount),
          0.0,
          reason: '$amount drifted off the right edge',
        );
      }
    });

    testWidgets('gives way in the label rather than overflowing',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const LabelledAmountRow(
            label: 'A considerably longer translation of the payable amount '
                'label than English needs',
            amount: 'X999999.00',
          ),
        ),
      );
      await tester.pump();

      expect(_gapFromRightEdge(tester, 'X999999.00'), 0.0);
      expect(tester.takeException(), isNull,
          reason: 'the label must absorb the squeeze, not overflow the row');
    });

    testWidgets('reads as one line: label left, figure right', (tester) async {
      await tester.pumpWidget(
        _wrap(
            const LabelledAmountRow(label: 'Payable Amount', amount: 'X9.00')),
      );
      await tester.pump();

      final box = tester.getRect(find.byKey(_boxKey));
      final label = tester.getRect(find.text('Payable Amount'));
      final value = tester.getRect(find.text('X9.00'));

      expect(label.left, box.left, reason: 'label starts at the left edge');
      expect(value.left, greaterThan(label.left));
      //vertically centred against each other despite the size difference
      expect((label.center.dy - value.center.dy).abs(), lessThan(1.0));
    });
  });
}
