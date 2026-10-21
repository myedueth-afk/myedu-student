/// Represents a single fee discount / relief record returned inside the
/// `existing_discounts` list of the fee details API.
///
/// A discount can apply to either the compulsory or the optional part of a fee
/// (see [discountScope]). When the fee is paid in installments the backend also
/// breaks down how much of the discount is applied to each installment via the
/// [items] list. When installments are disabled the [items] list is usually
/// empty and the whole discount value applies to the fee directly.
class FeeDiscount {
  final int? id;
  final int? schoolId;
  final int? studentId;
  final int? feesId;

  /// Either `compulsory` or `optional`.
  final String? discountScope;
  final String? discountName;

  /// Either `fixed` or `percentage`.
  final String? discountType;

  /// Raw discount value as received from the API (stored as string e.g. "2000.00").
  /// For `fixed` it is the amount, for `percentage` it is the percentage value.
  final double? discountValue;
  final String? discountDate;
  final String? description;
  final int? createdBy;
  final String? createdAt;
  final String? updatedAt;
  final List<FeeDiscountItem> items;

  const FeeDiscount({
    this.id,
    this.schoolId,
    this.studentId,
    this.feesId,
    this.discountScope,
    this.discountName,
    this.discountType,
    this.discountValue,
    this.discountDate,
    this.description,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.items = const [],
  });

  FeeDiscount.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        schoolId = json['school_id'] as int?,
        studentId = json['student_id'] as int?,
        feesId = json['fees_id'] as int?,
        discountScope = json['discount_scope'] as String?,
        discountName = json['discount_name'] as String?,
        discountType = json['discount_type'] as String?,
        discountValue =
            double.tryParse((json['discount_value'] ?? 0).toString()) ?? 0.0,
        discountDate = json['discount_date'] as String?,
        description = json['description'] as String?,
        createdBy = json['created_by'] as int?,
        createdAt = json['created_at'] as String?,
        updatedAt = json['updated_at'] as String?,
        items = ((json['items'] ?? []) as List)
            .map((e) => FeeDiscountItem.fromJson(Map.from(e ?? {})))
            .toList();

  Map<String, dynamic> toJson() => {
        'id': id,
        'school_id': schoolId,
        'student_id': studentId,
        'fees_id': feesId,
        'discount_scope': discountScope,
        'discount_name': discountName,
        'discount_type': discountType,
        'discount_value': discountValue,
        'discount_date': discountDate,
        'description': description,
        'created_by': createdBy,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'items': items.map((e) => e.toJson()).toList(),
      };

  bool get isCompulsory => (discountScope ?? '').toLowerCase() == 'compulsory';

  bool get isOptional => (discountScope ?? '').toLowerCase() == 'optional';

  bool get isPercentage => (discountType ?? '').toLowerCase() == 'percentage';

  /// The concrete monetary discount amount for this record.
  ///
  /// When [items] are present (installment / optional breakdown) we sum the
  /// per-item discount amounts so the value is always accurate regardless of
  /// whether the discount is fixed or percentage based. When there are no items
  /// (e.g. installments disabled) we fall back to [discountValue], which for a
  /// fixed discount already represents the amount.
  double get effectiveDiscountAmount {
    if (items.isNotEmpty) {
      return items.fold(0.0, (sum, item) => sum + (item.discountAmount ?? 0.0));
    }
    return discountValue ?? 0.0;
  }

  /// Returns the items that affect a specific fee type id (installment id or
  /// optional fee id depending on [discountScope]).
  List<FeeDiscountItem> itemsForFeeTypeId(int feeTypeId) =>
      items.where((item) => item.feeTypeId == feeTypeId).toList();
}

/// A single line inside a [FeeDiscount.items] list describing how much of the
/// discount is applied to one installment / optional fee.
class FeeDiscountItem {
  final int? id;
  final int? feeDiscountId;

  /// Either `installment` or `optional`.
  final String? feeType;

  /// The id of the installment / optional fee this item maps to.
  final int? feeTypeId;
  final double? originalAmount;
  final double? discountAmount;
  final double? finalAmount;
  final String? createdAt;
  final String? updatedAt;

  const FeeDiscountItem({
    this.id,
    this.feeDiscountId,
    this.feeType,
    this.feeTypeId,
    this.originalAmount,
    this.discountAmount,
    this.finalAmount,
    this.createdAt,
    this.updatedAt,
  });

  FeeDiscountItem.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        feeDiscountId = json['fee_discount_id'] as int?,
        feeType = json['fee_type'] as String?,
        feeTypeId = json['fee_type_id'] as int?,
        originalAmount =
            double.tryParse((json['original_amount'] ?? 0).toString()) ?? 0.0,
        discountAmount =
            double.tryParse((json['discount_amount'] ?? 0).toString()) ?? 0.0,
        finalAmount =
            double.tryParse((json['final_amount'] ?? 0).toString()) ?? 0.0,
        createdAt = json['created_at'] as String?,
        updatedAt = json['updated_at'] as String?;

  Map<String, dynamic> toJson() => {
        'id': id,
        'fee_discount_id': feeDiscountId,
        'fee_type': feeType,
        'fee_type_id': feeTypeId,
        'original_amount': originalAmount,
        'discount_amount': discountAmount,
        'final_amount': finalAmount,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  bool get isInstallment => (feeType ?? '').toLowerCase() == 'installment';

  bool get isOptional => (feeType ?? '').toLowerCase() == 'optional';
}
