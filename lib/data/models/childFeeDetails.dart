import 'package:eschool/data/models/classFeeType.dart';
import 'package:eschool/data/models/advanceFee.dart';
import 'package:eschool/data/models/classDetails.dart';
import 'package:eschool/data/models/compulsoryPaidFee.dart';
import 'package:eschool/data/models/feeDiscount.dart';
import 'package:eschool/data/models/installment.dart';
import 'package:eschool/data/models/paidFeeDetails.dart';
import 'package:eschool/data/models/sessionYear.dart';
import 'package:eschool/utils/labelKeys.dart';

class ChildFeeDetails {
  final int? id;
  final String? name;
  final String? dueDate;
  final double? dueCharges;
  final double? dueChargesInPercentage;
  final int? classId;
  final int? schoolId;
  final int? sessionYearId;
  final String? createdAt;
  final String? updatedAt;
  final double? minimumInstallmentAmount;
  final bool? includeFeeInstallments;
  final double? totalCompulsoryFees;
  final double? totalOptionalFees;
  final double? dueChargesAmount;
  final List<ClassFeeType>? compulsoryFees;
  final List<ClassFeeType>? optionalFees;
  final List<ClassFeeType>? fees;
  final List<PaidFeeDetails>? paidFees;
  final List<Installment>? installments;
  final SessionYear? sessionYear;
  final ClassDetails? classDetails;
  final bool? isOverdue;

  /// Discount / relief records applied to this fee (compulsory and/or optional).
  final List<FeeDiscount>? existingDiscounts;

  /// Total discount amount across all scopes as computed by the backend.
  final double? totalDiscountAmount;

  /// Net payable amount after discount (only sent for installment enabled fees).
  final double? netPayableAmount;

  /// Original fee amount before discount (only sent for installment enabled fees).
  final double? originalFeeAmount;

  /// Pending amount after discount and payments (installment enabled fees).
  final double? pendingAmount;

  /// Fee money the school has booked against this fee, late fees excluded —
  /// those arrive separately as [totalDuePaidAmount].
  ///
  /// Left null rather than defaulted to zero when the backend omits it, so
  /// [paidFeeAmount] can tell "nothing paid" from "not told" and fall back to
  /// adding up the payment rows.
  final double? totalPaidAmount;

  ///[Late fees the school has actually collected against this fee]
  final double? totalDuePaidAmount;

  /// The backend's own view of where this fee stands: `Unpaid`, `Success` or
  /// `Failed` (a manual receipt the school refused).
  ///
  /// Parsed but not yet what the screens display — see [getFeePaymentStatus].
  final String? status;

  ChildFeeDetails({
    this.dueChargesAmount,
    this.isOverdue,
    this.existingDiscounts,
    this.totalDiscountAmount,
    this.netPayableAmount,
    this.originalFeeAmount,
    this.pendingAmount,
    this.totalPaidAmount,
    this.totalDuePaidAmount,
    this.status,
    this.id,
    this.name,
    this.dueDate,
    this.dueCharges,
    this.classId,
    this.schoolId,
    this.sessionYearId,
    this.createdAt,
    this.updatedAt,
    this.minimumInstallmentAmount,
    this.includeFeeInstallments,
    this.totalCompulsoryFees,
    this.totalOptionalFees,
    this.compulsoryFees,
    this.optionalFees,
    this.fees,
    this.paidFees,
    this.installments,
    this.classDetails,
    this.sessionYear,
    this.dueChargesInPercentage,
  });

