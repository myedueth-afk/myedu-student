class SubjectWiseReport {
  final DiaryReport? diaryReport;
  final OfflineExamReport? offlineExamReport;
  final OnlineExamReport? onlineExamReport;
  final AssignmentReport? assignmentReport;

  SubjectWiseReport({
    this.diaryReport,
    this.offlineExamReport,
    this.onlineExamReport,
    this.assignmentReport,
  });

  factory SubjectWiseReport.fromJson(Map<String, dynamic> json) {
    return SubjectWiseReport(
      diaryReport: json['diary_report'] != null
          ? DiaryReport.fromJson(json['diary_report'])
          : null,
      offlineExamReport: json['offline_exam_report'] != null
          ? OfflineExamReport.fromJson(json['offline_exam_report'])
          : null,
      onlineExamReport: json['online_exam_report'] != null
          ? OnlineExamReport.fromJson(json['online_exam_report'])
          : null,
      assignmentReport: json['assignment_report'] != null
          ? AssignmentReport.fromJson(json['assignment_report'])
          : null,
    );
  }
}

class DiaryReport {
  final DiarySummary? summary;
  final List<DiaryCategory>? topPositiveCategories;
  final List<DiaryCategory>? topNegativeCategories;

  DiaryReport({
    this.summary,
    this.topPositiveCategories,
    this.topNegativeCategories,
  });

  factory DiaryReport.fromJson(Map<String, dynamic> json) {
    return DiaryReport(
      summary: json['summary'] != null
          ? DiarySummary.fromJson(json['summary'])
          : null,
      topPositiveCategories: json['top_positive_categories'] != null
          ? (json['top_positive_categories'] as List)
              .map((e) => DiaryCategory.fromJson(e))
              .toList()
          : [],
      topNegativeCategories: json['top_negative_categories'] != null
          ? (json['top_negative_categories'] as List)
              .map((e) => DiaryCategory.fromJson(e))
              .toList()
          : [],
    );
  }
}

class DiarySummary {
  final int? totalEntries;
  final int? positiveCount;
  final int? negativeCount;

  DiarySummary({this.totalEntries, this.positiveCount, this.negativeCount});

  factory DiarySummary.fromJson(Map<String, dynamic> json) {
    return DiarySummary(
      totalEntries: json['total_entries'],
      positiveCount: json['positive_count'],
      negativeCount: json['negative_count'],
    );
  }
}

class DiaryCategory {
  final String? categoryName;
  final int? count;
  final dynamic percentage;

  DiaryCategory({this.categoryName, this.count, this.percentage});

  factory DiaryCategory.fromJson(Map<String, dynamic> json) {
    return DiaryCategory(
      categoryName: json['category_name'],
      count: json['count'],
      percentage: json['percentage'],
    );
  }
}

class OfflineExamReport {
  final OfflineExamSummary? summary;
  final List<OfflineExamPerformance>? bestPerformance;
  final List<OfflineExamPerformance>? weakPerformance;

  OfflineExamReport({
    this.summary,
    this.bestPerformance,
    this.weakPerformance,
  });

  factory OfflineExamReport.fromJson(Map<String, dynamic> json) {
    return OfflineExamReport(
      summary: json['summary'] != null
          ? OfflineExamSummary.fromJson(json['summary'])
          : null,
      bestPerformance: json['best_performance'] != null
          ? (json['best_performance'] as List)
              .map((e) => OfflineExamPerformance.fromJson(e))
              .toList()
          : [],
      weakPerformance: json['weak_performance'] != null
          ? (json['weak_performance'] as List)
              .map((e) => OfflineExamPerformance.fromJson(e))
              .toList()
          : [],
    );
  }
}

class OfflineExamSummary {
  final dynamic obtainedMarks;
  final dynamic totalMarks;
  final dynamic percentage;

  OfflineExamSummary({this.obtainedMarks, this.totalMarks, this.percentage});

  factory OfflineExamSummary.fromJson(Map<String, dynamic> json) {
    return OfflineExamSummary(
      obtainedMarks: json['obtained_marks'],
      totalMarks: json['total_marks'],
      percentage: json['percentage'],
    );
  }
}

