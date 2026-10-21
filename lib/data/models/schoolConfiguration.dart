import 'package:eschool/data/models/paymentGateway.dart';
import 'package:eschool/data/models/schoolSettings.dart';
import 'package:eschool/data/models/semesterDetails.dart';
import 'package:eschool/data/models/sessionYear.dart';
import 'package:eschool/utils/systemModules.dart';

class SchoolConfiguration {
  final SessionYear sessionYear;
  final SchoolSettings schoolSettings;
  final SemesterDetails semesterDetails;
  final Map<String, String> enabledModules;
  final List<PaymentGeteway> enabledPaymentGateways;
  SchoolConfiguration(
      {required this.sessionYear,
      required this.semesterDetails,
      required this.schoolSettings,
      required this.enabledPaymentGateways,
      required this.enabledModules});

  static SchoolConfiguration fromJson(Map<String, dynamic> json) {
    return SchoolConfiguration(
      enabledPaymentGateways: ((json['payment_gateway'] ?? []) as List)
          .map((e) => PaymentGeteway.fromJson(Map.from(e ?? {})))
          .toList(),
      semesterDetails: SemesterDetails.fromJson(json['semester'] ?? {}),
      enabledModules: Map<String, String>.from(json['features'] ?? {}),
      schoolSettings: SchoolSettings.fromJson(
          json['settings'] is Map ? Map.from(json['settings']) : {}),
      sessionYear: SessionYear.fromJson(Map.from(json['session_year'] ?? {})),
    );
  }

  bool isAssignmentModuleEnabled() {
    return enabledModules.containsKey(assignmentManagementModuleId.toString());
  }

  ///[Gateways that can actually run a checkout]
  ///
  ///The backend returns manual payment inside the same `payment_gateway` list,
  ///so every gateway driven flow (pre payment tasks, the "pay using" sheet,
  ///[PaymentGatewayService]) must read this instead of
  ///[enabledPaymentGateways] — handing "Manual" to a gateway would look up an
  ///api key and an order that do not exist.
  List<PaymentGeteway> get onlinePaymentGateways =>
      enabledPaymentGateways.where((gateway) => !gateway.isManual).toList();

  ///[The manual payment configuration, or null when the school has not enabled it]
  PaymentGeteway? get manualPaymentGateway {
    for (var gateway in enabledPaymentGateways) {
      if (gateway.isManual) {
        return gateway;
      }
    }
    return null;
  }

  bool isOnlineFeePaymentEnable() {
    return onlinePaymentGateways.isNotEmpty;
  }

  ///[Whether the parent may pay the fee outside the app and upload a receipt]
  bool isManualFeePaymentEnable() {
    return manualPaymentGateway != null;
  }

  ///[Whether any payment route at all is open to the parent]
  ///
  ///Drives whether the fee screens show their pay section — a school with only
  ///manual payment enabled still has to reach the Pay Now button.
  bool isAnyFeePaymentEnable() {
    return isOnlineFeePaymentEnable() || isManualFeePaymentEnable();
  }
}