  ChildFeeDetails copyWith({
    int? id,
    double? dueChargesAmount,
    String? name,
    bool? isOverdue,
    String? dueDate,
    double? dueCharges,
    int? classId,
    int? schoolId,
    int? sessionYearId,
    String? createdAt,
    String? updatedAt,
    double? minimumInstallmentAmount,
    bool? includeFeeInstallments,
    double? totalCompulsoryFees,
    double? totalOptionalFees,
    List<ClassFeeType>? compulsoryFees,
    List<ClassFeeType>? optionalFees,
    List<ClassFeeType>? fees,
    List<PaidFeeDetails>? paidFees,
    List<Installment>? installments,
    SessionYear? sessionYear,
    ClassDetails? classDetails,
    double? dueChargesInPercentage,
    List<FeeDiscount>? existingDiscounts,
    double? totalDiscountAmount,
    double? netPayableAmount,
    double? originalFeeAmount,
    double? pendingAmount,
    double? totalPaidAmount,
    double? totalDuePaidAmount,
    String? status,
  }) {
    return ChildFeeDetails(
      isOverdue: isOverdue ?? this.isOverdue,
      dueChargesAmount: dueChargesAmount ?? this.dueChargesAmount,
      existingDiscounts: existingDiscounts ?? this.existingDiscounts,
      totalDiscountAmount: totalDiscountAmount ?? this.totalDiscountAmount,
      netPayableAmount: netPayableAmount ?? this.netPayableAmount,
      originalFeeAmount: originalFeeAmount ?? this.originalFeeAmount,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      totalPaidAmount: totalPaidAmount ?? this.totalPaidAmount,
      totalDuePaidAmount: totalDuePaidAmount ?? this.totalDuePaidAmount,
      status: status ?? this.status,
      classDetails: classDetails ?? this.classDetails,
      sessionYear: sessionYear ?? this.sessionYear,
      id: id ?? this.id,
      name: name ?? this.name,
      dueDate: dueDate ?? this.dueDate,
      dueCharges: dueCharges ?? this.dueCharges,
      classId: classId ?? this.classId,
      schoolId: schoolId ?? this.schoolId,
      sessionYearId: sessionYearId ?? this.sessionYearId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      minimumInstallmentAmount:
          minimumInstallmentAmount ?? this.minimumInstallmentAmount,
      includeFeeInstallments:
          includeFeeInstallments ?? this.includeFeeInstallments,
      totalCompulsoryFees: totalCompulsoryFees ?? this.totalCompulsoryFees,
      totalOptionalFees: totalOptionalFees ?? this.totalOptionalFees,
      compulsoryFees: compulsoryFees ?? this.compulsoryFees,
      optionalFees: optionalFees ?? this.optionalFees,
      fees: fees ?? this.fees,
      paidFees: paidFees ?? this.paidFees,
      installments: installments ?? this.installments,
      dueChargesInPercentage:
          dueChargesInPercentage ?? this.dueChargesInPercentage,
    );
  }

  ChildFeeDetails.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        isOverdue = json['is_overdue'] as bool?,
        dueChargesAmount =
            double.parse((json['due_charges_amount'] ?? 0).toString()),
        name = json['name'] as String?,
        dueDate = json['due_date'] as String?,
        dueCharges = double.parse((json['due_charges'] ?? 0).toString()),
        dueChargesInPercentage =
            double.parse((json['due_charges_in_percentage'] ?? 0).toString()),
        classId = json['class_id'] as int?,
        schoolId = json['school_id'] as int?,
        sessionYearId = json['session_year_id'] as int?,
        createdAt = json['created_at'] as String?,
        updatedAt = json['updated_at'] as String?,
        minimumInstallmentAmount =
            double.parse((json['minimum_installment_amount'] ?? 0).toString()),
        includeFeeInstallments = json['include_fee_installments'] as bool?,
        totalCompulsoryFees =
            double.parse((json['total_compulsory_fees'] ?? 0).toString()),
        compulsoryFees = ((json['compulsory_fees'] ?? []) as List)
            .map((e) => ClassFeeType.fromJson(Map.from(e ?? {})))
            .toList(),
        optionalFees = ((json['optional_fees'] ?? []) as List)
            .map((e) => ClassFeeType.fromJson(Map.from(e ?? {})))
            .toList(),
        fees = ((json['fees_class_type'] ?? []) as List)
            .map((e) => ClassFeeType.fromJson(Map.from(e ?? {})))
            .toList(),
        paidFees = ((json['fees_paid'] ?? []) as List)
            .map((e) => PaidFeeDetails.fromJson(Map.from(e ?? {})))
            .toList(),
        installments = ((json['installments'] ?? []) as List)
            .map((e) => Installment.fromJson(Map.from(e ?? {})))
            .toList(),
        sessionYear =
            SessionYear.fromJson(Map.from(json['session_year'] ?? {})),
        classDetails = ClassDetails.fromJson(Map.from(json['class'] ?? {})),
        existingDiscounts = ((json['existing_discounts'] ?? []) as List)
            .map((e) => FeeDiscount.fromJson(Map.from(e ?? {})))
            .toList(),
        totalDiscountAmount =
            double.parse((json['total_discount_amount'] ?? 0).toString()),
        netPayableAmount = json['net_payable_amount'] == null
            ? null
            : double.parse(json['net_payable_amount'].toString()),
        originalFeeAmount = json['original_fee_amount'] == null
            ? null
            : double.parse(json['original_fee_amount'].toString()),
        status = json['status'] as String?,
        pendingAmount = json['pending_amount'] == null
            ? null
            : double.parse(json['pending_amount'].toString()),
        totalPaidAmount = json['total_paid_amount'] == null
            ? null
            : double.parse(json['total_paid_amount'].toString()),
        totalDuePaidAmount = json['total_due_paid_amount'] == null
            ? null
            : double.parse(json['total_due_paid_amount'].toString()),
        totalOptionalFees =
            double.parse((json['total_optional_fees'] ?? 0).toString());

