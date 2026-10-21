/// One payment in a child's fee history, and — the same class — each fee line
/// inside it.
///
/// The endpoint returns one row per payment, with the fees it settled nested
/// under `compulsory_fees` / `optional_fees`. Paying an overdue installment
/// together with the current one is a single payment of two lines, and both
/// levels carry the same fields, so [items] holds the lines as transactions in
/// their own right.
///
/// A payload with no nested lists — the shape this endpoint used to return, one
/// row per fee — parses as a payment of one line and behaves exactly as before.
///
/// Covers every way a fee can be settled — a gateway payment, cash taken at the
/// office, or a manual transfer whose receipt the school has yet to approve —
/// so [status] is the field that says whether the money has actually landed.
class FeeTransaction {
  final int? id;

  ///["compulsory" or "optional"]
  final String? type;

  ///[What was paid for: a fee type, an installment name, or "Full Payment"]
  final String? feeName;

  final double? amount;
  final double? dueCharges;

  /// The fees this one payment settled. Empty on a fee line, and on the older
  /// one-row-per-fee shape.
  final List<FeeTransaction> items;

  /// The payment's own total, late fees included. Only a payment row has one;
  /// a fee line states [amount] and [dueCharges] separately.
  final double? totalAmount;

  ///["Compulsory Fees" or "Optional Fees"] — the payment's own wording for what
  ///it was for, where a fee line names the fee itself.
  final String? paymentType;

  ///[The school's reference for the payment, e.g. MANUAL-20260902-JZVLLI]
  final String? paymentReference;

  ///["Manual", "Online", "Cash"]
  final String? mode;

  ///["Pending", "Success", "Rejected"]
  final String? status;

  final String? date;
  final String? chequeNo;
  final int? paymentTransactionId;
  final String? notes;

  ///[Why a manual payment was rejected, when the school gave a reason]
  final String? reason;

  final String? createdAt;

  ///[Manual payment only] The receipt the parent uploaded. Present as soon as
  ///the payment is filed, unlike a gateway receipt which has to be fetched.
  final String? receiptUrl;

  FeeTransaction({
    this.id,
    this.type,
    this.feeName,
    this.amount,
    this.dueCharges,
    this.mode,
    this.status,
    this.date,
    this.chequeNo,
    this.paymentTransactionId,
    this.notes,
    this.reason,
    this.createdAt,
    this.receiptUrl,
    this.items = const [],
    this.totalAmount,
    this.paymentType,
    this.paymentReference,
  });

  FeeTransaction.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        type = json['type'] as String?,
        feeName = json['fee_name'] as String?,
        amount = double.tryParse((json['amount'] ?? 0).toString()) ?? 0.0,
        dueCharges =
            double.tryParse((json['due_charges'] ?? 0).toString()) ?? 0.0,
        //null when absent, so a fee line is never mistaken for a payment that
        //happens to total the same
        totalAmount = json['total_amount'] == null
            ? null
            : double.tryParse(json['total_amount'].toString()),
        paymentType = json['payment_type'] as String?,
        paymentReference = json['payment_reference'] as String?,
        //the fees this payment settled, in the order the endpoint sends them
        items = [
          ..._parseItems(json['compulsory_fees']),
          ..._parseItems(json['optional_fees']),
        ],
        mode = json['mode'] as String?,
        status = json['status'] as String?,
        date = json['date'] as String?,
        chequeNo = json['cheque_no'] as String?,
        paymentTransactionId = json['payment_transaction_id'] as int?,
        notes = json['notes'] as String?,
        reason = json['reason'] as String?,
        createdAt = json['created_at'] as String?,
        //the same url arrives twice — as `receipt_url`, and inside the `file`
        //object the panel attaches; either will do
        receiptUrl = (json['receipt_url'] as String?) ??
            ((json['file'] is Map)
                ? (json['file']['file_url'] as String?)
                : null);

  static List<FeeTransaction> _parseItems(dynamic value) => value is List
      ? value
          .map((e) => FeeTransaction.fromJson(
              Map<String, dynamic>.from((e ?? <String, dynamic>{}) as Map)))
          .toList()
      : const [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'fee_name': feeName,
        'amount': amount,
        'due_charges': dueCharges,
        'total_amount': totalAmount,
        'payment_type': paymentType,
        'payment_reference': paymentReference,
        'mode': mode,
        'status': status,
        'date': date,
        'cheque_no': chequeNo,
        'payment_transaction_id': paymentTransactionId,
        'notes': notes,
        'reason': reason,
        'created_at': createdAt,
        'receipt_url': receiptUrl,
        'compulsory_fees':
            items.where((e) => !e.isOptional).map((e) => e.toJson()).toList(),
        'optional_fees':
            items.where((e) => e.isOptional).map((e) => e.toJson()).toList(),
      };

