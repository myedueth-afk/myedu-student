import 'package:eschool/ui/screens/childFeeDetails/widgets/paymentInstructionsHtml.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 512x512 image, the same shape of payload the panel embeds as the payment
/// QR. Its size is the point of the fixture: rendered at its intrinsic size it
/// would overflow the card and be drawn past 1:1 on a high density screen,
/// which is what made the code look blurry.
const String _largePngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAgAAAAIACAAAAADRE4smAAAEb0lEQVR42u3csQ0AMQwDMe2/tNN7'
    'gQAWv2UnXL50sr5ZH+9yAwnAQAIwkAAMJAADCcBAAuAC4ALgAuAC4ALgAuAC4ALgN9wgXryBBGAg'
    'ARhIAAYSgIEEwAXABcAFwAXABcAFwAXABcAFwO8FYBBuAG4AbgBuAG4gARhIAAYSgIEEYCABGEgA'
    'XABcAFwAXADcfQDuxXMBcAFwAXABcAFwAXABcAFwAXABcAFwAXABcAFw9wG4PwIXABcAFwAXABcA'
    'FwAXABcAFwAXABcAFwAXABcAdx+Ae/FcAFwAXABcAFwAXABcAFwAXABcAFwAXABcAFwA3H0A7o/A'
    'BcAFwAXABcAFwAXABcAFwAXABcAFwAXABcAFwN0H4AbgBuAG4AbgBhCAgQRgIAEYSAAGEoCBBGAg'
    'AXABcAFwAfC4D2AwfwQuAC4ALgAuAC4ALgAuAC4ALgAuAC4ALgAuAC4A7j4A9+K5ALgAuAC4ALgA'
    'uAC4ALgAuAC4ALgAuAC4ALgAuPsA3B+BC4ALgAuAC4ALgAuAC4ALgAuAC4ALgAuAC4ALgLsPwL14'
    'LgAuAC4ALgAuAC4ALgAuAC4ALgAuAC4ALgAuAO4+APdH4ALgAuAC4ALgAuAC4ALgAuAC4ALgBuAG'
    '4AbgBqh0g3jxBhKAgQRgIAEYSAAGEgAXABcAFwAXABcAFwAXABcAFwB3H4D7I3ABcAFwAXABcAFw'
    'AXABcAFwAXABcAFwAXABcAFw9wG4F88FwAXABcAFwAXABcAFwAXABcAFwAXABcAFwAXA3Qfg/ghc'
    'AFwAXABcAFwAXABcAFwAXABcAFwAXABcAFwA3H0A7sVzAXABcAFwAXABcAFwAXABcAFwAXABcAFw'
    'AXABcPcBuD8CFwAXABcAFwA3ADcANwA3ADcAN5AADCQAAwnAQAIw0LgPwL14LgAuAC4ALgAuAC4A'
    'LgAuAC4ALgAuAC4ALgAuAO4+APdH4ALgAuAC4ALgAuAC4ALgAuAC4ALgAuAC4ALgAuDuA3AvnguA'
    'C4ALgAuAC4ALgAuAC4ALgAuAC4ALgAuAC4C7D8D9EbgAuAC4ALgAuAC4ALgAuAC4ALgAuAC4ALgA'
    'uAC4+wDci+cC4ALgAuAC4ALgBuAG4AbgBuAGEICBBGAgARhIAAaqDMAg3ADcANwA3ADcQAIwkAAM'
    'JAADCcBAAjCQALgAuAC4ALgAuPsA3IvnAuAC4ALgAuAC4ALgAuAC4ALgAuAC4ALgAuAC4O4DcH8E'
    'LgAuAC4ALgAuAC4ALgAuAC4ALgAuAC4ALgAuAO4+APfiuQC4ALgAuAC4ALgAuAC4ALgAuAC4ALgA'
    'uAC4ALj7ANwfgQuAC4ALgAuAC4ALgAuAC4ALgAuAC4ALgAuAC4C7D8ANwA3ADcANwA0gAAMJwEAC'
    'MJAADCQAAwnAQALgAuAC4ALgcR/AYP4IXABcAFwAXABcAFwAXABcAFwAXABcAFwAXABcANx9AO7F'
    'cwFwAXABcAFwAXABcAFwAXABcAFwAXABcAFwAfD//gBmpx3jV0GKJgAAAABJRU5ErkJggg==';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        //narrower than the image is wide, so an unconstrained image would
        //overflow rather than quietly shrink
        width: 311,
        child: SingleChildScrollView(child: child),
      ),
    ),
  );
}

/// Payment instructions in the shape the panel's editor saves them.
///
/// Three tables, each several rows deep, none of them carrying a `border`
/// attribute — the case that used to render as a borderless grid — and none
/// short enough to be one line tall.
///
/// The real QR is left out. Embedded as base64 it is 20kb on its own, and past
/// 10kb the renderer builds off the main thread and shows a spinner until it is
/// done, so this test would be measuring that spinner. What the QR does to
/// layout has its own tests above; these are about tables.
const String _panelInstructionsMarkup = '''
<p>BANK DETAILS</p>
<table>
<thead><tr><th>Field</th><th>Details</th></tr></thead>
<tbody>
<tr><td>Bank Name</td><td>State Bank of India</td></tr>
<tr><td>Account Holder</td><td>Tony Stark Academy School</td></tr>
<tr><td>Account Number</td><td>123456789012</td></tr>
<tr><td>IFSC Code</td><td>SBIN0001234</td></tr>
<tr><td>Branch</td><td>Main Branch</td></tr>
</tbody>
</table>
<p>UPI DETAILS</p>
<table>
<thead><tr><th>Field</th><th>Details</th></tr></thead>
<tbody>
<tr><td>UPI ID</td><td>tonystarkacademy@upi</td></tr>
<tr><td>Payment Name</td><td>Tony Stark Academy</td></tr>
<tr><td>Reference</td><td>Student admission number</td></tr>
<tr><td>Note</td><td>Send the screenshot after paying</td></tr>
</tbody>
</table>
<p>AFTER PAYING</p>
<table>
<thead><tr><th>Step</th><th>What to do</th></tr></thead>
<tbody>
<tr><td>1</td><td>Keep the transaction receipt</td></tr>
<tr><td>2</td><td>Upload it against the fee</td></tr>
<tr><td>3</td><td>Wait for the school to confirm</td></tr>
<tr><td>4</td><td>Check the fee status afterwards</td></tr>
</tbody>
</table>
''';