  Map<String, dynamic> toJson() => {
        'id': id,
        'is_overdue': isOverdue,
        'name': name,
        'due_date': dueDate,
        'due_charges': dueCharges,
        'class_id': classId,
        'school_id': schoolId,
        'session_year_id': sessionYearId,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'minimum_installment_amount': minimumInstallmentAmount,
        'include_fee_installments': includeFeeInstallments,
        'total_compulsory_fees': totalCompulsoryFees,
        'total_optional_fees': totalOptionalFees,
        'compulsory_fees': compulsoryFees?.map((e) => e.toJson()).toList(),
        'optional_fees': optionalFees?.map((e) => e.toJson()).toList(),
        'fees_class_type': fees?.map((e) => e.toJson()).toList(),
        'fees_paid': paidFees?.map((e) => e.toJson()).toList(),
        'installments': installments?.map((e) => e.toJson()).toList(),
        'class': classDetails?.toJson(),
        'session_year': sessionYear?.toJson(),
        'due_charges_amount': dueChargesAmount,
        'due_charges_in_percentage': dueChargesInPercentage,
        'existing_discounts':
            existingDiscounts?.map((e) => e.toJson()).toList(),
        'total_discount_amount': totalDiscountAmount,
        'net_payable_amount': netPayableAmount,
        'original_fee_amount': originalFeeAmount,
        'pending_amount': pendingAmount,
        'total_paid_amount': totalPaidAmount,
        'total_due_paid_amount': totalDuePaidAmount,
        'status': status,
      };

  /// The most recent manual payment filed against this fee, whatever became of
  /// it, or null when none was.
  ///
  /// Only the newest one decides what the screen says: a parent who was
  /// rejected and has since sent a fresh receipt is waiting again, not still
  /// rejected. Ordered by id, which the backend assigns in sequence.
  /// [compulsory] picks which side of the fee to look at. A manual payment is
  /// filed against compulsory fees or optional ones — they are separate
  /// endpoints, and the backend records them under `type` accordingly — so a
  /// receipt refused on one has nothing to say about the other, and must not
  /// surface on its tab.
  /// Modes the parent puts through a payment gateway themselves.
  ///
  /// Everything else — a receipt filed in the app, a cheque, cash at the office
  /// — is money the school takes by hand and can therefore explain when it does
  /// not arrive. Written as what to leave out rather than what to include, so a
  /// mode the school adds later is covered without another change here.
  static const Set<String> _gatewayModes = {'online'};

  ({int id, String status, String? reason, String mode})? _latestPayment({
    required bool compulsory,
    bool schoolSettledOnly = false,
  }) {
    ({int id, String status, String? reason, String mode})? latest;

    for (var paidFee in paidFees ?? []) {
      final payments = compulsory
          ? (paidFee.compulsoryPaidFees ?? [])
          : (paidFee.optionalPaidFees ?? []);

      for (var payment in payments) {
        final String mode = ((payment.mode as String?) ?? '').toLowerCase();
        if (schoolSettledOnly && _gatewayModes.contains(mode)) {
          continue;
        }

        //the two payment lists hold different types, so the fields are read
        //dynamically and narrowed here
        final record = (
          id: (payment.id as int?) ?? 0,
          status: ((payment.status as String?) ?? '').toLowerCase(),
          reason: payment.reason as String?,
          mode: mode,
        );

        if (latest == null || record.id > latest.id) {
          latest = record;
        }
      }
    }

    return latest;
  }

  /// True while a payment on this side of the fee is still waiting on the
  /// school.
  ///
  /// The backend records such a payment straight away — with an amount, and a
  /// `fees_paid` row — but marks it `Pending`, because nothing has actually
  /// been received until the school confirms it. Anything that reads as "paid"
  /// has to account for that or the fee looks settled while the money is still
  /// unverified.
  ///
  /// Every mode counts, not just the receipts filed through the app. A cheque
  /// the school is waiting to clear commits the same money, and offering to pay
  /// again while it is outstanding invites the parent to pay twice.
  bool hasPendingPayment({required bool compulsory}) =>
      _latestPayment(compulsory: compulsory)?.status == 'pending';

  /// How to announce money that is with the school, on a fee list card that has
  /// no compulsory/optional tabs to say which side it belongs to. Null when
  /// nothing is waiting.
  ///
  /// The scope matters because the card's status line is the *compulsory*
  /// settlement — `is_fully_paid`, see [getFeePaymentStatus] — so a fee whose
  /// compulsory side is settled reads "Paid" while an optional payment is still
  /// unconfirmed. An unscoped "Under Review" next to that "Paid" reads as a
  /// contradiction; naming the optional side turns the two into one sentence:
  /// the fee is paid, and an optional extra is with the school.
  ///
  /// Compulsory wins when both sides are waiting: the unscoped label already
  /// covers the whole fee, and the status line will not be claiming "Paid".
  String? paymentUnderReviewLabelKey() {
    if (hasPendingPayment(compulsory: true)) {
      return underReviewKey;
    }
    return hasOptionalPaymentUnderReview() ? optionalUnderReviewKey : null;
  }

