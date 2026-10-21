class SchoolSettings {
  final String? schoolName;
  final String? schoolEmail;
  final String? schoolPhone;
  final String? schoolTagline;
  final String? schoolAddress;
  final String? horizontalLogo;
  final String? verticalLogo;
  final String? timetableStartTime;
  final String? timetableEndTime;
  final String? timetableDuration;
  final String? autoRenewalPlan;
  final String? onlineExamTermsAndCondition;
  final String? currencyCode;
  final String? currencySymbol;
  final String? privacyPolicy;
  final String? termsCondition;
  final String? refundCancellation;

  SchoolSettings({
    this.schoolName,
    this.onlineExamTermsAndCondition,
    this.schoolEmail,
    this.schoolPhone,
    this.schoolTagline,
    this.schoolAddress,
    this.horizontalLogo,
    this.verticalLogo,
    this.timetableStartTime,
    this.timetableEndTime,
    this.timetableDuration,
    this.autoRenewalPlan,
    this.currencyCode,
    this.currencySymbol,
    this.privacyPolicy,
    this.termsCondition,
    this.refundCancellation,
  });

  SchoolSettings copyWith({
    String? schoolName,
    String? schoolEmail,
    String? schoolPhone,
    String? schoolTagline,
    String? schoolAddress,
    String? horizontalLogo,
    String? verticalLogo,
    String? timetableStartTime,
    String? timetableEndTime,
    String? timetableDuration,
    String? autoRenewalPlan,
    String? onlineExamTermsAndCondition,
    String? currencyCode,
    String? currencySymbol,
    String? privacyPolicy,
    String? termsCondition,
    String? refundCancellation,
  }) {
    return SchoolSettings(
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      onlineExamTermsAndCondition:
          onlineExamTermsAndCondition ?? this.onlineExamTermsAndCondition,
      schoolName: schoolName ?? this.schoolName,
      schoolEmail: schoolEmail ?? this.schoolEmail,
      schoolPhone: schoolPhone ?? this.schoolPhone,
      schoolTagline: schoolTagline ?? this.schoolTagline,
      schoolAddress: schoolAddress ?? this.schoolAddress,
      horizontalLogo: horizontalLogo ?? this.horizontalLogo,
      verticalLogo: verticalLogo ?? this.verticalLogo,
      timetableStartTime: timetableStartTime ?? this.timetableStartTime,
      timetableEndTime: timetableEndTime ?? this.timetableEndTime,
      timetableDuration: timetableDuration ?? this.timetableDuration,
      autoRenewalPlan: autoRenewalPlan ?? this.autoRenewalPlan,
      privacyPolicy: privacyPolicy ?? this.privacyPolicy,
      termsCondition: termsCondition ?? this.termsCondition,
      refundCancellation: refundCancellation ?? this.refundCancellation,
    );
  }

  SchoolSettings.fromJson(Map<String, dynamic> json)
      : schoolName = json['school_name'] as String?,
        onlineExamTermsAndCondition =
            json['online_exam_terms_condition'] as String?,
        schoolEmail = json['school_email'] as String?,
        schoolPhone = json['school_phone'] as String?,
        schoolTagline = json['school_tagline'] as String?,
        schoolAddress = json['school_address'] as String?,
        horizontalLogo = json['horizontal_logo'] as String?,
        verticalLogo = json['vertical_logo'] as String?,
        timetableStartTime = json['timetable_start_time'] as String?,
        timetableEndTime = json['timetable_end_time'] as String?,
        timetableDuration = json['timetable_duration'] as String?,
        currencyCode = json['currency_code'] as String?,
        currencySymbol = json['currency_symbol'] as String?,
        autoRenewalPlan = json['auto_renewal_plan'] as String?,
        privacyPolicy = json['privacy_policy'] as String?,
        termsCondition = json['terms_condition'] as String?,
        refundCancellation = json['refund_cancellation'] as String?;

  Map<String, dynamic> toJson() => {
        'school_name': schoolName,
        'school_email': schoolEmail,
        'school_phone': schoolPhone,
        'school_tagline': schoolTagline,
        'school_address': schoolAddress,
        'horizontal_logo': horizontalLogo,
        'vertical_logo': verticalLogo,
        'timetable_start_time': timetableStartTime,
        'timetable_end_time': timetableEndTime,
        'timetable_duration': timetableDuration,
        'auto_renewal_plan': autoRenewalPlan,
        'online_exam_terms_condition': onlineExamTermsAndCondition,
        'currency_code': currencyCode,
        'currency_symbol': currencySymbol,
        'privacy_policy': privacyPolicy,
        'terms_condition': termsCondition,
        'refund_cancellation': refundCancellation,
      };
}
