import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';

class Subject {
  final int? id;
  final String? name;
  final String? code;
  final String? bgColor;
  final String? image;
  final int? mediumId;
  final String? type;
  final int? schoolId;
  final String? createdAt;
  final String? updatedAt;
  final dynamic deletedAt;
  final int? classSubjectId;
  final String? nameWithType;

  String getSubjectName({required BuildContext context}) {
    // Return empty string if name is null or empty (for break periods)
    if (name == null || name!.isEmpty) {
      return '';
    }

    String translatedType =
        Utils.getTranslatedLabel(isPractial() ? practicalKey : theoryKey);

    return "($name - $translatedType)";
  }

  bool isPractial() => "Practical" == (type ?? "");

  Subject({
    this.id,
    this.name,
    this.code,
    this.bgColor,
    this.image,
    this.mediumId,
    this.type,
    this.schoolId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.classSubjectId,
    this.nameWithType,
  });

  Subject copyWith({
    int? id,
    String? name,
    String? code,
    String? bgColor,
    String? image,
    int? mediumId,
    String? type,
    int? schoolId,
    String? createdAt,
    String? updatedAt,
    dynamic deletedAt,
    int? classSubjectId,
    String? nameWithType,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      bgColor: bgColor ?? this.bgColor,
      image: image ?? this.image,
      mediumId: mediumId ?? this.mediumId,
      type: type ?? this.type,
      schoolId: schoolId ?? this.schoolId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      classSubjectId: classSubjectId ?? this.classSubjectId,
      nameWithType: nameWithType ?? this.nameWithType,
    );
  }

  Subject.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        name = _parseString(json['name']),
        code = _parseString(json['code']),
        bgColor = _parseString(json['bg_color']),
        image = _parseString(json['image']),
        mediumId = json['medium_id'] as int?,
        type = _parseString(json['type']),
        schoolId = json['school_id'] as int?,
        createdAt = _parseString(json['created_at']),
        updatedAt = _parseString(json['updated_at']),
        deletedAt = json['deleted_at'],
        classSubjectId = json['class_subject_id'] as int?,
        nameWithType = _parseString(json['name_with_type']);

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is List) {
      return value.isNotEmpty ? value.first.toString() : null;
    }
    return value.toString();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'bg_color': bgColor,
        'image': image,
        'medium_id': mediumId,
        'type': type,
        'school_id': schoolId,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
        'class_subject_id': classSubjectId,
        'name_with_type': nameWithType
      };

  bool hasSvgImage() {
    final imageUrlParts = (image ?? "").split(".");
    return imageUrlParts.last.toLowerCase() == "svg";
  }
}
