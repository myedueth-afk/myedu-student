import 'package:eschool/utils/hiveBoxKeys.dart';
import 'package:hive/hive.dart';

class SettingsRepository {
  /// Language the user picked explicitly in the language sheet. Null while the
  /// user never picked one, which is what lets the app follow the panel
  /// default — so this must only be written on an actual user choice.
  String? getSelectedLanguageCode() {
    final languageCode = Hive.box(settingsBoxKey).get(currentLanguageCodeKey);
    return languageCode is String && languageCode.isNotEmpty
        ? languageCode
        : null;
  }

  Future<void> setSelectedLanguageCode(String value) async {
    await Hive.box(settingsBoxKey).put(currentLanguageCodeKey, value);
  }

  /// Hands the app back to the panel default.
  Future<void> clearSelectedLanguageCode() async {
    await Hive.box(settingsBoxKey).delete(currentLanguageCodeKey);
  }

  Future<void> setAllowNotification(bool value) async {
    Hive.box(settingsBoxKey).put(allowNotificationKey, value);
  }

  bool getAllowNotification() {
    return Hive.box(settingsBoxKey).get(allowNotificationKey) ?? true;
  }
}
