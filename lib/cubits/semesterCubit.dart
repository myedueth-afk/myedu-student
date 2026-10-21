import 'package:eschool/data/models/semester.dart';
import 'package:eschool/data/repositories/semesterRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class SemesterState {}

class SemesterInitial extends SemesterState {}

class SemesterFetchInProgress extends SemesterState {}

class SemesterFetchSuccess extends SemesterState {
  final List<Semester> semesters;

  SemesterFetchSuccess({required this.semesters});
}

class SemesterFetchFailure extends SemesterState {
  final String errorMessage;

  SemesterFetchFailure(this.errorMessage);
}

class SemesterCubit extends Cubit<SemesterState> {
  final SemesterRepository _semesterRepository;

  SemesterCubit(this._semesterRepository) : super(SemesterInitial());

  void fetchSemesters({
    required int sessionYearId,
    bool useParentApi = false,
    int? childId,
  }) async {
    try {
      emit(SemesterFetchInProgress());
      emit(
        SemesterFetchSuccess(
          semesters: await _semesterRepository.fetchSemesters(
            sessionYearId: sessionYearId,
            useParentApi: useParentApi,
            childId: childId,
          ),
        ),
      );
    } catch (e) {
      emit(SemesterFetchFailure(e.toString()));
    }
  }
}