void main() {
  group('PaymentInstructionsHtml', () {
    testWidgets(
        'holds an embedded image to the QR box instead of its '
        'intrinsic size', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PaymentInstructionsHtml(
            html:
                '<p><br><img src="data:image/png;base64,$_largePngBase64"></p>',
          ),
        ),
      );
      await tester.pump();

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      //the 512px source must be laid out at the design's 124px square
      expect(tester.getSize(imageFinder), const Size(124, 124));
    });

    testWidgets('downsamples with a filter that keeps a dense code legible',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          PaymentInstructionsHtml(
            html: '<img src="data:image/png;base64,$_largePngBase64">',
          ),
        ),
      );
      await tester.pump();

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.filterQuality, FilterQuality.medium);
      expect(image.fit, BoxFit.contain);
    });

    testWidgets('lays out the instruction tables without overflowing',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PaymentInstructionsHtml(
            html: '<p>BANK DETAILS</p>'
                '<table><thead><tr><th>Field</th><th>Details</th></tr></thead>'
                '<tbody><tr><td>Bank Name</td><td>State Bank of India</td></tr>'
                '<tr><td>Account Number</td><td>123456789012</td></tr>'
                '</tbody></table>',
          ),
        ),
      );
      await tester.pump();

      //HtmlWidget lays text out as RichText spans, not Text widgets
      expect(
        find.textContaining('BANK DETAILS', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('State Bank of India', findRichText: true),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'gives every table in the real panel markup the height its '
        'rows actually need', (tester) async {
      //the panel's own markup: bare `<table>` with a header row and a body,
      //which is what the editor saves when nobody touches the table properties
      const html = _panelInstructionsMarkup;

      await tester.pumpWidget(_wrap(PaymentInstructionsHtml(html: html)));
      await tester.pump();

      final tables = tester.allRenderObjects
          .where((o) => o.runtimeType.toString().contains('Table'))
          .whereType<RenderBox>()
          .toList();

      //counted from the markup rather than written down, because a school
      //editing its own instructions must not fail this test — what it checks is
      //that every table in the content reaches the screen
      final tablesInMarkup = '<table'.allMatches(html.toLowerCase()).length;
      expect(tablesInMarkup, greaterThan(0));
      expect(tables, hasLength(tablesInMarkup));

      //every table in the fixture has at least four rows, so none of them can
      //legitimately be one line tall. A table laid out shorter than its rows
      //need does not clip — it paints them over whatever follows, which is how
      //the editor's leftover table landed on top of the payment details.
      for (final table in tables) {
        expect(
          table.size.height,
          greaterThan(60),
          reason: 'table laid out at ${table.size} is collapsed',
        );
      }

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'keeps the bold header the markup asks for instead of '
        'restyling it', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PaymentInstructionsHtml(
            html: '<table><thead><tr><th>Field</th><th>Details</th></tr>'
                '</thead><tbody><tr><td>Bank Name</td>'
                '<td>State Bank of India</td></tr></tbody></table>',
          ),
        ),
      );
      await tester.pump();

      //`th` is bold per the html spec, and the school sees it bold in the
      //editor — the app must not flatten it back to the body weight
      final header = tester.widget<RichText>(
        find
            .descendant(
              of: find.byType(PaymentInstructionsHtml),
              matching: find.byType(RichText),
            )
            .first,
      );
      expect(header.text.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('renders nothing for an unusable image source', (tester) async {
      await tester.pumpWidget(
        _wrap(const PaymentInstructionsHtml(html: '<img src="">')),
      );
      await tester.pump();

      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('withEditorTableDefaults', () {
    test('gives a bare table the grid the editor shows', () {
      final result = PaymentInstructionsHtml.withEditorTableDefaults(
        '<table><tbody><tr><td>a</td></tr></tbody></table>',
      );

      expect(result, contains('border="1"'));
      expect(result, contains('cellpadding="6"'));
      expect(result, contains('border-collapse: collapse'));
    });

    test('leaves a table that chose its own presentation alone', () {
      //this is the shape the editor writes when the school sets table
      //properties by hand
      final result = PaymentInstructionsHtml.withEditorTableDefaults(
        '<table style="border-collapse: collapse; width: 64.1379%;" '
        'border="1"><tbody><tr><td>a</td></tr></tbody></table>',
      );

      expect(result, contains('width: 64.1379%'));
      //not doubled up
      expect('border="1"'.allMatches(result).length, 1);
      expect('border-collapse'.allMatches(result).length, 1);
    });

    test('respects a school that deliberately turned borders off', () {
      final result = PaymentInstructionsHtml.withEditorTableDefaults(
        '<table border="0"><tbody><tr><td>a</td></tr></tbody></table>',
      );

      expect(result, contains('border="0"'));
      expect(result, isNot(contains('border="1"')));
    });

    test('does not touch anything that is not a table', () {
      const html = '<p>BANK DETAILS</p><img src="x">';

      expect(PaymentInstructionsHtml.withEditorTableDefaults(html), html);
    });
  });
}
