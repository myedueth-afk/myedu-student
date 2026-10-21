import 'package:eschool/app/appTranslation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Behaviour of the last-resort language — the one GetX falls back to for keys
/// the active language does not provide. Unlike the app default, which the
/// panel owns through `"status": 1` (see panelDefaultLanguage_test.dart), this
/// one has to be a language bundled with the build.
///
/// `AppTranslation.fallbackLanguageCode` is derived from which json files
/// actually parsed at startup, so the tests drive `bundledLanguageCodes`
/// directly instead of loading real assets.
void main() {
  setUp(() {
    AppTranslation.bundledLanguageCodes.clear();
    AppTranslation.translationsKeys.clear();
    Get.clearTranslations();
  });

  group('fallbackLanguageCode', () {
    test('is bundledFallbackLanguageCode when its json is bundled', () {
      AppTranslation.bundledLanguageCodes.addAll({'en', 'hi'});
      // bundledFallbackLanguageCode is "en" in this build.
      expect(AppTranslation.fallbackLanguageCode, 'en');
    });

    test('is whatever did parse when that json is missing', () {
      // Simulates a build that ships a single hi.json: falls back to hi,
      // never to nothing.
      AppTranslation.bundledLanguageCodes.add('hi');
      expect(AppTranslation.fallbackLanguageCode, 'hi');
    });

    test('degrades to bundledFallbackLanguageCode when no json parsed at all',
        () {
      expect(AppTranslation.fallbackLanguageCode, 'en');
    });
  });

  group('a panel default with no bundled json still renders text', () {
    test('panel labels arrive and are used', () {
      AppTranslation.bundledLanguageCodes.add('en');
      AppTranslation.translationsKeys['en'] = {'home': 'Home', 'menu': 'Menu'};
      Get.addTranslations(AppTranslation.translationsKeys);
      Get.fallbackLocale = const Locale('en');

      // Panel default is the panel-only "test"; splash sync overlays its
      // labels.
      AppTranslation.overlayRemoteLabels({
        'test': {'home': 'Startseite'},
      });
      Get.locale = const Locale('test');

      expect('home'.tr, 'Startseite', reason: 'panel label wins');
      expect('menu'.tr, 'Menu',
          reason: 'key the panel omits uses the fallback');
      expect(AppTranslation.hasTranslationsFor('test'), isTrue);
    });

    test('no panel labels at all leaves the language unusable', () {
      AppTranslation.bundledLanguageCodes.add('en');
      AppTranslation.translationsKeys['en'] = {'home': 'Home'};
      Get.addTranslations(AppTranslation.translationsKeys);
      Get.fallbackLocale = const Locale('en');
      Get.locale = const Locale('test');

      // This is what makes the cubit reset to fallbackLanguageCode.
      expect(AppTranslation.hasTranslationsFor('test'), isFalse);
      // Meanwhile text is still readable rather than raw keys.
      expect('home'.tr, 'Home');
    });
  });
}
