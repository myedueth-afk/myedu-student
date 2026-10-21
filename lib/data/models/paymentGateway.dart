import 'package:eschool/utils/constants.dart';

class PaymentGeteway {
  final int? id;
  final String? paymentMethod;
  final String? apiKey;
  final String? secretKey;
  final String? currencyCode;
  final String? paymentLink;

  ///[Manual payment only] Panel-authored instructions for paying outside the
  ///app. May contain HTML, so it is rendered rather than printed.
  final String? details;

  ///[Manual payment only] Bank account the parent should transfer the fee to.
  final String? bankName;
  final String? accountName;
  final String? accountNo;

  ///[Manual payment only] Absolute url of the image the school wants shown
  ///alongside the account details — normally a payment QR code.
  final String? file;

  PaymentGeteway({
    this.id,
    this.paymentMethod,
    this.apiKey,
    this.secretKey,
    this.currencyCode,
    this.paymentLink,
    this.details,
    this.bankName,
    this.accountName,
    this.accountNo,
    this.file,
  });

  PaymentGeteway copyWith({
    int? id,
    String? paymentMethod,
    String? apiKey,
    String? secretKey,
    String? currencyCode,
    String? paymentLink,
    String? details,
    String? bankName,
    String? accountName,
    String? accountNo,
    String? file,
  }) {
    return PaymentGeteway(
      id: id ?? this.id,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      apiKey: apiKey ?? this.apiKey,
      secretKey: secretKey ?? this.secretKey,
      currencyCode: currencyCode ?? this.currencyCode,
      paymentLink: paymentLink ?? this.paymentLink,
      details: details ?? this.details,
      bankName: bankName ?? this.bankName,
      accountName: accountName ?? this.accountName,
      accountNo: accountNo ?? this.accountNo,
      file: file ?? this.file,
    );
  }

  PaymentGeteway.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        paymentMethod = json['payment_method'] as String?,
        apiKey = json['api_key'] as String?,
        secretKey = json['secret_key'] as String?,
        currencyCode = json['currency_code'] as String?,
        paymentLink = json['payment_link'] as String?,
        details = json['details'] as String?,
        bankName = json['bank_name'] as String?,
        accountName = json['account_name'] as String?,
        accountNo = json['account_no'] as String?,
        file = json['file'] as String?;

  Map<String, dynamic> toJson() => {
        'id': id,
        'payment_method': paymentMethod,
        'api_key': apiKey,
        'secret_key': secretKey,
        'currency_code': currencyCode,
        'payment_link': paymentLink,
        'details': details,
        'bank_name': bankName,
        'account_name': accountName,
        'account_no': accountNo,
        'file': file,
      };

  ///[Manual payment is listed as a gateway but never processed as one]
  bool get isManual => paymentMethod == manualPaymentMethodKey;
}
