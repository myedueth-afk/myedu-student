import 'package:equatable/equatable.dart';
import 'package:eschool/data/models/studentLeave.dart';
import 'package:eschool/data/repositories/studentLeaveRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class StudentLeavesState extends Equatable {}

class StudentLeavesInitial extends StudentLeavesState {
  @override
  List<Object?> get props => [];
}

class StudentLeavesFetchInProgress extends StudentLeavesState {
  @override
  List<Object?> get props => [];
}

class StudentLeavesFetchSuccess extends StudentLeavesState {
  final List<StudentLeave> leaves;

  StudentLeavesFetchSuccess({required this.leaves});

  @override
  List<Object?> get props => [leaves];
}

class StudentLeavesFetchFailure extends StudentLeavesState {
  final String errorMessage;

  StudentLeavesFetchFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

class StudentLeavesCubit extends Cubit<StudentLeavesState> {
  final StudentLeaveRepository _studentLeaveRepository;

  StudentLeavesCubit(this._studentLeaveRepository)
      : super(StudentLeavesInitial());

  Future<void> fetchStudentLeaves({int? childId}) async {
    emit(StudentLeavesFetchInProgress());
    try {
      emit(
        StudentLeavesFetchSuccess(
          leaves: await _studentLeaveRepository.getStudentLeaves(
            childId: childId,
          ),
        ),
      );
    } catch (e) {
      emit(StudentLeavesFetchFailure(e.toString()));
    }
  }

  List<StudentLeave> leaves() {
    if (state is StudentLeavesFetchSuccess) {
      return (state as StudentLeavesFetchSuccess).leaves;
    }
    return [];
  }

  /// Drops a cancelled leave from the loaded list so the list reflects the
  /// change without waiting for a refetch.
  void removeLeave({required int leaveId}) {
    if (state is StudentLeavesFetchSuccess) {
      emit(
        StudentLeavesFetchSuccess(
          leaves: List<StudentLeave>.from(
            (state as StudentLeavesFetchSuccess).leaves,
          )..removeWhere((leave) => leave.id == leaveId),
        ),
      );
    }
  }
}