  /// True while money sent for an optional fee is waiting on the school.
  ///
  /// Asked two ways, because neither is complete on its own. The latest payment
  /// row on the optional side is all the fee list can go on — its payload
  /// carries the payments but not necessarily the optional fee catalog. Asking
  /// fee by fee catches what that misses: optional fees are picked and paid one
  /// at a time, so a later approved payment for Sports does not settle a GYM
  /// receipt still sitting with the school.
  bool hasOptionalPaymentUnderReview() =>
      hasPendingPayment(compulsory: false) ||
      (optionalFees ?? []).any(
        (optionalFee) =>
            !(optionalFee.isPaid ?? false) &&
            isOptionalFeePending(optionalFeeId: optionalFee.id ?? 0),
      );

  /// True while a payment sent for this one optional fee is waiting on the
  /// school.
  ///
  /// Matched by `fees_class_id`, the way [optionalPaidDate] matches. Optional
  /// fees are chosen and paid one at a time, each with its own payment row, so
  /// a receipt sent for Sports says nothing about whether GYM has been paid.
  bool isOptionalFeePending({required int optionalFeeId}) {
    for (final paidFee in paidFees ?? []) {
      for (final payment in paidFee.optionalPaidFees ?? []) {
        if (payment.feesClassId == optionalFeeId &&
            ((payment.status as String?) ?? '').toLowerCase() == 'pending') {
          return true;
        }
      }
    }

    return false;
  }

  /// True while there is an optional fee the parent could still pay for.
  ///
  /// One that is already settled cannot be paid again, and one whose payment is
  /// with the school must not be paid twice — but anything else remains
  /// payable, however many of its neighbours are waiting.
  bool hasPayableOptionalFee() {
    return (optionalFees ?? []).any(
      (optionalFee) =>
          !(optionalFee.isPaid ?? false) &&
          !isOptionalFeePending(optionalFeeId: optionalFee.id ?? 0),
    );
  }

  /// How the payment that is waiting on the school was made — `manual`,
  /// `cheque`, `cash`, `online` — so the screen can say so in its own words.
  ///
  /// Null when nothing is waiting.
  String? pendingPaymentMode({required bool compulsory}) {
    final latest = _latestPayment(compulsory: compulsory);
    return latest?.status == 'pending' ? latest?.mode : null;
  }

  /// True when the last payment the school handled on this side of the fee
  /// came back refused, and the fee is still owed.
  ///
  /// Rejection arrives as `Failed`; `rejected` is accepted too in case that
  /// wording is ever adopted.
  ///
  /// Every way the school takes money by hand counts, not only a receipt filed
  /// through the app: a bounced cheque leaves the parent owing the money
  /// exactly as a refused receipt does, and the school has a reason for it
  /// either way. A declined card does not count — that failure is transient,
  /// the school has nothing to explain, and the payment flow reports it as it
  /// happens rather than leaving a banner on the fee.
  ///
  /// A settled fee reports no rejection. The school can refuse a receipt and
  /// then take the money another way — cash at the office is the common one —
  /// which leaves the refusal sitting behind a fee that is fully paid. Telling
  /// the parent their last transaction was rejected at that point is both
  /// wrong, since a later one succeeded, and useless, since there is nothing
  /// left to pay. The record stays on the payment history, where it reads in
  /// order alongside the payment that settled the fee.
  bool hasRejectedPayment({required bool compulsory}) {
    if (getFeePaymentStatus() == paidKey) {
      return false;
    }

    final status = _latestPayment(
      compulsory: compulsory,
      schoolSettledOnly: true,
    )?.status;
    return status == 'failed' || status == 'rejected';
  }

  /// The school's own words for why the last manual payment was refused.
  ///
  /// Null when the last payment was not rejected, or when the school gave no
  /// reason — the screen falls back to a plain statement in that case rather
  /// than inventing an explanation on the school's behalf.
  String? rejectedPaymentReason({required bool compulsory}) {
    if (!hasRejectedPayment(compulsory: compulsory)) {
      return null;
    }

    final reason = (_latestPayment(
              compulsory: compulsory,
              schoolSettledOnly: true,
            )?.reason ??
            '')
        .trim();
    return reason.isEmpty ? null : reason;
  }

  String getFeePaymentStatus() {
    if (paidFees?.isEmpty ?? true) {
      return pendingKey;
    }

    final paidFee = paidFees!.first;

    //settled in full, including a fee cleared entirely by a discount — that
    //books nothing yet is still paid, so this is checked before the amount
    if (paidFee.isFullyPaid == 1) {
      return paidKey;
    }

    //A manual payment gets a `fees_paid` row the moment it is filed, but the
    //row books nothing until the school approves it — and if the school turns
    //it down, it never will. Reading a zero row as "partially paid" tells the
    //parent money has landed when none has. Keyed on the amount rather than on
    //the status, so it holds however the backend labels an unapproved payment
    //(Pending today, Failed once rejected).
    if ((paidFee.amount ?? 0.0) <= 0.0) {
      return pendingKey;
    }

    return partiallyPaidKey;
  }

