import 'package:eschool/ui/widgets/expandableContentContainer.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 311,
          child: SingleChildScrollView(child: child),
        ),
      ),
    );

void main() {
  group('ExpandableContentContainer', () {
    testWidgets('leaves short content alone, with no control', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ExpandableContentContainer(
            collapsedHeight: 300,
            child: SizedBox(height: 120, width: double.infinity),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(ExpandableContentContainer)).height,
        120,
      );
      expect(find.text(showMoreKey), findsNothing);
      expect(find.text(showLessKey), findsNothing);
    });

    testWidgets('folds tall content and offers to reveal the rest',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ExpandableContentContainer(
            collapsedHeight: 300,
            child: SizedBox(height: 1600, width: double.infinity),
          ),
        ),
      );
      await tester.pumpAndSettle();

      //the content is folded, not merely scrolled past
      final folded =
          tester.getSize(find.byType(ExpandableContentContainer)).height;
      expect(folded, lessThan(400));
      expect(find.text(showMoreKey), findsOneWidget);

      await tester.tap(find.text(showMoreKey));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(ExpandableContentContainer)).height,
        greaterThan(1600),
      );
      expect(find.text(showLessKey), findsOneWidget);
    });

    testWidgets('folds back up again', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ExpandableContentContainer(
            collapsedHeight: 300,
            child: SizedBox(height: 1600, width: double.infinity),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(showMoreKey));
      await tester.pumpAndSettle();
      //expanding pushes the control past the fold of the test viewport
      await tester.ensureVisible(find.text(showLessKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text(showLessKey));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(ExpandableContentContainer)).height,
        lessThan(400),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
