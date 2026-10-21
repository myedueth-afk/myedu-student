import 'package:eschool/app/appTranslation.dart';
import 'package:eschool/cubits/appLocalizationCubit.dart';
import 'package:eschool/data/models/appLanguage.dart';
import 'package:flutter_test/flutter_test.dart';

/// The default language is owned by the panel: `get-languages` flags it with
/// `"status": 1`. These tests pin both the parsing of that flag and the order
/// the cubit resolves the active language in.
void main() {
  // Verbatim `data` from a real get-languages response.
  final apiLanguages = <Map<String, dynamic>>[
    {
      "id": 1,
      "name": "English",
      "code": "en",
      "image": "https://example.test/en.jpg",
      "status": 1,
      "is_rtl": 0,
    },
    {
      "id": 12,
      "name": "RTL",
      "code": "002",
      "image": "https://example.test/rtl.svg",
      "status": 0,
      "is_rtl": 1,
    },
    {
      "id": 13,
      "name": "Gujarati",
      "code": "gu",
      "image": "https://example.test/gu.jpg",
      "status": 0,
      "is_rtl": 0,
    },
  ];

  List<AppLanguage> panelLanguages([List<Map<String, dynamic>>? records]) =>
      (records ?? apiLanguages).map(AppLanguage.fromJson).toList();

  setUp(() {
    AppTranslation.bundledLanguageCodes
      ..clear()
      // Stands in for the single bundled assets/languages/en.json.
      ..add('en');
  });

  group('status flag', () {
    test('marks exactly the language the panel defaults to', () {
      final languages = panelLanguages();
      expect(languages.map((language) => language.isDefault), [
        true,
        false,
        false,
      ]);
      expect(languages.defaultLanguage?.languageCode, 'en');
    });

    test('is null when the panel marks no default', () {
      final languages = panelLanguages(
        apiLanguages.map((record) => {...record, 'status': 0}).toList(),
      );
      expect(languages.defaultLanguage, isNull);
    });

    test('survives the Hive cache round-trip', () {
      final cached = panelLanguages()
          .map((language) => AppLanguage.fromJson(
                // Hive returns stored maps as Map<dynamic, dynamic>.
                Map.from(Map<dynamic, dynamic>.from(language.toJson())),
              ))
          .toList();
      expect(cached.defaultLanguage?.languageCode, 'en',
          reason: 'a cold start must resolve the default without the network');
    });
  });

  group('resolveLanguageCode', () {
    test('follows the panel default when the user never picked a language', () {
      expect(
        AppLocalizationCubit.resolveLanguageCode(
          selectedLanguageCode: null,
          availableLanguages: panelLanguages(),
        ),
        'en',
      );
    });

    test('follows the panel when the default moves to another language', () {
      final languages = panelLanguages([
        {...apiLanguages[0], 'status': 0},
        {...apiLanguages[1], 'status': 0},
        {...apiLanguages[2], 'status': 1},
      ]);
      expect(
        AppLocalizationCubit.resolveLanguageCode(
          selectedLanguageCode: null,
          availableLanguages: languages,
        ),
        'gu',
        reason: 'a default changed on the panel reaches the app on next sync',
      );
    });

    test('an explicit user choice outranks the panel default', () {
      expect(
        AppLocalizationCubit.resolveLanguageCode(
          selectedLanguageCode: 'gu',
          availableLanguages: panelLanguages(),
        ),
        'gu',
      );
    });

    test('falls back to the bundled language when no default is flagged', () {
      final languages = panelLanguages(
        apiLanguages.map((record) => {...record, 'status': 0}).toList(),
      );
      expect(
        AppLocalizationCubit.resolveLanguageCode(
          selectedLanguageCode: null,
          availableLanguages: languages,
        ),
        'en',
      );
    });

    test('falls back to the bundled language before the panel is reachable',
        () {
      // First launch offline: no cached list, nothing fetched yet.
      expect(
        AppLocalizationCubit.resolveLanguageCode(
          selectedLanguageCode: null,
          availableLanguages: const [],
        ),
        AppTranslation.fallbackLanguageCode,
      );
    });

    test('a default with a blank code is ignored', () {
      final languages = panelLanguages([
        {'code': '', 'name': 'Broken', 'status': 1},
      ]);
      expect(
        AppLocalizationCubit.resolveLanguageCode(
          selectedLanguageCode: null,
          availableLanguages: languages,
        ),
        'en',
        reason: 'a misconfigured panel record must not strand the app',
      );
    });

    test('the first flagged language wins when the panel flags several', () {
      final languages = panelLanguages(
        apiLanguages.map((record) => {...record, 'status': 1}).toList(),
      );
      expect(
        AppLocalizationCubit.resolveLanguageCode(
          selectedLanguageCode: null,
          availableLanguages: languages,
        ),
        'en',
        reason: 'resolution stays deterministic',
      );
    });
  });
}