  /// Where the optional side of this fee stands, on its own terms.
  ///
  /// [getFeePaymentStatus] answers for the fee the parent owes, which is the
  /// compulsory one — `is_fully_paid` is set once that side is settled and says
  /// nothing about optional extras. Stating it above the optional rows has the
  /// summary claim "Paid" over a list of fees marked "Under Review", so the
  /// optional tab asks this instead and the two agree.
  ///
  /// Null when the school defined no optional fees: there is nothing on this
  /// side to have a status, and inventing one would be worse than saying
  /// nothing.
  String? getOptionalFeePaymentStatus() {
    final optionalFees = this.optionalFees ?? [];
    if (optionalFees.isEmpty) {
      return null;
    }

    if (optionalFees.every((optionalFee) => optionalFee.isPaid ?? false)) {
      return paidKey;
    }

    //money already sent outranks what is left unpicked: it is the one thing on
    //this side the parent cannot act on, and the rows below say the same
    if (hasOptionalPaymentUnderReview()) {
      return underReviewKey;
    }

    return optionalFees.any((optionalFee) => optionalFee.isPaid ?? false)
        ? partiallyPaidKey
        : pendingKey;
  }

  bool isGivenOptionalFeePaid({required int optionalFeeId}) {
    if ((paidFees ?? []).isEmpty) {
      return false;
    }

    return paidFees!.first.optionalPaidFees!
        .where((element) => element.id == optionalFeeId)
        .toList()
        .isNotEmpty;
  }

  bool isFeeOverDue() {
    return isOverdue ?? false;
  }

  double getTotalCompulsoryAmountWithDue() {
    return (dueChargesAmount ?? 0.0) + (totalCompulsoryFees ?? 0.0);
  }

  // ----------------------------------------------------------------------------
  // What has actually been paid
  //
  // A late fee is money the parent handed over, not an annotation on the fee.
  // The backend keeps the two apart — `total_paid_amount` and
  // `total_due_paid_amount` — so anything adding up to "what I paid" has to put
  // them back together.
  // ----------------------------------------------------------------------------

  ///[Compulsory payment rows the school has actually settled]
  Iterable<CompulsoryPaidFee> _settledCompulsoryPayments() =>
      _compulsoryPayments().where((payment) => payment.isSettled);

  /// Fee money already collected on the compulsory side, late fees excluded.
  ///
  /// The backend's figure is preferred: it booked the money, and it accounts
  /// for advances the payment rows carry separately. Summing the rows is the
  /// fallback for a payload that omits it.
  double paidFeeAmount() {
    if (totalPaidAmount != null) {
      return totalPaidAmount!;
    }

    return _settledCompulsoryPayments()
        .fold(0.0, (sum, payment) => sum + (payment.amount ?? 0.0));
  }

  ///[Late fees already collected on this fee]
  double paidDueChargesAmount() {
    if (totalDuePaidAmount != null) {
      return totalDuePaidAmount!;
    }

    return _settledCompulsoryPayments()
        .fold(0.0, (sum, payment) => sum + (payment.dueCharges ?? 0.0));
  }

  /// Everything handed over against this fee: the fee money and the late fees
  /// on top of it. This — not [paidFeeAmount] — is "what I paid".
  double totalAmountPaid() => paidFeeAmount() + paidDueChargesAmount();

  bool hasPaidAnyAmount() => totalAmountPaid() > 0.0;

  /// Late fees this fee has attracted that are still owed.
  ///
  /// [inInstallmentMode] is the screen's decision (the toggle, or a payment
  /// already made that way). The two routes carry the penalty differently: one
  /// charge per late installment, or a single charge on the whole fee.
  double outstandingDueChargesAmount({required bool inInstallmentMode}) {
    if (inInstallmentMode) {
      return unpaidInstallments()
          .fold(0.0, (sum, e) => sum + (e.dueChargeAmount ?? 0.0));
    }

    if (isCompulsoryFeeFullyPaid() || !isFeeOverDue()) {
      return 0.0;
    }

    return dueChargesAmount ?? 0.0;
  }

  /// Every late fee this fee has attracted — collected already, or still owed.
  ///
  /// What the fee breakdown states, so a penalty counts whether it is about to
  /// be paid or was paid months ago.
  double totalDueChargesAmount({required bool inInstallmentMode}) =>
      paidDueChargesAmount() +
      outstandingDueChargesAmount(inInstallmentMode: inInstallmentMode);

  double remainingFeeAmountToPay() {
    if (paidFees!.isEmpty) {
      return totalCompulsoryFees ?? 0.0;
    } else {
      double totalPaidAmount = 0.0;
      for (var compulsoryPaidAmount
          in (paidFees!.first.compulsoryPaidFees ?? [])) {
        totalPaidAmount =
            totalPaidAmount + (compulsoryPaidAmount.amount ?? 0.0);
      }
      //
      return (totalCompulsoryFees ?? 0.0) - totalPaidAmount;
    }
  }

