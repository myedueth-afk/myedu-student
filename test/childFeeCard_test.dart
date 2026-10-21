import 'package:eschool/data/models/childFeeDetails.dart';
import 'package:eschool/ui/widgets/childFeeCard.dart';
import 'package:eschool/ui/widgets/statusChip.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fee shaped the way the endpoint returns one, with a single payment on
/// whichever side is asked for.
ChildFeeDetails _fee({
  String name = 'Third FEES - 9 English',
  String? mode,
  String? status,
  bool optional = false,
  int isFullyPaid = 0,
  double paidAmount = 0,
}) {
  final payments = mode == null
      ? const []
      : [
          {
            'id': 69,
            'mode': mode,
            'amount': 78000,
            'status': status,
            'reason': null,
          }
        ];

  return ChildFeeDetails.fromJson({
    'id': 27,
    'name': name,
    'due_date': '28-08-2026',
    'class': {'id': 2, 'name': '9'},
    'session_year': {'id': 1, 'name': '2026'},
    'fees_paid': [
      {
        'id': 39,
        'is_fully_paid': isFullyPaid,
        'amount': paidAmount,
        'compulsory_fee': optional ? const [] : payments,
        'optional_fee': optional ? payments : const [],
      }
    ],
  });
}

Future<void> _showCard(WidgetTester tester, ChildFeeDetails fee) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          //wider than a handset on purpose. The test font draws every glyph at
          //the full font size, so the label keys standing in for translations
          //("status : ") are roughly twice their real width — at a true 325 the
          //status row overflows on its own, before this card is even involved.
          width: 600,
          child: ChildFeeCard(fee: fee, onTap: () {}),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('a fee with money waiting on the school', () {
    testWidgets('says so on the card', (tester) async {
      //without this the list reads "Pending" — the same as a fee nobody has
      //touched — for a parent who paid by cheque last week
      await _showCard(tester, _fee(mode: 'Cheque', status: 'Pending'));

      expect(find.text(underReviewKey), findsOneWidget);
      expect(find.byType(StatusChip), findsOneWidget);
    });

    testWidgets('says so for a receipt filed in the app too', (tester) async {
      await _showCard(tester, _fee(mode: 'Manual', status: 'Pending'));

      expect(find.text(underReviewKey), findsOneWidget);
    });

    testWidgets('names the optional side when that is what is waiting',
        (tester) async {
      //the list has no tabs, so a card stands for the whole fee — and the
      //status line beside the chip speaks for the compulsory side alone
      await _showCard(
        tester,
        _fee(mode: 'Manual', status: 'Pending', optional: true),
      );

      expect(find.text(optionalUnderReviewKey), findsOneWidget);
      expect(find.text(underReviewKey), findsNothing);
    });

    testWidgets('does not name a side when the compulsory fee is waiting too',
        (tester) async {
      //both sides waiting: the unscoped label already covers the whole fee
      await _showCard(
        tester,
        ChildFeeDetails.fromJson({
          'id': 27,
          'name': 'Third FEES - 9 English',
          'class': {'id': 2, 'name': '9'},
          'session_year': {'id': 1, 'name': '2026'},
          'fees_paid': [
            {
              'id': 39,
              'is_fully_paid': 0,
              'amount': 0,
              'compulsory_fee': [
                {'id': 69, 'mode': 'Cheque', 'status': 'Pending'}
              ],
              'optional_fee': [
                {'id': 70, 'mode': 'Manual', 'status': 'Pending'}
              ],
            }
          ],
        }),
      );

      expect(find.text(underReviewKey), findsOneWidget);
      expect(find.text(optionalUnderReviewKey), findsNothing);
    });

    testWidgets('keeps the fee status alongside it', (tester) async {
      //Under Review is news about a payment, not a fourth fee status, so the
      //status line still answers "how much of this fee is settled"
      await _showCard(tester, _fee(mode: 'Cheque', status: 'Pending'));

      expect(find.text(underReviewKey), findsOneWidget);
      expect(find.textContaining(statusKey), findsOneWidget);
      expect(find.text(pendingKey), findsOneWidget);
    });

    testWidgets('a settled fee with optional money in flight says both',
        (tester) async {
      //the screenshot case: compulsory paid in full while an optional receipt
      //sits with the school. "Paid" beside a bare "Under Review" reads as a
      //contradiction — naming the side makes the two one sentence
      await _showCard(
        tester,
        _fee(
          mode: 'Manual',
          status: 'Pending',
          optional: true,
          isFullyPaid: 1,
          paidAmount: 18500,
        ),
      );

      expect(find.text(paidKey), findsOneWidget);
      expect(find.text(optionalUnderReviewKey), findsOneWidget);
    });
  });

  group('a fee with nothing waiting', () {
    testWidgets('shows no chip when nothing has been paid', (tester) async {
      await _showCard(tester, _fee());

      expect(find.text(underReviewKey), findsNothing);
      expect(find.byType(StatusChip), findsNothing);
    });

    testWidgets('shows no chip once the school has confirmed', (tester) async {
      await _showCard(
        tester,
        _fee(
          mode: 'Cheque',
          status: 'Success',
          isFullyPaid: 1,
          paidAmount: 78000,
        ),
      );

      expect(find.text(underReviewKey), findsNothing);
      expect(find.text(paidKey), findsOneWidget);
    });

    testWidgets('shows no chip after a payment was refused', (tester) async {
      //a bounced cheque is not under review — it is over, and the fee screen
      //carries the reason
      await _showCard(tester, _fee(mode: 'Cheque', status: 'Failed'));

      expect(find.text(underReviewKey), findsNothing);
    });
  });

  group('the card holds its shape', () {
    testWidgets('stays the height the list lays out for it', (tester) async {
      //the card is a fixed 100: anything added to it has to fit, and a Column
      //that does not throws rather than scrolling
      await _showCard(tester, _fee(mode: 'Cheque', status: 'Pending'));

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(ChildFeeCard)).height, 100.0);
    });

    testWidgets('gives way in the fee name, not past the card edge',
        (tester) async {
      //the chip is fixed width and the name is not, so the name is what yields
      await _showCard(
        tester,
        _fee(
          name: 'APP side all installment pay TEST with a very long name '
              '- 9 English',
          mode: 'Cheque',
          status: 'Pending',
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(underReviewKey), findsOneWidget);

      final card = tester.getRect(find.byType(ChildFeeCard));
      final chip = tester.getRect(find.byType(StatusChip));
      //the chip is inside the card's padding, not spilling off the right edge
      expect(chip.right, lessThanOrEqualTo(card.right - 15));
    });

    testWidgets('holds the wider optional chip inside the card too',
        (tester) async {
      //"Optional Under Review" is the widest thing the chip ever says
      await _showCard(
        tester,
        _fee(
          name: 'APP side all installment pay TEST with a very long name '
              '- 9 English',
          mode: 'Manual',
          status: 'Pending',
          optional: true,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(optionalUnderReviewKey), findsOneWidget);

      final card = tester.getRect(find.byType(ChildFeeCard));
      final chip = tester.getRect(find.byType(StatusChip));
      expect(chip.right, lessThanOrEqualTo(card.right - 15));
      //a translation cannot eat the row: the chip is capped at 55% of it, so
      //the name always keeps enough width to identify the fee
      expect(chip.width, lessThanOrEqualTo((card.width - 30) * 0.55));
    });
  });
}
