import 'package:eschool/data/models/appLanguage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Parsing of the panel's language records, pinned to a real `set-languages`
/// response, plus the Hive cache round-trip (Hive hands maps back as
/// `Map<dynamic, dynamic>`, so the casts on the read path are unchecked until
/// runtime).
void main() {
  // Verbatim `data` from a real set-languages response.
  final apiRecord = <String, dynamic>{
    "id": 14,
    "code": "test",
    "name": "Test",
    "name_in_english": "Test",
    "student_app_file": null,
    "staff_app_file": null,
    "web_file": null,
    "panel_file": "",
    "rtl": false,
    "image": null,
    "created_at": "20-07-2026 12:42",
    "updated_at": "20-07-2026 12:42",
    "country_code": null,
    "file_name": <String, dynamic>{},
  };

  test('parses a real panel language record', () {
    final language = AppLanguage.fromJson(apiRecord);
    expect(language.languageCode, 'test');
    expect(language.languageName, 'Test');
    expect(language.isRtl, isFalse);
    expect(language.imageUrl, isNull, reason: 'null image must not become ""');
  });

  test('survives the Hive cache round-trip', () {
    final original = AppLanguage.fromJson(apiRecord);

    // Hive returns stored maps as Map<dynamic, dynamic>.
    final stored = Map<dynamic, dynamic>.from(original.toJson());
    final restored = AppLanguage.fromJson(Map.from(stored));

    expect(restored.languageCode, original.languageCode);
    expect(restored.languageName, original.languageName);
    expect(restored.isRtl, original.isRtl);
    expect(restored.imageUrl, original.imageUrl);
  });

  test('rtl round-trips through the int the cache stores', () {
    final rtl = AppLanguage.fromJson({...apiRecord, 'rtl': true});
    expect(rtl.isRtl, isTrue);

    final restored = AppLanguage.fromJson(
      Map.from(Map<dynamic, dynamic>.from(rtl.toJson())),
    );
    expect(restored.isRtl, isTrue, reason: 'stored as 1, must read back true');
  });

  test('get-languages 0/1 form of the rtl flag', () {
    expect(AppLanguage.fromJson({'code': 'ar', 'is_rtl': 1}).isRtl, isTrue);
    expect(AppLanguage.fromJson({'code': 'en', 'is_rtl': 0}).isRtl, isFalse);
  });

  test('unnamed language falls back to its code, blank code is filtered out',
      () {
    expect(AppLanguage.fromJson({'code': 'xx'}).languageName, 'xx');
    expect(AppLanguage.fromJson(<String, dynamic>{}).languageCode, isEmpty);
  });
}
