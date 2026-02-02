import 'package:get/get.dart';
import 'app_translations_data.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    // Support language-only codes for simplicity
    'en': appTranslationsData['en'] ?? {},
    'de': appTranslationsData['de'] ?? {},
    // Also expose region-specific codes if needed
    'en_US': appTranslationsData['en'] ?? {},
    'de_DE': appTranslationsData['de'] ?? {},
  };
}