  bool didUserPaidPreviousCompulsoryFeeInInstallment() {
    //If user has paid any amount using installment
    return (installments ?? []).isNotEmpty
        ? installments!.where((element) => (element.isPaid ?? false)).isNotEmpty
        : false;
  }

  ///[Every compulsory payment filed against this fee, whatever became of it]
  Iterable<CompulsoryPaidFee> _compulsoryPayments() sync* {
    for (final paidFee in paidFees ?? <PaidFeeDetails>[]) {
      yield* paidFee.compulsoryPaidFees ?? <CompulsoryPaidFee>[];
    }
  }

  /// Whether this fee is being settled in installments.
  ///
  /// Read from the payments themselves, because a payment filed against an
  /// installment commits the fee to that route whether or not the school has
  /// approved it yet. Asking only whether an installment is *paid* is what put
  /// the parent back on the full payment screen the moment they submitted a
  /// receipt for review: nothing was paid yet, so nothing said installments.
  ///
  /// A refused payment says nothing — see [isLive] — since that money never
  /// arrived and the choice is open again.
  bool isBeingPaidInInstallments() =>
      didUserPaidPreviousCompulsoryFeeInInstallment() ||
      _compulsoryPayments()
          .any((payment) => payment.isLive && payment.isInstallmentPayment);

  /// Whether the fee is still open to either route, full payment or
  /// installments — nothing standing against it has committed it to one.
  ///
  /// A refused payment commits nothing, so the parent chooses again.
  bool canStillChooseHowToPay() =>
      !_compulsoryPayments().any((payment) => payment.isLive);

  /// True while a payment sent for this one installment is waiting on the
  /// school, so its card can say so instead of showing it as still due.
  bool isInstallmentPending({required int installmentId}) =>
      _compulsoryPayments().any((payment) =>
          payment.installmentId == installmentId && payment.isPending);

  bool isCompulsoryFeeFullyPaid() {
    //If user has paid any amount using installment
    return (paidFees?.isNotEmpty ?? false)
        ? (paidFees!
            .where((element) => element.isFullyPaid == 1)
            .toList()
            .isNotEmpty)
        : false;
  }

  /// Unpaid installments that are already due and must be part of the current
  /// payment (shown as "Outstanding installment(s)" in the summary).
  ///
  /// An installment is due when:
  /// - its due date has passed. This is the rule that actually defines
  ///   "outstanding". A due charge is only a *consequence* of being late, and
  ///   it is 0 whenever the school configured no penalty for that installment,
  ///   so keying off the charge alone silently drops those installments from
  ///   the payment — taking their relief and their amount with them, and
  ///   leaving them to surface as payable "advance" instead, OR
  /// - the backend applied a due charge to it. It has already penalised the
  ///   installment, which is authoritative even if the due date is missing or
  ///   unreadable, OR
  /// - it comes before the installment currently being collected. Installments
  ///   are paid in order, so nothing before the current one can be skipped.
  List<Installment> dueInstallments() {
    final all = installments ?? [];

    // Position of the installment currently being collected: the backend
    // flagged current one, else the first unpaid one (nothing precedes it, so
    // the position rule adds nothing in that fallback case).
    final current = currentInstallment();
    final currentIndex =
        current.id == null ? -1 : all.indexWhere((e) => e.id == current.id);

    final due = <Installment>[];
    for (var i = 0; i < all.length; i++) {
      final installment = all[i];
      if (installment.isPaid ?? false) continue;
      // The current installment itself is handled as the "next" installment
      // of the payment, never as an outstanding one.
      if (installment.isCurrent ?? false) continue;
      final isPastDue = installment.isPastDueDate();
      final hasDueCharge = (installment.dueChargeAmount ?? 0.0) != 0.0;
      final isBeforeCurrent = currentIndex != -1 && i < currentIndex;
      if (isPastDue || hasDueCharge || isBeforeCurrent) {
        due.add(installment);
      }
    }
    return due;
  }

  bool hasAnyDueInstallment() {
    return dueInstallments().isNotEmpty;
  }

  List<Installment> unpaidInstallments() {
    return (installments ?? [])
        .where((element) => !(element.isPaid ?? false))
        .toList();
  }

  bool hasAnyUnpaidInstallment() {
    return unpaidInstallments().isNotEmpty;
  }

  bool hasOptionalFees() {
    return (optionalFees ?? []).isNotEmpty;
  }

  bool hasAnyUnpaidOptionlFee() {
    return (optionalFees ?? [])
        .where((e) => (e.isPaid ?? false) == false)
        .toList()
        .isNotEmpty;
  }

  List<Installment> paidInstallments() {
    return (installments ?? []).where((e) => (e.isPaid ?? false)).toList();
  }

