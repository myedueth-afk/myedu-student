import 'package:eschool/data/models/subjectWiseReport.dart';
import 'package:eschool/data/repositories/subjectWiseReportRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class SubjectWiseReportState {}

class SubjectWiseReportInitial extends SubjectWiseReportState {}

class SubjectWiseReportFetchInProgress extends SubjectWiseReportState {}

class SubjectWiseReportFetchSuccess extends SubjectWiseReportState {
  final SubjectWiseReport report;

  SubjectWiseReportFetchSuccess({required this.report});
}

class SubjectWiseReportFetchFailure extends SubjectWiseReportState {
  final String errorMessage;

  SubjectWiseReportFetchFailure({required this.errorMessage});
}

class SubjectWiseReportCubit extends Cubit<SubjectWiseReportState> {
  final SubjectWiseReportRepository _subjectWiseReportRepository;

  SubjectWiseReportCubit(this._subjectWiseReportRepository)
      : super(SubjectWiseReportInitial());

  void fetchSubjectWiseReport({
    required int classSubjectId,
    required int childId,
    required bool useParentApi,
  }) async {
    emit(SubjectWiseReportFetchInProgress());
    try {
      final SubjectWiseReport report =
          await _subjectWiseReportRepository.getSubjectWiseReport(
              classSubjectId: classSubjectId,
              childId: childId,
              useParentApi: useParentApi);
      emit(SubjectWiseReportFetchSuccess(report: report));
    } catch (e) {
      emit(SubjectWiseReportFetchFailure(errorMessage: e.toString()));
    }
  }
}
