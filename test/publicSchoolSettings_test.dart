import 'package:eschool/cubits/appSettingsCubit.dart';
import 'package:eschool/data/repositories/systemInfoRepository.dart';
import 'package:eschool/utils/api.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records which settings source the cubit read, without going near the
/// network. Fails every call while [failing] is set.
class _RecordingSystemRepository extends SystemRepository {
  final List<String> calls = [];
  bool failing = false;

  String _answer(String call) {
    calls.add(call);
    if (failing) throw ApiException('offline');
    return '<p>$call</p>';
  }

  @override
  Future<dynamic> fetchSettings({
    required String type,
    bool sendAppType = false,
  }) async =>
      _answer('settings:$type');

  @override
  Future<dynamic> fetchSchoolSettings({required String type}) async =>
      _answer('school:$type');

  @override
  Future<dynamic> fetchPublicSchoolSettings({
    required String type,
    required String schoolCode,
  }) async =>
      _answer('public:$schoolCode:$type');
}

void main() {
  group('headers', () {
    test('the header name is the one the backend reads', () {
      expect(Api.schoolCodeHeader, 'school-code');
    });

    test('a signed-out request naming a school carries only its code', () {
      expect(
        Api.requestHeaders(useAuthToken: false, schoolCode: 'SCH202412'),
        {Api.schoolCodeHeader: 'SCH202412'},
      );
    });
  });

  group('AppSettingsCubit', () {
    late _RecordingSystemRepository repository;
    late AppSettingsCubit cubit;

    setUp(() {
      repository = _RecordingSystemRepository();
      cubit = AppSettingsCubit(repository);
    });

    tearDown(() => cubit.close());

    test('reads a school\'s settings by its code alone', () async {
      await cubit.fetchPublicSchoolSettings(
        type: 'privacy_policy',
        schoolCode: 'SCH202412',
      );

      expect(repository.calls, ['public:SCH202412:privacy_policy']);
      expect(
        cubit.state,
        AppSettingsFetchSuccess(
          appSettingsResult: '<p>public:SCH202412:privacy_policy</p>',
        ),
      );
    });

    test('retry repeats the fetch that failed, from the same source',
        () async {
      repository.failing = true;
      await cubit.fetchPublicSchoolSettings(
        type: 'privacy_policy',
        schoolCode: 'SCH202412',
      );
      expect(cubit.state, isA<AppSettingsFetchFailure>());

      repository.failing = false;
      await cubit.retry();

      expect(repository.calls, [
        'public:SCH202412:privacy_policy',
        'public:SCH202412:privacy_policy',
      ]);
      expect(cubit.state, isA<AppSettingsFetchSuccess>());
    });

    test('retry follows the latest fetch, not the first', () async {
      repository.failing = true;
      await cubit.fetchSchoolSettings(type: 'about_us');
      await cubit.fetchAppSettings(type: 'student_parent_privacy_policy');

      repository.failing = false;
      await cubit.retry();

      expect(
        repository.calls.last,
        'settings:student_parent_privacy_policy',
      );
    });

    test('retry before any fetch does nothing', () async {
      await cubit.retry();

      expect(repository.calls, isEmpty);
      expect(cubit.state, isA<AppSettingsInitial>());
    });
  });
}
