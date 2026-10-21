class StudentProfileExtraDetails {
  final int? id;
  final int? studentId;
  final int? formFieldId;
  final String? data;
  final int? schoolId;
  final FormField? formField;
  final String? fileUrl;

  StudentProfileExtraDetails({
    this.id,
    this.studentId,
    this.formFieldId,
    this.data,
    this.schoolId,
    this.formField,
    this.fileUrl,
  });

  StudentProfileExtraDetails copyWith(
      {int? id,
      int? studentId,
      int? formFieldId,
      String? data,
      int? schoolId,
      FormField? formField,
      String? fileUrl}) {
    return StudentProfileExtraDetails(
        id: id ?? this.id,
        studentId: studentId ?? this.studentId,
        formFieldId: formFieldId ?? this.formFieldId,
        data: data ?? this.data,
        schoolId: schoolId ?? this.schoolId,
        formField: formField ?? this.formField,
        fileUrl: fileUrl ?? this.fileUrl);
  }

  StudentProfileExtraDetails.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        studentId = json['student_id'] as int?,
        formFieldId = json['form_field_id'] as int?,
        data = json['data'] as String?,
        formField = FormField.fromJson(Map.from(json['form_field'] ?? {})),
        schoolId = json['school_id'] as int?,
        fileUrl = json['file_url'] as String?;

  Map<String, dynamic> toJson() => {
        'id': id,
        'student_id': studentId,
        'form_field_id': formFieldId,
        'data': data,
        'school_id': schoolId,
        'form_field': formField?.toJson(),
        'file_url': fileUrl,
      };
}

//
class FormField {
  final int? id;
  final String? name;
  final String? type;

  FormField({
    this.id,
    this.name,
    this.type,
  });

  FormField copyWith({
    int? id,
    String? name,
    String? type,
  }) {
    return FormField(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
    );
  }

  FormField.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        name = json['name'] as String?,
        type = json['type'] as String?;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'type': type};
}
