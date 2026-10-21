/// Everything the manual fee payment screen needs to describe *what* is being
/// paid, carried across the route in one object instead of a loose argument map.
///
/// The screen itself only reads [payableAmount] today — the rest is the payment
/// context the submit endpoint will need, kept together here so wiring that
/// endpoint up is a change in one place rather than a new route argument each
/// time.
class ManualFeePaymentArguments {
  final int childId;
  final int feeId;

  /// True when the compulsory tab raised this payment, false for optional fees.
  final bool compulsoryFee;

  /// Optional fee ids the parent ticked. Empty for a compulsory payment.
  final List<int> optionalFeeIds;

  /// Installment ids covered by this payment. Empty when the whole fee is being
  /// paid in one go.
  final List<int> installmentIds;

  /// Advance the parent chose to put towards future installments.
  final double advanceAmount;

  /// What the fee screen worked out as due, used to pre-fill the amount field.
  final double payableAmount;

  const ManualFeePaymentArguments({
    required this.childId,
    required this.feeId,
    required this.compulsoryFee,
    required this.payableAmount,
    this.optionalFeeIds = const [],
    this.installmentIds = const [],
    this.advanceAmount = 0.0,
  });
}
