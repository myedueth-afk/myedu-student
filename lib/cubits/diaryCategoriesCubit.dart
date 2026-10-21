import 'package:eschool/data/models/diaryCategory.dart';
import 'package:eschool/data/repositories/diaryRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class DiaryCategoriesState {}

class DiaryCategoriesInitial extends DiaryCategoriesState {}

class DiaryCategoriesFetchInProgress extends DiaryCategoriesState {}

class DiaryCategoriesFetchSuccess extends DiaryCategoriesState {
  final List<DiaryCategory> categories;

  DiaryCategoriesFetchSuccess({required this.categories});
}

class DiaryCategoriesFetchFailure extends DiaryCategoriesState {
  final String errorMessage;

  DiaryCategoriesFetchFailure(this.errorMessage);
}

class DiaryCategoriesCubit extends Cubit<DiaryCategoriesState> {
  final DiaryRepository _diaryRepository = DiaryRepository();

  DiaryCategoriesCubit() : super(DiaryCategoriesInitial());

  /// Fetch categories for students
  void getStudentDiaryCategories() async {
    emit(DiaryCategoriesFetchInProgress());
    try {
      final categories = await _diaryRepository.getStudentDiaryCategories();
      emit(DiaryCategoriesFetchSuccess(categories: categories));
    } catch (e) {
      emit(DiaryCategoriesFetchFailure(e.toString()));
    }
  }

  /// Fetch categories for parents
  void getParentDiaryCategories({required int childId}) async {
    emit(DiaryCategoriesFetchInProgress());
    try {
      final categories = await _diaryRepository.getParentDiaryCategories(
        childId: childId,
      );
      emit(DiaryCategoriesFetchSuccess(categories: categories));
    } catch (e) {
      emit(DiaryCategoriesFetchFailure(e.toString()));
    }
  }

  /// Get category names for filter dropdown
  List<String> getCategoryNames() {
    if (state is DiaryCategoriesFetchSuccess) {
      final categories = (state as DiaryCategoriesFetchSuccess).categories;
      return categories.map((category) => category.name).toList();
    }
    return [];
  }

  /// Get category ID by name
  int? getCategoryIdByName(String name) {
    if (state is DiaryCategoriesFetchSuccess) {
      final categories = (state as DiaryCategoriesFetchSuccess).categories;
      try {
        final category = categories.firstWhere((cat) => cat.name == name);
        return category.id;
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
