import 'dart:ui';
import 'package:get/get.dart';
import 'package:doctor_app/data/local/storage_service.dart';

const String kLanguageCodeKey = 'language_code';

Locale getSavedLocale(StorageService storage) {
  final saved = storage.read<String>(key: kLanguageCodeKey);
  final code = saved ?? 'de';
  final normalized = (code == 'de' || code == 'en') ? code : 'de';
  return Locale(normalized);
}

Future<void> saveLanguageCode(StorageService storage, String code) async {
  await storage.write(key: kLanguageCodeKey, value: code);
}

String toggleLanguageCode(String current) {
  return current == 'de' ? 'en' : 'de';
}

void applySavedLocale(StorageService storage) {
  final locale = getSavedLocale(storage);
  Get.updateLocale(locale);
}
