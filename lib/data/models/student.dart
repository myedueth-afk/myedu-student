import 'package:eschool/data/models/childUserDetails.dart';
import 'package:eschool/data/models/classSection.dart';
import 'package:eschool/data/models/guardian.dart';
import 'package:eschool/data/models/school.dart';
import 'package:eschool/data/models/studentProfileExtraDetails.dart';

class Student {
  final int? id;
  final int? userId;
  final String? firstName;
  final String? lastName;
  final String? countryCode;
  final String? mobile;
  final String? gender;
  final String? image;
  final String? dob;
  final String? currentAddress;
  final String? permanentAddress;
  final int? status;
  final String? fcmId;
  final int? schoolId;
  final String? createdAt;
  final String? updatedAt;
  final ClassSection? classSection;
  final Guardian? guardian;
  final School? school;
  final int? sessionYearId;
  final int? rollNumber;
  final String? admissionNo;
  final String? admissionDate;
  final List<StudentProfileExtraDetails>? studentProfileExtraDetails;
  final ChildUserDetails? childUserDetails;

  Student(
      {this.id,
      this.firstName,
      this.userId,
      this.lastName,
      this.countryCode,
      this.mobile,
      this.gender,
      this.image,
      this.dob,
      this.currentAddress,
      this.permanentAddress,
      this.status,
      this.fcmId,
      this.schoolId,
      this.createdAt,
      this.updatedAt,
      this.classSection,
      this.guardian,
      this.school,
      this.admissionDate,
      this.admissionNo,
      this.rollNumber,
      this.sessionYearId,
      this.studentProfileExtraDetails,
      this.childUserDetails});

  Student copyWith(
      {int? id,
      String? firstName,
      String? lastName,
      String? countryCode,
      String? mobile,
      String? gender,
      String? image,
      String? dob,
      String? currentAddress,
      String? permanentAddress,
      int? status,
      String? fcmId,
      int? schoolId,
      String? createdAt,
      String? updatedAt,
      ClassSection? classSection,
      Guardian? guardian,
      School? school,
      String? admissionNo,
      String? admissionDate,
      int? rollNumber,
      int? sessionYearId,
      int? userId,
      List<StudentProfileExtraDetails>? studentProfileExtraDetails,
      ChildUserDetails? childUserDetails}) {
    return Student(
        userId: userId ?? this.userId,
        id: id ?? this.id,
        childUserDetails: childUserDetails ?? this.childUserDetails,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        countryCode: countryCode ?? this.countryCode,
        mobile: mobile ?? this.mobile,
        gender: gender ?? this.gender,
        image: image ?? this.image,
        dob: dob ?? this.dob,
        currentAddress: currentAddress ?? this.currentAddress,
        permanentAddress: permanentAddress ?? this.permanentAddress,
        status: status ?? this.status,
        fcmId: fcmId ?? this.fcmId,
        schoolId: schoolId ?? this.schoolId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        classSection: classSection ?? this.classSection,
        guardian: guardian ?? this.guardian,
        school: school ?? this.school,
        admissionDate: admissionDate ?? this.admissionDate,
        admissionNo: admissionNo ?? this.admissionNo,
        rollNumber: rollNumber ?? this.rollNumber,
        sessionYearId: sessionYearId ?? this.sessionYearId,
        studentProfileExtraDetails:
            studentProfileExtraDetails ?? this.studentProfileExtraDetails);
  }

  Student.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        childUserDetails =
            ChildUserDetails.fromJson(Map.from(json['user'] ?? {})),
        userId = json['user_id'] as int?,
        firstName = json['first_name'] as String?,
        lastName = json['last_name'] as String?,
        countryCode = json['country_code']?.toString(),
        mobile = json['mobile'] as String?,
        gender = json['gender'] as String?,
        image = json['image'] as String?,
        dob = json['dob'] as String?,
        currentAddress = json['current_address'] as String?,
        permanentAddress = json['permanent_address'] as String?,
        status = int.parse((json['status'] ?? 0).toString()),
        fcmId = json['fcm_id'] as String?,
        schoolId = json['school_id'] as int?,
        createdAt = json['created_at'] as String?,
        classSection =
            ClassSection.fromJson(Map.from(json['class_section'] ?? {})),
        guardian = Guardian.fromJson(Map.from(json['guardian'] ?? {})),
        school = School.fromJson(Map.from(json['school'] ?? {})),
        sessionYearId = json['session_year_id'] as int?,
        rollNumber = int.tryParse(json['roll_number']?.toString() ?? ''),
        admissionDate = json['admission_date'] as String?,
        admissionNo = json['admission_no'] as String?,
        studentProfileExtraDetails = ((json['extra_details'] ?? []) as List)
            .map((details) =>
                StudentProfileExtraDetails.fromJson(Map.from(details ?? {})))
            .toList(),
        updatedAt = json['updated_at'] as String?;

  Map<String, dynamic> toJson() => {
        'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'country_code': countryCode,
        'mobile': mobile,
        'gender': gender,
        'image': image,
        'dob': dob,
        'current_address': currentAddress,
        'permanent_address': permanentAddress,
        'status': status,
        'fcm_id': fcmId,
        'school_id': schoolId,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'class_section': classSection?.toJson(),
        'guardian': guardian?.toJson(),
        'school': school?.toJson(),
        'session_year_id': sessionYearId,
        'roll_number': rollNumber,
        'admission_date': admissionDate,
        'admission_no': admissionNo,
        'user_id': userId,
        'extra_details':
            studentProfileExtraDetails?.map((e) => e.toJson()).toList(),
        'user': childUserDetails?.toJson(),
      };

  String getFullName() {
    // Handle null values and return empty string if both are null/empty
    final first = firstName?.trim() ?? '';
    final last = lastName?.trim() ?? '';

    if (first.isEmpty && last.isEmpty) {
      return '';
    }

    return '$first $last'.trim();
  }

  @override
  String toString() {
    final name = getFullName();

    // Build class section string only if we have valid data
    final className = classSection?.classDetails?.name ?? '';
    final sectionName = classSection?.section?.name ?? '';

    // Only append class section if at least one of them is not empty
    if (className.isNotEmpty || sectionName.isNotEmpty) {
      return '$name - $className$sectionName';
    }

    // Return just the name if no class section data
    return name;
  }
}
