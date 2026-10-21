import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Verifies the fallback promise of the panel-managed localization: whatever
/// the panel does or does not return, a label always resolves to the bundled
/// English text rather than to a raw key.
void main() {
  setUp(() {
    Get.clearTranslations();
    // Stands in for the single bundled assets/languages/en.json.
    Get.addTranslations({
      'en': {'home': 'Home', 'menu': 'Menu'},
    });
    Get.fallbackLocale = const Locale('en');
  });

  test('language with no labels at all falls back to English', () {
    // Panel language "test" with "file_name": {} -> nothing overlaid.
    Get.locale = const Locale('test');
    expect('home'.tr, 'Home');
    expect('menu'.tr, 'Menu');
  });

  test('language with partial labels falls back per missing key', () {
    Get.appendTranslations({
      'test': {'home': 'Hjem'},
    });
    Get.locale = const Locale('test');
    expect('home'.tr, 'Hjem', reason: 'panel value wins');
    expect('menu'.tr, 'Menu', reason: 'missing key falls back to English');
  });

  test('country-suffixed panel code resolves via normalised key', () {
    Get.appendTranslations({
      'zh_CN': {'home': '首页'},
    });
    Get.locale = const Locale('zh', 'CN');
    expect('home'.tr, '首页');
    expect('menu'.tr, 'Menu');
  });

  test('a key missing everywhere returns the raw key (worst case)', () {
    Get.locale = const Locale('test');
    expect('someKeyNotInEnJson'.tr, 'someKeyNotInEnJson');
  });
}
