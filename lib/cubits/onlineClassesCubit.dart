import 'package:equatable/equatable.dart';
import 'package:eschool/data/models/timeTableSlot.dart';
import 'package:eschool/data/repositories/studentRepository.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class OnlineClassesState extends Equatable {}

class OnlineClassesInitial extends OnlineClassesState {
  @override
  List<Object?> get props => [];
}

class OnlineClassesFetchInProgress extends OnlineClassesState {
  @override
  List<Object?> get props => [];
}

class OnlineClassesFetchSuccess extends OnlineClassesState {
  final List<TimeTableSlot> onlineClasses;

  ///The date the classes were fetched for (today). Passed to the card so the
  ///online / live / join indicators are evaluated against the correct date.
  final DateTime date;

  OnlineClassesFetchSuccess({
    required this.onlineClasses,
    required this.date,
  });

  @override
  List<Object?> get props => [onlineClasses, date];
}

class OnlineClassesFetchFailure extends OnlineClassesState {
  final String errorMessage;

  OnlineClassesFetchFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

/// Fetches today's timetable (filtered by weekday on the backend) and keeps only
/// the slots that are online classes for today. Used by the home screen's
/// "Online Classes" section.
class OnlineClassesCubit extends Cubit<OnlineClassesState> {
  final StudentRepository _studentRepository;

  OnlineClassesCubit(this._studentRepository) : super(OnlineClassesInitial());

  Future<void> fetchTodaysOnlineClasses({
    required bool useParentApi,
    int? childId,
  }) async {
    emit(OnlineClassesFetchInProgress());

    final today = DateTime.now();

    ///Full weekday name ("Monday".."Sunday") expected by the API `day` filter.
    final dayName = Utils.weekDaysFullForm[today.weekday - 1];

    try {
      final slots = await _studentRepository.fetchTimeTable(
        childId: childId ?? 0,
        useParentApi: useParentApi,
        day: dayName,
      );

      ///Also match the slot's weekday locally so the result stays correct even
      ///if the endpoint doesn't honor the `day` filter (e.g. the parent API).
      final onlineClasses = slots
          .where((slot) =>
              slot.day == dayName && slot.showOnlineClassLabelOnDate(today))
          .toList();
      emit(
        OnlineClassesFetchSuccess(onlineClasses: onlineClasses, date: today),
      );
    } catch (e) {
      emit(OnlineClassesFetchFailure(e.toString()));
    }
  }
}
