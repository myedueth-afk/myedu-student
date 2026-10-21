import 'package:eschool/data/models/diaryCategory.dart';
import 'package:eschool/data/models/studentDiaryResponse.dart';
import 'package:eschool/utils/api.dart';
import 'package:flutter/material.dart';

class DiaryRepository {
  Future<StudentDiaryResponse> getDiaries({
    int? studentId,
    int? page,
    int? classSectionId,
    int? sessionYearId,
    int? diaryCategoryId,
    int? subjectId,
    String? search,
    String? sort,
  }) async {
    try {
      final result = await Api.get(
        url: Api.getDiaries,
        useAuthToken: true,
        queryParameters: {
          if (studentId != null) 'student_id': studentId,
          if (page != null) 'page': page,
          if (classSectionId != null) 'class_section_id': classSectionId,
          if (sessionYearId != null) 'session_year_id': sessionYearId,
          if (diaryCategoryId != null) 'diary_category_id': diaryCategoryId,
          if (subjectId != null) 'subject_id': subjectId,
          if (search != null && search.isNotEmpty) 'search': search,
          if (sort != null && sort.isNotEmpty) 'sort': sort,
        },
      );

      return StudentDiaryResponse.fromJson(Map.from(result['data'] ?? {}));
    } catch (e, st) {
      debugPrint(e.toString());
      debugPrint(st.toString());
      throw ApiException(e.toString());
    }
  }

  /// Fetch diary categories for students
  Future<List<DiaryCategory>> getStudentDiaryCategories() async {
    try {
      final result = await Api.get(
        url: Api.getStudentDiaryCategories,
        useAuthToken: true,
      );

      final List<dynamic> categoriesData = result['data'] ?? [];
      return categoriesData
          .map((category) => DiaryCategory.fromJson(Map.from(category ?? {})))
          .toList();
    } catch (e, st) {
      debugPrint("Error fetching student diary categories: $e");
      debugPrint("Stack trace: $st");
      throw ApiException(e.toString());
    }
  }

  /// Fetch diary categories for parents
  Future<List<DiaryCategory>> getParentDiaryCategories({
    required int childId,
  }) async {
    try {
      final result = await Api.get(
        url: Api.getParentDiaryCategories,
        useAuthToken: true,
        queryParameters: {
          'child_id': childId,
        },
      );

      final List<dynamic> categoriesData = result['data'] ?? [];
      return categoriesData
          .map((category) => DiaryCategory.fromJson(Map.from(category ?? {})))
          .toList();
    } catch (e, st) {
      debugPrint("Error fetching parent diary categories: $e");
      debugPrint("Stack trace: $st");
      throw ApiException(e.toString());
    }
  }
}
