import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/authCubit.dart';
import 'package:eschool/cubits/schoolConfigurationCubit.dart';
import 'package:eschool/utils/constants.dart';
import 'package:eschool/utils/errorMessageKeysAndCodes.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Abstract interface for payment data providers
/// Any cubit that provides payment gateway data should implement this
abstract class PaymentDataProvider {
  String getRazorpayOrderId();
  String getStripePaymentClientSecret();
  String getFlutterwavePaymentLink();
  String getPaystackPaymentLink();
  String getChapaPaymentLink();
}

/// A service class that handles all payment gateway integrations
/// This class provides a centralized way to handle payments across the app
class PaymentGatewayService {
  final BuildContext context;
  final Razorpay _razorpay;
  final VoidCallback onPaymentComplete;
  final PaymentDataProvider paymentDataProvider;
  final SchoolConfigurationCubit schoolConfigCubit;
  final AuthCubit authCubit;

  PaymentGatewayService({
    required this.context,
    required Razorpay razorpay,
    required this.onPaymentComplete,
    required this.paymentDataProvider,
    required this.schoolConfigCubit,
    required this.authCubit,
  }) : _razorpay = razorpay {
    _initializeRazorpay();
  }

  /// Initialize Razorpay event listeners
  void _initializeRazorpay() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpayPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayPaymentError);
  }

  /// Navigate to confirm payment screen
  void _navigateToConfirmPaymentScreen() {
    Get.offNamed(Routes.confirmPayment);
  }

  /// Handle Razorpay payment success
  void _handleRazorpayPaymentSuccess(PaymentSuccessResponse response) {
    onPaymentComplete();
    _navigateToConfirmPaymentScreen();
  }

  /// Handle Razorpay payment error
  void _handleRazorpayPaymentError(PaymentFailureResponse response) {
    onPaymentComplete();
    _navigateToConfirmPaymentScreen();
  }

  /// Process payment with Razorpay
  /// [razorpayApiKey] - The API key for Razorpay
  Future<void> payWithRazorpay({required String razorpayApiKey}) async {
    try {
      final options = {
        'key': razorpayApiKey,
        'order_id': paymentDataProvider.getRazorpayOrderId(),
        'name': schoolConfigCubit
                .getSchoolConfiguration()
                .schoolSettings
                .schoolName ??
            '',
        'prefill': {
          'contact': authCubit.getParentDetails().mobile ?? "",
          'email': authCubit.getParentDetails().email ?? ""
        },
      };

      _razorpay.open(options);
    } catch (e) {
      onPaymentComplete();
      _navigateToConfirmPaymentScreen();
    }
  }

  /// Process payment with Stripe
  /// [stripePublishableKey] - The publishable key for Stripe
  Future<void> payWithStripe({required String stripePublishableKey}) async {
    try {
      Stripe.publishableKey = stripePublishableKey;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          billingDetailsCollectionConfiguration:
              BillingDetailsCollectionConfiguration(
            address: AddressCollectionMode.full,
            email: CollectionMode.always,
            name: CollectionMode.always,
            phone: CollectionMode.always,
          ),
          paymentIntentClientSecret:
              paymentDataProvider.getStripePaymentClientSecret(),
          style: ThemeMode.light,
          merchantDisplayName: schoolConfigCubit
                  .getSchoolConfiguration()
                  .schoolSettings
                  .schoolName ??
              '',
        ),
      );

      // Open payment sheet
      await Stripe.instance.presentPaymentSheet();

      onPaymentComplete();
      _navigateToConfirmPaymentScreen();
    } on StripeException catch (e) {
      // Payment cancelled by user
      if (e.error.code == FailureCode.Canceled) {
        onPaymentComplete();
        _navigateToConfirmPaymentScreen();
      }
    } on StripeConfigException catch (e) {
      if (kDebugMode) {
        debugPrint('Stripe Config Error: ${e.message}');
      }
      _showErrorSnackBar(Utils.getTranslatedLabel(
          ErrorMessageKeysAndCode.defaultErrorMessageKey));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Stripe Payment Error: ${e.toString()}');
      }
      _showErrorSnackBar(Utils.getTranslatedLabel(
          ErrorMessageKeysAndCode.defaultErrorMessageKey));
    }
  }

  /// Process payment with Flutterwave
  Future<void> payWithFlutterwave() async {
    try {
      final paymentLink = paymentDataProvider.getFlutterwavePaymentLink();

      if (kDebugMode) {
        debugPrint("Flutterwave payment link: $paymentLink");
      }

      if (paymentLink.isNotEmpty) {
        final result = await Get.toNamed(
          Routes.paymentWebview,
          arguments: {'paymentLink': paymentLink},
        );

        onPaymentComplete();
        if (result == true) {
          _navigateToConfirmPaymentScreen();
        } else {
          _navigateToConfirmPaymentScreen();
        }
      } else {
        if (kDebugMode) {
          debugPrint("Error: Empty payment link received from Flutterwave");
        }
        _showErrorSnackBar("Unable to get payment link. Please try again.");
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint("Error in payWithFlutterwave: $e");
        debugPrint("Stack trace: $stackTrace");
      }
      _showErrorSnackBar("Payment initialization failed. Please try again.");
    }
  }

  /// Process payment with Paystack
  Future<void> payWithPaystack() async {
    try {
      final paymentLink = paymentDataProvider.getPaystackPaymentLink();

      if (kDebugMode) {
        debugPrint("Paystack payment link: $paymentLink");
      }

      if (paymentLink.isNotEmpty) {
        final result = await Get.toNamed(
          Routes.paymentWebview,
          arguments: {'paymentLink': paymentLink},
        );

        onPaymentComplete();
        if (result == true) {
          _navigateToConfirmPaymentScreen();
        } else {
          _navigateToConfirmPaymentScreen();
        }
      } else {
        if (kDebugMode) {
          debugPrint("Error: Empty payment link received from Paystack");
        }
        _showErrorSnackBar("Unable to get payment link. Please try again.");
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint("Error in payWithPaystack: $e");
        debugPrint("Stack trace: $stackTrace");
      }
      _showErrorSnackBar("Payment initialization failed. Please try again.");
    }
  }

  /// Process payment with Chapa
  Future<void> payWithChapa() async {
    try {
      final paymentLink = paymentDataProvider.getChapaPaymentLink();

      if (kDebugMode) {
        debugPrint("Chapa payment link: $paymentLink");
      }

      if (paymentLink.isNotEmpty) {
        await Get.toNamed(
          Routes.paymentWebview,
          arguments: {'paymentLink': paymentLink},
        );

        onPaymentComplete();
        _navigateToConfirmPaymentScreen();
      } else {
        if (kDebugMode) {
          debugPrint("Error: Empty payment link received from Chapa");
        }
        _showErrorSnackBar("Unable to get payment link. Please try again.");
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint("Error in payWithChapa: $e");
        debugPrint("Stack trace: $stackTrace");
      }
      _showErrorSnackBar("Payment initialization failed. Please try again.");
    }
  }

  /// Handle pre-payment tasks listener
  /// This method determines which payment gateway to use based on the API response
  /// [state] - The state from any pre-payment tasks cubit
  /// [paymentMethodGetter] - Function to extract payment method from the state
  /// [apiKeyGetter] - Function to extract API key from the state
  /// [errorMessageGetter] - Function to extract error message from failure state
  void handlePrePaymentTasksListener({
    required dynamic state,
    required String Function(dynamic) paymentMethodGetter,
    required String Function(dynamic) apiKeyGetter,
    required String Function(dynamic) errorMessageGetter,
    required bool Function(dynamic) isFailureState,
    required bool Function(dynamic) isSuccessState,
  }) {
    if (isFailureState(state)) {
      _showErrorSnackBar(Utils.getErrorMessageFromErrorCode(
          context, errorMessageGetter(state)));
    } else if (isSuccessState(state)) {
      // Route to appropriate payment method based on the selected gateway
      final paymentMethod = paymentMethodGetter(state);

      if (paymentMethod == stripePaymentMethodKey) {
        payWithStripe(stripePublishableKey: apiKeyGetter(state));
      } else if (paymentMethod == razorpayPaymentMethodKey) {
        payWithRazorpay(razorpayApiKey: apiKeyGetter(state));
      } else if (paymentMethod == flutterwavePaymentMethodKey) {
        payWithFlutterwave();
      } else if (paymentMethod == paystackPaymentMethodKey) {
        payWithPaystack();
      } else if (paymentMethod == chapaPaymentMethodKey) {
        payWithChapa();
      }
    }
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    Utils.showCustomSnackBar(
      context: context,
      errorMessage: message,
      backgroundColor: Theme.of(context).colorScheme.error,
    );
  }

  /// Clean up resources
  void dispose() {
    _razorpay.clear();
  }
}
