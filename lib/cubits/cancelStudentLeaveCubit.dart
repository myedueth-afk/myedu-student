import 'package:equatable/equatable.dart';
import 'package:eschool/data/repositories/studentLeaveRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class CancelStudentLeaveState extends Equatable {}

class CancelStudentLeaveInitial extends CancelStudentLeaveState {
  @override
  List<Object?> get props => [];
}

class CancelStudentLeaveInProgress extends CancelStudentLeaveState {
  @override
  List<Object?> get props => [];
}

class CancelStudentLeaveSuccess extends CancelStudentLeaveState {
  final int leaveId;

  CancelStudentLeaveSuccess({required this.leaveId});

  @override
  List<Object?> get props => [leaveId];
}

class CancelStudentLeaveFailure extends CancelStudentLeaveState {
  final String errorMessage;

  CancelStudentLeaveFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

class CancelStudentLeaveCubit extends Cubit<CancelStudentLeaveState> {
  final StudentLeaveRepository _studentLeaveRepository;

  CancelStudentLeaveCubit(this._studentLeaveRepository)
      : super(CancelStudentLeaveInitial());

  Future<void> cancelStudentLeave({required int leaveId}) async {
    emit(CancelStudentLeaveInProgress());
    try {
      await _studentLeaveRepository.cancelStudentLeave(leaveId: leaveId);
      emit(CancelStudentLeaveSuccess(leaveId: leaveId));
    } catch (e) {
      emit(CancelStudentLeaveFailure(e.toString()));
    }
  }
}
