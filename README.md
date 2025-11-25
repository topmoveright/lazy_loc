# LazyLoc

A lightweight localization package for Flutter that automates translation file management and provides a simple `.tr()` extension for string translation.

## Features

- **CLI Tool**: Automatically scans your Dart code for `.tr()` calls and generates/updates JSON translation files
- **Auto Backup**: Creates timestamped backups before modifying translation files
- **Smart Merge**: Preserves existing translations while adding new keys
- **Simple API**: Use `.tr()` extension on any string for translation
- **Flutter Integration**: Built-in `LocalizationsDelegate` for seamless Flutter integration

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  lazy_loc: ^0.0.1
  flutter_localizations:
    sdk: flutter
```

## Usage

### 1. Configure Your App

In your `pubspec.yaml`, register the assets directory where your translation files will reside:

```yaml
flutter:
  assets:
    - assets/translations/
```

### 2. Initialize in Your App

You can use the default `lazyLocDelegate` which tries to load any language file found in `assets/translations/`, or configure it manually.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lazy_loc/lazy_loc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 1. Define supported locales
      supportedLocales: const [
        Locale('en'),
        Locale('ko'),
        Locale('ja'),
      ],
      // 2. Add delegates
      localizationsDelegates: const [
        lazyLocDelegate, // Default delegate
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const MyHomePage(),
    );
  }
}
```

#### Advanced Configuration

If you need to store translations in a different directory or restrict supported locales explicitly in the delegate:

```dart
localizationsDelegates: [
  LazyLocDelegate(
    path: 'assets/i18n', // Custom path
    supportedLocales: [Locale('en'), Locale('ko')], // Explicit support
  ),
  // ...
],
```

### 3. Use in Your Code

Simply append `.tr()` to any string you want to translate.

```dart
Text('hello'.tr())
Text('welcome_message'.tr())
```

### 4. Generate Translation Files

Run the CLI tool to scan your code and generate/update translation files:

```bash
dart run lazy_loc
```

This will:
- Scan all `.dart` files in `lib/` for `.tr()` calls
- Create/update JSON files in `assets/translations/` for each language
- Backup existing files to `assets/translations/_backup/`

### 5. Fill in Translations

After running the CLI, you'll have JSON files like `assets/translations/ko.json`:

```json
{
  "hello": "",
  "welcome_message": ""
}
```

Fill in the translations manually or use AI:

```json
{
  "hello": "안녕하세요",
  "welcome_message": "환영합니다"
}
```

## CLI Options

You can customize the scanner behavior with command-line arguments:

```bash
# Show help
dart run lazy_loc --help

# Scan specific path (glob pattern)
dart run lazy_loc --path "lib/features/**.dart"

# Custom output directory (default: assets/translations)
dart run lazy_loc --output "assets/i18n"

# Specify target languages (comma-separated)
# Default: ko,en
dart run lazy_loc --langs en,ko,ja,es
```

## Workflow

1. Write code with `.tr()` calls
2. Run `dart run lazy_loc` to generate translation files
3. Fill in translations (manually or with AI)
4. Commit both code and translation files
5. Repeat as needed

## License

MIT