  double remainingInstallmentAmount() {
    double remaining = 0.0;

    for (var installment in (installments ?? [])) {
      if (!(installment.isPaid ?? false)) {
        // For an unpaid installment the amount still owed is:
        //   max(0, installmentAmount - paidAmount - advancePaid - discount)
        //   + dueCharge
        // The due charge is a penalty that must be paid together with the
        // installment, so it has to be part of the remaining total — and it is
        // added AFTER clamping the fee part so excess relief can never swallow
        // it, matching how the payable amount is computed on the fee screen.
        final dueCharge = installment.isInstallmentOverdue()
            ? (installment.dueChargeAmount ?? 0.0)
            : 0.0;
        remaining += netRemainingOfInstallment(installment) + dueCharge;
      }
    }

    return remaining > 0.0 ? remaining : 0.0;
  }

  Installment currentInstallment() {
    final index = (installments ?? [])
        .indexWhere((element) => (element.isCurrent ?? false));
    if (index != -1) {
      return installments![index];
    }

    // If no installment is marked as current, find the first unpaid one
    final unpaidIndex =
        (installments ?? []).indexWhere((element) => !(element.isPaid ?? true));
    if (unpaidIndex != -1) {
      return installments![unpaidIndex];
    }

    return Installment.fromJson({});
  }

  // Get the next installment that needs to be paid (even if not marked as current)
  Installment nextUnpaidInstallment() {
    // First try to get the current installment if it's unpaid
    final current = currentInstallment();
    if (!(current.isPaid ?? true) && current.id != null) {
      return current;
    }

    // Otherwise find the first unpaid one
    final unpaidInstallments = this.unpaidInstallments();
    if (unpaidInstallments.isNotEmpty) {
      // Sort by ID to get them in order
      unpaidInstallments.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
      return unpaidInstallments.first;
    }

    return Installment.fromJson({});
  }

  /// Amount still owed on an installment after deducting any advance already
  /// paid toward it, clamped to >= 0 (before relief/discount and before due
  /// charges).
  ///
  /// This is the single source of truth for the "remaining minus advance"
  /// figure. Advance payments are tracked separately from paid_amount by the
  /// backend (the per-installment cards subtract them the same way), so they
  /// must be deducted here too or totals over-report what is still owed.
  double installmentAmountAfterAdvance(Installment installment) {
    final advancePaid =
        installmentTotalAdvancePaidAmount(installmentId: installment.id ?? 0);
    final base = installment.remainingAmount - advancePaid;
    return base > 0.0 ? base : 0.0;
  }

  /// Net amount still owed on an installment: [installmentAmountAfterAdvance]
  /// minus its relief/discount, clamped to >= 0.
  /// Due charges are intentionally excluded: they are penalties on the
  /// installments being paid now, not future fee amount an advance could go
  /// toward.
  double netRemainingOfInstallment(Installment installment) {
    final netRemaining = installmentAmountAfterAdvance(installment) -
        (installment.discountAmount ?? 0.0);
    return netRemaining > 0.0 ? netRemaining : 0.0;
  }

  /// Cached because [ChildFeeDetails] is immutable for a screen's lifetime and
  /// the value is read multiple times per rebuild.
  late final double _maximumAdvanceInstallmentAmount =
      _computeMaximumAdvanceInstallmentAmount();

  double maximumAdvanceInstallmentAmount() => _maximumAdvanceInstallmentAmount;

  double _computeMaximumAdvanceInstallmentAmount() {
    // Get next installment and due installments
    final nextInstallment = nextUnpaidInstallment();
    final dueInsts = dueInstallments();

    // Net remaining of the next installment (part of the current payment).
    // Must be net of its discount — the same basis as the unpaid total below —
    // otherwise the discount gets subtracted twice and the maximum advance
    // comes out too low by exactly the relief amount.
    double nextInstallmentAmount = 0.0;
    if (nextInstallment.id != null && !(nextInstallment.isPaid ?? false)) {
      // Check if this installment is already in due installments
      if (!dueInsts.any((inst) => inst.id == nextInstallment.id)) {
        nextInstallmentAmount = netRemainingOfInstallment(nextInstallment);
      }
    }

    // Net remaining of overdue installments (also part of the current payment).
    double outstandingNetAmount = 0.0;
    for (var installment in dueInsts) {
      outstandingNetAmount += netRemainingOfInstallment(installment);
    }

    // Sum up remaining amounts of all unpaid installments (net of their discounts)
    // This represents the total left to pay across all future installments.
    double totalUnpaidNetRemaining = 0.0;
    for (var installment in (installments ?? [])) {
      if (!(installment.isPaid ?? false)) {
        totalUnpaidNetRemaining += netRemainingOfInstallment(installment);
      }
    }

    // Advance = total unpaid net remaining minus what's already being paid
    // (next installment + outstanding installments)
    double advanceMax =
        totalUnpaidNetRemaining - nextInstallmentAmount - outstandingNetAmount;

    // Ensure the value is not negative
    return advanceMax > 0.0 ? advanceMax : 0.0;
  }

