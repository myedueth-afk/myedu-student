import 'package:eschool/data/models/subjectWiseReport.dart';
import 'package:eschool/ui/screens/reports/widgets/assignmentReportCard.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// The subject report API renamed the assignment `submitted` count to
/// `in_review`, and the report card now labels it "In-review".
void main() {
  // `assignment_report` from GET student/report?class_subject_id=75
  const reportJson = {
    'statistics': {
      'total_assignments': 6,
      'accepted': 1,
      'in_review': 2,
      'pending': 3,
      'rejected': 0,
    },
    'points': {
      'total_points': 3100,
      'obtained_points': 0,
      'percentage': 0,
    },
  };

  test('reads the in-review count from in_review', () {
    final stats = AssignmentReport.fromJson(reportJson).statistics!;

    expect(stats.totalAssignments, 6);
    expect(stats.accepted, 1);
    expect(stats.inReview, 2);
    expect(stats.pending, 3);
    expect(stats.rejected, 0);
  });

  test('still reads the legacy submitted count from older backends', () {
    final stats = AssignmentStatistics.fromJson({
      'total_assignments': 2,
      'submitted': 1,
    });

    expect(stats.inReview, 1);
  });

  test('prefers in_review when both keys are present', () {
    final stats = AssignmentStatistics.fromJson({
      'in_review': 4,
      'submitted': 9,
    });

    expect(stats.inReview, 4);
  });

  testWidgets('the card shows the in-review label with its count',
      (tester) async {
    Get.addTranslations({
      'en': {inReviewKey: 'In-review', submittedKey: 'Submitted'},
    });
    Get.locale = const Locale('en');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AssignmentReportCard(
              report: AssignmentReport.fromJson(reportJson),
              onViewAssignment: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('In-review : 2'), findsOneWidget);
    expect(find.textContaining('Submitted'), findsNothing);
  });
}