class OfflineExamPerformance {
  final String? examName;
  final String? examDate;
  final dynamic obtainedMarks;
  final dynamic totalMarks;
  final String? grade;

  OfflineExamPerformance({
    this.examName,
    this.examDate,
    this.obtainedMarks,
    this.totalMarks,
    this.grade,
  });

  factory OfflineExamPerformance.fromJson(Map<String, dynamic> json) {
    return OfflineExamPerformance(
      examName: json['exam_name'],
      examDate: json['exam_date'],
      obtainedMarks: json['obtained_marks'],
      totalMarks: json['total_marks'],
      grade: json['grade'],
    );
  }
}

class OnlineExamReport {
  final OnlineExamSummary? summary;
  final List<OnlineExamPerformance>? bestPerformance;
  final List<OnlineExamPerformance>? weakPerformance;

  OnlineExamReport({
    this.summary,
    this.bestPerformance,
    this.weakPerformance,
  });

  factory OnlineExamReport.fromJson(Map<String, dynamic> json) {
    return OnlineExamReport(
      summary: json['summary'] != null
          ? OnlineExamSummary.fromJson(json['summary'])
          : null,
      bestPerformance: json['best_performance'] != null
          ? (json['best_performance'] as List)
              .map((e) => OnlineExamPerformance.fromJson(e))
              .toList()
          : [],
      weakPerformance: json['weak_performance'] != null
          ? (json['weak_performance'] as List)
              .map((e) => OnlineExamPerformance.fromJson(e))
              .toList()
          : [],
    );
  }
}

class OnlineExamSummary {
  final int? completedExams;
  final int? missedExams;
  final int? totalExams;

  OnlineExamSummary({this.completedExams, this.missedExams, this.totalExams});

  factory OnlineExamSummary.fromJson(Map<String, dynamic> json) {
    return OnlineExamSummary(
      completedExams: json['completed_exams'],
      missedExams: json['missed_exams'],
      totalExams: json['total_exams'],
    );
  }
}

class OnlineExamPerformance {
  final String? examName;
  final dynamic obtainedMarks;
  final dynamic totalMarks;

  OnlineExamPerformance({this.examName, this.obtainedMarks, this.totalMarks});

  factory OnlineExamPerformance.fromJson(Map<String, dynamic> json) {
    return OnlineExamPerformance(
      examName: json['exam_name'],
      obtainedMarks: json['obtained_marks'],
      totalMarks: json['total_marks'],
    );
  }
}

class AssignmentReport {
  final AssignmentStatistics? statistics;
  final AssignmentPoints? points;

  AssignmentReport({this.statistics, this.points});

  factory AssignmentReport.fromJson(Map<String, dynamic> json) {
    return AssignmentReport(
      statistics: json['statistics'] != null
          ? AssignmentStatistics.fromJson(json['statistics'])
          : null,
      points: json['points'] != null
          ? AssignmentPoints.fromJson(json['points'])
          : null,
    );
  }
}

class AssignmentStatistics {
  final int? totalAssignments;
  final int? accepted;
  final int? inReview;
  final int? pending;
  final int? rejected;

  AssignmentStatistics({
    this.totalAssignments,
    this.accepted,
    this.inReview,
    this.pending,
    this.rejected,
  });

  factory AssignmentStatistics.fromJson(Map<String, dynamic> json) {
    return AssignmentStatistics(
      totalAssignments: json['total_assignments'],
      accepted: json['accepted'],
      // Older backends sent this count as `submitted`
      inReview: json['in_review'] ?? json['submitted'],
      pending: json['pending'],
      rejected: json['rejected'],
    );
  }
}

class AssignmentPoints {
  final dynamic totalPoints;
  final dynamic obtainedPoints;
  final dynamic percentage;

  AssignmentPoints({this.totalPoints, this.obtainedPoints, this.percentage});

  factory AssignmentPoints.fromJson(Map<String, dynamic> json) {
    return AssignmentPoints(
      totalPoints: json['total_points'],
      obtainedPoints: json['obtained_points'],
      percentage: json['percentage'],
    );
  }
}
