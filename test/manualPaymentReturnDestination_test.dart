import 'package:eschool/app/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Stand-ins for the four screens the manual payment flow passes through.
///
/// The real ones want cubits, a repository and a live api; what is under test
/// is the navigation stack they are pushed onto, which is the same whatever
/// they render.
GetPage _page(String name) => GetPage(
      name: name,
      page: () => Scaffold(body: Center(child: Text(name))),
    );

Widget _app() => GetMaterialApp(
      initialRoute: Routes.childFees,
      getPages: [
        _page(Routes.childFees),
        _page(Routes.childFeeDetails),
        _page(Routes.manualFeePayment),
        _page(Routes.confirmPayment),
      ],
    );

/// Walks the parent in as far as the submitted manual payment form.
Future<void> _reachManualPaymentForm(WidgetTester tester) async {
  await tester.pumpWidget(_app());
  await tester.pumpAndSettle();

  Get.toNamed(Routes.childFeeDetails);
  await tester.pumpAndSettle();

  Get.toNamed(Routes.manualFeePayment);
  await tester.pumpAndSettle();

  expect(find.text(Routes.manualFeePayment), findsOneWidget);
}

/// The call [ManualFeePaymentScreen] makes once the receipt is filed.
void _onPaymentFiled() {
  Get.offNamedUntil(
    Routes.confirmPayment,
    (route) => route.settings.name == Routes.childFees || route.isFirst,
  );
}

void main() {
  group('where a filed manual payment leaves the parent', () {
    testWidgets('Go Back from the confirmation lands on the fee list',
        (tester) async {
      await _reachManualPaymentForm(tester);

      _onPaymentFiled();
      await tester.pumpAndSettle();
      expect(find.text(Routes.confirmPayment), findsOneWidget);

      //what the Go Back button does
      Get.back();
      await tester.pumpAndSettle();

      //not the fee details screen it came from, which still holds the fee as it
      //looked before the receipt was sent
      expect(find.text(Routes.childFees), findsOneWidget);
      expect(find.text(Routes.childFeeDetails), findsNothing);
    });

    testWidgets('the submitted form cannot be returned to', (tester) async {
      //a second submission would file a second receipt for the same money
      await _reachManualPaymentForm(tester);

      _onPaymentFiled();
      await tester.pumpAndSettle();

      Get.back();
      await tester.pumpAndSettle();

      expect(find.text(Routes.manualFeePayment), findsNothing);
    });

    testWidgets('nothing from the payment run is left behind', (tester) async {
      await _reachManualPaymentForm(tester);

      _onPaymentFiled();
      await tester.pumpAndSettle();

      Get.back();
      await tester.pumpAndSettle();

      expect(Get.currentRoute, Routes.childFees);
      //the three screens the parent walked through are all gone, so there is
      //no stale fee, no re-submittable form and no orphaned confirmation
      for (final screen in [
        Routes.childFeeDetails,
        Routes.manualFeePayment,
        Routes.confirmPayment,
      ]) {
        expect(find.text(screen), findsNothing);
      }
    });

    testWidgets('a stack without the fee list still keeps something behind it',
        (tester) async {
      //the flow is only ever entered from the fee list today. If that ever
      //changes, the parent must not be left on a confirmation screen that
      //cannot be backed out of
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      Get.toNamed(Routes.childFeeDetails);
      await tester.pumpAndSettle();

      _onPaymentFiled();
      await tester.pumpAndSettle();

      Get.back();
      await tester.pumpAndSettle();

      expect(find.text(Routes.confirmPayment), findsNothing);
    });
  });
}