  ///[Status is compared case insensitively — the fee endpoints capitalise it
  ///while the payment transaction endpoints do not]
  bool _statusIs(String value) =>
      (status ?? '').toLowerCase() == value.toLowerCase();

  /// Waiting on the school to verify a receipt. Nothing has been settled yet.
  bool get isPending => _statusIs('Pending');

  /// Turned down by the school.
  ///
  /// The backend records this as `Failed`; `Rejected` is accepted too so the
  /// app keeps working if that wording is ever adopted.
  bool get isRejected => _statusIs('Failed') || _statusIs('Rejected');

  bool get isSucceeded => _statusIs('Success');

  bool get isManual => (mode ?? '').toLowerCase() == 'manual';

  /// Whether a late fee was charged as part of this payment.
  bool get hasDueCharges => (dueCharges ?? 0.0) > 0.0;

  ///[Whether this payment settled more than one fee at once]
  bool get hasItems => items.isNotEmpty;

  /// What this payment actually took.
  ///
  /// A payment states its own total, which already carries every line's late
  /// fee. A fee line has to add its own: [amount] is the fee half of it and
  /// [dueCharges] the late fee charged with it.
  double get totalAmountPaid {
    if (totalAmount != null) {
      return totalAmount!;
    }
    if (hasItems) {
      return items.fold(0.0, (sum, item) => sum + item.totalAmountPaid);
    }
    return (amount ?? 0.0) + (dueCharges ?? 0.0);
  }

  ///[Late fees charged across every fee this payment settled]
  double get totalDueCharges => hasItems
      ? items.fold(0.0, (sum, item) => sum + (item.dueCharges ?? 0.0))
      : (dueCharges ?? 0.0);

  ///[Whether this settled an optional fee rather than a compulsory one]
  bool get isOptional =>
      (type ?? '').toLowerCase() == 'optional' ||
      (paymentType ?? '').toLowerCase().contains('optional');

  /// Which side of the fee this payment was for, in the wording the receipt
  /// endpoint expects.
  ///
  /// A payment row carries no `type` of its own — it says `payment_type`
  /// ("Compulsory Fees") instead, and its lines carry the plain word — so this
  /// reads whichever is there rather than defaulting blind to compulsory and
  /// asking for the wrong receipt.
  String get receiptType {
    final own = (type ?? '').toLowerCase();
    if (own == 'compulsory' || own == 'optional') {
      return own;
    }
    if (isOptional) {
      return 'optional';
    }
    if (hasItems) {
      return items.first.receiptType;
    }
    return 'compulsory';
  }

  /// What to head the payment with.
  ///
  /// A payment settling one fee is named after it, the way the history read
  /// before payments were grouped. Settling several, no single fee name will
  /// do, so it takes the payment's own wording — the fees themselves are then
  /// listed beneath it.
  String get displayName {
    final own = (feeName ?? '').trim();
    if (own.isNotEmpty) {
      return own;
    }
    if (items.length == 1) {
      return items.first.displayName;
    }
    return (paymentType ?? '').trim();
  }

  ///[Whether the parent's own uploaded receipt can be shown]
  bool get hasUploadedReceipt => (receiptUrl ?? '').trim().isNotEmpty;

  /// The school's reason for refusing the payment, wherever it was recorded.
  ///
  /// A refusal can be written against the payment or against the fees inside
  /// it, and the reason is the whole point of coming back to this screen, so
  /// both levels are read rather than only the outer one.
  String? get rejectionReason => _firstNonEmpty((e) => e.reason);

  ///[Which cheque this was, read from either level the same way]
  String? get chequeNumber => _firstNonEmpty((e) => e.chequeNo);

  /// The first non-empty value of [field] on this payment or, failing that, on
  /// one of the fees it settled.
  String? _firstNonEmpty(String? Function(FeeTransaction) field) {
    for (final candidate in [this, ...items]) {
      final value = (field(candidate) ?? '').trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}
