import 'package:eschool/data/models/assignment.dart';
import 'package:flutter_test/flutter_test.dart';

/// The assignments API moved an assignment's class section and class subject
/// into `assignment_commons` and now sends the top-level fields as null.
void main() {
  Map<String, dynamic> classSubject({
    required int id,
    required int subjectId,
    required String name,
    required String image,
  }) =>
      {
        'id': id,
        'class_id': 2,
        'subject_id': subjectId,
        'type': 'Compulsory',
        'subject_with_name': '$name - Theory',
        'subject': {
          'id': subjectId,
          'name': name,
          'code': null,
          'bg_color': '#b020e1',
          'image': image,
          'medium_id': 2,
          'type': 'Theory',
          'school_id': 629,
          'name_with_type': '$name - Theory',
        },
      };

  Map<String, dynamic> assignmentJson({
    dynamic topLevelClassSubject,
    int? topLevelClassSubjectId,
    int? topLevelClassSectionId,
    dynamic commons,
  }) =>
      {
        'id': 16,
        'class_section_id': topLevelClassSectionId,
        'class_subject_id': topLevelClassSubjectId,
        'name': 'sdfsdf',
        'instructions': 'sdfsdfsdf',
        'due_date': '2026/05/09 11:37 AM',
        'points': 500,
        'resubmission': 0,
        'extra_days_for_resubmission': null,
        'session_year_id': 1,
        'school_id': 629,
        'created_at': '2026/01/09 11:37 AM',
        'due_date_original': '05-09-2026 11:37 AM',
        'created_at_original': '01-09-2026 11:37 AM',
        'file': [],
        'class_subject': topLevelClassSubject,
        'submission': null,
        'assignment_commons': commons,
      };

  const mathsImage = 'https://example.com/storage/629/subject/maths.jpg';
  const opsImage = 'https://example.com/storage/629/subject/ops.jpg';

  test('subject, class subject and class section come from assignment_commons',
      () {
    final assignment = Assignment.fromJson(assignmentJson(commons: [
      {
        'id': 16,
        'assignment_id': 16,
        'class_section_id': 6,
        'class_subject_id': 75,
        'subject_with_name': 'Maths - Theory',
        'class_subject': classSubject(
          id: 75,
          subjectId: 7,
          name: 'Maths',
          image: mathsImage,
        ),
      },
    ]));

    expect(assignment.subject.id, 7);
    expect(assignment.subject.name, 'Maths');
    expect(assignment.subject.type, 'Theory');
    expect(assignment.subject.image, mathsImage);
    expect(assignment.subject.bgColor, '#b020e1');
    expect(assignment.subjectId, 75);
    expect(assignment.classSectionId, 6);
  });

  test('top-level class_subject still wins when the API sends it', () {
    final assignment = Assignment.fromJson(assignmentJson(
      topLevelClassSubjectId: 77,
      topLevelClassSectionId: 6,
      topLevelClassSubject: classSubject(
        id: 77,
        subjectId: 4,
        name: 'Operations Management',
        image: opsImage,
      ),
      commons: [
        {
          'class_section_id': 9,
          'class_subject_id': 75,
          'class_subject': classSubject(
            id: 75,
            subjectId: 7,
            name: 'Maths',
            image: mathsImage,
          ),
        },
      ],
    ));

    expect(assignment.subject.name, 'Operations Management');
    expect(assignment.subject.image, opsImage);
    expect(assignment.subjectId, 77);
    expect(assignment.classSectionId, 6);
  });

  test('skips commons without a subject so ids and subject stay paired', () {
    final assignment = Assignment.fromJson(assignmentJson(commons: [
      {'class_section_id': 3, 'class_subject_id': 11, 'class_subject': null},
      {
        'class_section_id': 6,
        'class_subject_id': 75,
        'class_subject': classSubject(
          id: 75,
          subjectId: 7,
          name: 'Maths',
          image: mathsImage,
        ),
      },
    ]));

    expect(assignment.subject.name, 'Maths');
    expect(assignment.subjectId, 75);
    expect(assignment.classSectionId, 6);
  });

  test('falls back to an empty subject when commons are missing or malformed',
      () {
    for (final commons in [null, <dynamic>[], 'unexpected', <dynamic>[42]]) {
      final assignment = Assignment.fromJson(assignmentJson(commons: commons));

      expect(assignment.subject.name, isNull, reason: 'commons: $commons');
      expect(assignment.subject.image, isNull, reason: 'commons: $commons');
      expect(assignment.subjectId, 0, reason: 'commons: $commons');
      expect(assignment.classSectionId, 0, reason: 'commons: $commons');
    }
  });

  test('a common without a subject still supplies its ids', () {
    final assignment = Assignment.fromJson(assignmentJson(commons: [
      {'class_section_id': 6, 'class_subject_id': 75, 'class_subject': null},
    ]));

    expect(assignment.subject.name, isNull);
    expect(assignment.subjectId, 75);
    expect(assignment.classSectionId, 6);
  });
}