  String optionalPaidDate({required int optionalFeeId}) {
    // Search across ALL paidFees entries, not just .first.
    // A student may have multiple payment records for the same fee.
    for (final paidFee in (paidFees ?? [])) {
      final optionalFeeIndex = (paidFee.optionalPaidFees ?? [])
          .indexWhere((element) => element.feesClassId == optionalFeeId);
      if (optionalFeeIndex != -1) {
        return paidFee.optionalPaidFees![optionalFeeIndex].date ?? "";
      }
    }
    return "";
  }

  String installmentPaidDate({required int installmentId}) {
    final installmentIndex = (paidFees ?? []).isEmpty
        ? -1
        : (paidFees!.first.compulsoryPaidFees ?? [])
            .indexWhere((element) => element.installmentId == installmentId);
    if (installmentIndex == -1) {
      return "";
    }
    return paidFees!.first.compulsoryPaidFees![installmentIndex].date ?? "";
  }

  List<AdvanceFee> installmentAdvancePaidAmount({required int installmentId}) {
    final installmentIndex = (paidFees ?? []).isEmpty
        ? -1
        : (paidFees!.first.compulsoryPaidFees ?? [])
            .indexWhere((element) => element.installmentId == installmentId);
    if (installmentIndex == -1) {
      return [];
    }
    return paidFees!.first.compulsoryPaidFees![installmentIndex].advanceFees ??
        [];
  }

  /// Total advance amount already paid toward the given installment.
  double installmentTotalAdvancePaidAmount({required int installmentId}) {
    double total = 0.0;
    for (final advanceFee
        in installmentAdvancePaidAmount(installmentId: installmentId)) {
      total += advanceFee.amount ?? 0.0;
    }
    return total;
  }

  bool hasUserPaidFullFeeWithoutInstallment() {
    return isCompulsoryFeeFullyPaid() &&
        !didUserPaidPreviousCompulsoryFeeInInstallment();
  }

  String fullCompulsoryFeePaidDate() {
    return (paidFees ?? []).isEmpty
        ? ""
        : (paidFees!.first.compulsoryPaidFees ?? []).isEmpty
            ? ""
            : (paidFees!.first.compulsoryPaidFees!.first.date ?? '');
  }

  // ----------------------------------------------------------------------------
  // Discount / Fee relief helpers
  // ----------------------------------------------------------------------------

  /// Whether installments are enabled for this fee.
  bool isInstallmentEnabled() => includeFeeInstallments ?? false;

  // Discount lists are derived by filtering [existingDiscounts]. They are read
  // several times per rebuild, so they are cached (the model is immutable for
  // the screen's lifetime) to avoid re-allocating a filtered list each call.
  late final List<FeeDiscount> _allDiscounts = existingDiscounts ?? [];
  late final List<FeeDiscount> _compulsoryDiscounts =
      _allDiscounts.where((d) => d.isCompulsory).toList();
  late final List<FeeDiscount> _optionalDiscounts =
      _allDiscounts.where((d) => d.isOptional).toList();

  /// All discount records (any scope).
  List<FeeDiscount> allDiscounts() => _allDiscounts;

  bool hasAnyDiscount() => allDiscounts().isNotEmpty;

  /// Discount records scoped to the compulsory fee.
  List<FeeDiscount> compulsoryDiscounts() => _compulsoryDiscounts;

  /// Discount records scoped to the optional fee.
  List<FeeDiscount> optionalDiscounts() => _optionalDiscounts;

  /// Discounts relevant for the currently selected tab.
  List<FeeDiscount> discountsForScope({required bool compulsory}) =>
      compulsory ? compulsoryDiscounts() : optionalDiscounts();

  bool hasCompulsoryDiscount() => compulsoryDiscounts().isNotEmpty;

  bool hasOptionalDiscount() => optionalDiscounts().isNotEmpty;

  /// Total relief applied to the compulsory fee.
  double totalCompulsoryDiscountAmount() => compulsoryDiscounts()
      .fold(0.0, (sum, d) => sum + d.effectiveDiscountAmount);

  /// Total relief applied to the optional fee.
  double totalOptionalDiscountAmount() => optionalDiscounts()
      .fold(0.0, (sum, d) => sum + d.effectiveDiscountAmount);

  /// Net payable for the compulsory fee after relief (never negative).
  /// Prefers the backend computed value when available, otherwise derives it.
  double compulsoryNetPayableAmount() {
    final derived =
        (totalCompulsoryFees ?? 0.0) - totalCompulsoryDiscountAmount();
    final value = netPayableAmount ?? derived;
    return value > 0.0 ? value : 0.0;
  }

  /// Returns the discount amount applied to a specific installment, derived from
  /// the discount items mapped to that installment id. Falls back to the
  /// installment's own discount_amount via the caller when no item is found.
  double installmentDiscountAmount({required int installmentId}) {
    double amount = 0.0;
    for (final discount in compulsoryDiscounts()) {
      for (final item in discount.itemsForFeeTypeId(installmentId)) {
        if (item.isInstallment) {
          amount += item.discountAmount ?? 0.0;
        }
      }
    }
    return amount;
  }
}
