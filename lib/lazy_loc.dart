import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LazyLoc {
  // 1. Static variable to hold translated data
  static Map<String, dynamic> _localizedValues = {};

  // Current Locale
  final Locale locale;
  LazyLoc(this.locale);

  // 2. Load function executed when Flutter changes Locale
  static Future<LazyLoc> load(
    Locale locale, {
    String path = 'assets/translations',
  }) async {
    // e.g. ko -> read assets/translations/ko.json
    // Using languageCode (e.g. 'en', 'ko') to match generated files
    final String fileName = locale.languageCode;
    final String assetPath = '$path/$fileName.json';

    try {
      String jsonString = await rootBundle.loadString(assetPath);
      Map<String, dynamic> jsonMap = json.decode(jsonString);

      // Store loaded data in static variable
      _localizedValues = jsonMap.map(
        (key, value) => MapEntry(key, value.toString()),
      );
    } catch (e) {
      // Log error if file not found or parsing fails
      debugPrint(
        'LazyLoc: ⚠️ $assetPath not found or invalid. Using keys as fallback.',
      );
      _localizedValues = {};
    }

    return LazyLoc(locale);
  }

  // 3. Translate function accessible from anywhere
  static String translate(String key) {
    return _localizedValues[key] ??
        key; // Return original key if translation missing
  }

  // Helper to access from Flutter tree (optional)
  static LazyLoc? of(BuildContext context) {
    return Localizations.of<LazyLoc>(context, LazyLoc);
  }
}

// 4. Delegate to connect with Flutter engine
class LazyLocDelegate extends LocalizationsDelegate<LazyLoc> {
  final List<Locale>? supportedLocales;
  final String path;

  const LazyLocDelegate({
    this.supportedLocales,
    this.path = 'assets/translations',
  });

  @override
  bool isSupported(Locale locale) {
    // If supportedLocales is specified, check it.
    // Otherwise, return true to support any locale for which a JSON file might exist.
    if (supportedLocales != null) {
      return supportedLocales!.contains(locale);
    }
    return true;
  }

  @override
  Future<LazyLoc> load(Locale locale) async {
    return await LazyLoc.load(locale, path: path);
  }

  @override
  bool shouldReload(LazyLocDelegate old) => false;
}

// Expose const object for easy usage with default settings
const LazyLocDelegate lazyLocDelegate = LazyLocDelegate();

extension LazyLocExt on String {
  // .tr() implementation
  String tr() {
    return LazyLoc.translate(this);
  }
}
