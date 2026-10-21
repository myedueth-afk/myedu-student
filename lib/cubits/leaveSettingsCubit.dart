import 'package:equatable/equatable.dart';
import 'package:eschool/data/models/leaveSettings.dart';
import 'package:eschool/data/models/publicHoliday.dart';
import 'package:eschool/data/repositories/studentLeaveRepository.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class LeaveSettingsState extends Equatable {}

class LeaveSettingsInitial extends LeaveSettingsState {
  @override
  List<Object?> get props => [];
}

class LeaveSettingsFetchInProgress extends LeaveSettingsState {
  @override
  List<Object?> get props => [];
}

class LeaveSettingsFetchSuccess extends LeaveSettingsState {
  final LeaveSettings leaveSettings;
  final List<PublicHoliday> publicHolidays;

  LeaveSettingsFetchSuccess({
    required this.leaveSettings,
    required this.publicHolidays,
  });

  @override
  List<Object?> get props => [leaveSettings, publicHolidays];
}

class LeaveSettingsFetchFailure extends LeaveSettingsState {
  final String errorMessage;

  LeaveSettingsFetchFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

/// Holds the school's weekly offs and public holidays so the apply-leave form
/// can tell working days apart from days no leave is needed for. Mirrors the
/// staff app's LeaveSettingsAndSessionYearsCubit, minus the session years —
/// the parent app already gets the running session year from
/// SchoolConfigurationCubit.
class LeaveSettingsCubit extends Cubit<LeaveSettingsState> {
  final StudentLeaveRepository _studentLeaveRepository;

  LeaveSettingsCubit(this._studentLeaveRepository)
      : super(LeaveSettingsInitial());

  Future<void> fetchLeaveSettings() async {
    emit(LeaveSettingsFetchInProgress());
    try {
      final result = await _studentLeaveRepository.getLeaveSettings();
      emit(
        LeaveSettingsFetchSuccess(
          leaveSettings: result.leaveSettings,
          publicHolidays: result.publicHolidays,
        ),
      );
    } catch (e) {
      emit(LeaveSettingsFetchFailure(e.toString()));
    }
  }

  /// Weekday numbers that are weekly offs, matching [DateTime.weekday]
  /// (1 = Monday ... 7 = Sunday). E.g. a school closed on Sunday returns [7].
  List<int> getHolidayWeekDays() {
    if (state is! LeaveSettingsFetchSuccess) {
      return [];
    }

    final holidays = (state as LeaveSettingsFetchSuccess)
            .leaveSettings
            .holiday
            ?.split(",") ??
        <String>[];

    return holidays
        .map((holiday) => Utils.weekDaysFullForm.indexOf(holiday.trim()) + 1)
        .where((weekday) => weekday > 0)
        .toList();
  }

  /// Public holiday dates mapped to their title, normalised to midnight so a
  /// selected date can be looked up directly.
  Map<DateTime, String> getPublicHolidayDates() {
    if (state is! LeaveSettingsFetchSuccess) {
      return {};
    }

    final Map<DateTime, String> holidayMap = {};
    for (final holiday in (state as LeaveSettingsFetchSuccess).publicHolidays) {
      if (holiday.date != null && (holiday.title ?? "").isNotEmpty) {
        holidayMap[DateTime(
          holiday.date!.year,
          holiday.date!.month,
          holiday.date!.day,
        )] = holiday.title!;
      }
    }
    return holidayMap;
  }
}
