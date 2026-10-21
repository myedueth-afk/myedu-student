import 'package:equatable/equatable.dart';
import 'package:eschool/data/repositories/systemInfoRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

//It will store the details like contact us and other
abstract class AppSettingsState extends Equatable {}

class AppSettingsInitial extends AppSettingsState {
  @override
  List<Object?> get props => [];
}

class AppSettingsFetchInProgress extends AppSettingsState {
  @override
  List<Object?> get props => [];
}

class AppSettingsFetchSuccess extends AppSettingsState {
  final String appSettingsResult;

  AppSettingsFetchSuccess({required this.appSettingsResult});
  @override
  List<Object?> get props => [appSettingsResult];
}

class AppSettingsFetchFailure extends AppSettingsState {
  final String errorMessage;

  AppSettingsFetchFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

class AppSettingsCubit extends Cubit<AppSettingsState> {
  final SystemRepository _systemRepository;

  AppSettingsCubit(this._systemRepository) : super(AppSettingsInitial());

  Future<void> fetchAppSettings({required String type}) =>
      _fetch(() => _systemRepository.fetchSettings(type: type));

  Future<void> fetchSchoolSettings({required String type}) =>
      _fetch(() => _systemRepository.fetchSchoolSettings(type: type));

  /// A school's settings before login; see
  /// [SystemRepository.fetchPublicSchoolSettings].
  Future<void> fetchPublicSchoolSettings({
    required String type,
    required String schoolCode,
  }) =>
      _fetch(
        () => _systemRepository.fetchPublicSchoolSettings(
          type: type,
          schoolCode: schoolCode,
        ),
      );

  /// Repeats the last fetch, whichever source it read from.
  Future<void> retry() async {
    final request = _lastRequest;
    if (request != null) await _fetch(request);
  }

  Future<dynamic> Function()? _lastRequest;

  Future<void> _fetch(Future<dynamic> Function() request) async {
    _lastRequest = request;
    emit(AppSettingsFetchInProgress());

    try {
      final result = await request() ?? "";
      emit(AppSettingsFetchSuccess(appSettingsResult: result));
    } catch (e) {
      emit(AppSettingsFetchFailure(e.toString()));
    }
  }
}
