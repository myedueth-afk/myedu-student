import 'package:eschool/utils/utils.dart';

class Installment {
  final int? id;
  final String? name;
  final String? dueDate;

  /// Human-readable due date returned by the backend (field: format_due_date).
  /// Example value: "13/03/2026".
  final String? formatDueDate;
  final double? dueCharges;
  final int? feesId;
  final int? sessionYearId;
  final int? schoolId;
  final String? createdAt;
  final String? updatedAt;
  final double? minimumAmount;
  final double? maximumAmount;
  final bool? isPaid;
  final double? dueChargeAmount;
  final bool? isCurrent;
  final double? installmentAmount;
  final double? paidAmount;

  /// Discount / relief applied to this specific installment.
  final double? discountAmount;

  /// Net payable for this installment after discount (installment_amount - discount).
  final double? netPayableAmount;

  /// Returns the remaining amount to be paid for this installment.
  /// Calculated as installmentAmount - paidAmount, clamped to >= 0.
  double get remainingAmount {
    final total = installmentAmount ?? 0.0;
    final paid = paidAmount ?? 0.0;
    final remaining = total - paid;
    return remaining > 0.0 ? remaining : 0.0;
  }

  Installment(
      {this.id,
      this.name,
      this.dueDate,
      this.formatDueDate,
      this.dueCharges,
      this.feesId,
      this.sessionYearId,
      this.schoolId,
      this.createdAt,
      this.updatedAt,
      this.minimumAmount,
      this.maximumAmount,
      this.isPaid,
      this.dueChargeAmount,
      this.isCurrent,
      this.installmentAmount,
      this.paidAmount,
      this.discountAmount,
      this.netPayableAmount});

  Installment copyWith(
      {int? id,
      String? name,
      String? dueDate,
      String? formatDueDate,
      double? dueCharges,
      int? feesId,
      int? sessionYearId,
      int? schoolId,
      String? createdAt,
      String? updatedAt,
      double? minimumAmount,
      double? maximumAmount,
      bool? isPaid,
      double? dueChargeAmount,
      bool? isCurrent,
      double? installmentAmount,
      double? paidAmount,
      double? discountAmount,
      double? netPayableAmount}) {
    return Installment(
        isCurrent: isCurrent,
        discountAmount: discountAmount ?? this.discountAmount,
        netPayableAmount: netPayableAmount ?? this.netPayableAmount,
        id: id ?? this.id,
        name: name ?? this.name,
        dueDate: dueDate ?? this.dueDate,
        formatDueDate: formatDueDate ?? this.formatDueDate,
        dueCharges: dueCharges ?? this.dueCharges,
        feesId: feesId ?? this.feesId,
        sessionYearId: sessionYearId ?? this.sessionYearId,
        schoolId: schoolId ?? this.schoolId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        minimumAmount: minimumAmount ?? this.minimumAmount,
        maximumAmount: maximumAmount ?? this.maximumAmount,
        isPaid: isPaid ?? this.isPaid,
        dueChargeAmount: dueChargeAmount ?? this.dueChargeAmount,
        installmentAmount: installmentAmount ?? this.installmentAmount,
        paidAmount: paidAmount ?? this.paidAmount);
  }

  Installment.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        name = json['name'] as String?,
        dueDate = json['due_date'] as String?,
        formatDueDate = json['format_due_date'] as String?,
        dueCharges = double.parse((json['due_charges'] ?? 0).toString()),
        feesId = json['fees_id'] as int?,
        sessionYearId = json['session_year_id'] as int?,
        schoolId = json['school_id'] as int?,
        createdAt = json['created_at'] as String?,
        updatedAt = json['updated_at'] as String?,
        minimumAmount = double.parse((json['minimum_amount'] ?? 0).toString()),
        maximumAmount = double.parse((json['maximum_amount'] ?? 0).toString()),
        isCurrent = json['is_current'] as bool?,
        dueChargeAmount =
            double.parse((json['due_charges_amount'] ?? 0).toString()),
        isPaid = json['is_paid'] as bool?,
        installmentAmount =
            double.parse((json['installment_amount'] ?? 0).toString()),
        paidAmount = double.parse((json['paid_amount'] ?? 0).toString()),
        discountAmount =
            double.parse((json['discount_amount'] ?? 0).toString()),
        netPayableAmount = json['net_payable_amount'] == null
            ? null
            : double.parse(json['net_payable_amount'].toString());

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'due_date': dueDate,
        'format_due_date': formatDueDate,
        'due_charges': dueCharges,
        'fees_id': feesId,
        'session_year_id': sessionYearId,
        'school_id': schoolId,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'minimum_amount': minimumAmount,
        'maximum_amount': maximumAmount,
        'is_paid': isPaid,
        'due_charges_amount': dueChargeAmount,
        'is_current': isCurrent,
        'installment_amount': installmentAmount,
        'paid_amount': paidAmount,
        'discount_amount': discountAmount,
        'net_payable_amount': netPayableAmount
      };

  /// Whether the backend has actually charged a late fee on this installment.
  ///
  /// This is NOT the same as "past its due date": a school can configure an
  /// installment with a zero due charge, and such an installment stays at 0
  /// forever no matter how late it is. Use this only to drive the due charge
  /// itself (the penalty row, the red amount); use [isPastDueDate] to decide
  /// whether the installment is still owed.
  bool isInstallmentOverdue() {
    return (dueChargeAmount ?? 0.0) != 0.0;
  }

  /// Whether this installment's due date has already passed.
  ///
  /// Compared date-only against today, so an installment due today is not yet
  /// past due — it is the one currently being collected, not an outstanding
  /// one. Returns false when the backend sent no due date or one that cannot
  /// be read, leaving the due charge and position rules to classify it.
  bool isPastDueDate() {
    final parsed = _parsedDueDate;
    if (parsed == null) {
      return false;
    }

    final today = DateTime.now();
    return DateTime(parsed.year, parsed.month, parsed.day)
        .isBefore(DateTime(today.year, today.month, today.day));
  }

  /// [dueDate] is the machine format ("2026-07-02"); [formatDueDate] is the
  /// display one ("02-07-2026"). Both are read so the value survives either
  /// field being absent, and [Utils.parseApiDate] handles both layouts.
  DateTime? get _parsedDueDate {
    for (final value in [dueDate, formatDueDate]) {
      if (value == null || value.isEmpty) continue;
      final parsed = Utils.parseApiDate(value);
      if (parsed != null) return parsed;
    }
    return null;
  }

  /// Whether this installment has any discount / relief applied to it.
  bool hasDiscount() => (discountAmount ?? 0.0) > 0.0;
}
