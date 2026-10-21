import 'package:equatable/equatable.dart';
import 'package:eschool/data/repositories/studentLeaveRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ApplyStudentLeaveState extends Equatable {}

class ApplyStudentLeaveInitial extends ApplyStudentLeaveState {
  @override
  List<Object?> get props => [];
}

class ApplyStudentLeaveInProgress extends ApplyStudentLeaveState {
  @override
  List<Object?> get props => [];
}

class ApplyStudentLeaveSuccess extends ApplyStudentLeaveState {
  @override
  List<Object?> get props => [];
}

class ApplyStudentLeaveFailure extends ApplyStudentLeaveState {
  final String errorMessage;

  ApplyStudentLeaveFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

class ApplyStudentLeaveCubit extends Cubit<ApplyStudentLeaveState> {
  final StudentLeaveRepository _studentLeaveRepository;

  ApplyStudentLeaveCubit(this._studentLeaveRepository)
      : super(ApplyStudentLeaveInitial());

  Future<void> applyStudentLeave({
    required int childId,
    required String fromDate,
    required String toDate,
    required String reason,
    List<String>? filePaths,
  }) async {
    emit(ApplyStudentLeaveInProgress());
    try {
      await _studentLeaveRepository.applyStudentLeave(
        childId: childId,
        fromDate: fromDate,
        toDate: toDate,
        reason: reason,
        filePaths: filePaths,
      );
      emit(ApplyStudentLeaveSuccess());
    } catch (e) {
      emit(ApplyStudentLeaveFailure(e.toString()));
    }
  }
}
