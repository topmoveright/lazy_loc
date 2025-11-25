import 'dart:io';
import 'package:args/args.dart';
import 'package:lazy_loc/src/config.dart';
import 'package:lazy_loc/src/scanner.dart';
import 'package:lazy_loc/src/translation_manager.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show usage information',
    )
    ..addOption(
      'path',
      abbr: 'p',
      defaultsTo: 'lib/**.dart',
      help: 'Path glob pattern to scan for .tr() calls',
    )
    ..addOption(
      'output',
      abbr: 'o',
      defaultsTo: LazyLocConfig.targetDir,
      help: 'Output directory for translation files',
    )
    ..addMultiOption(
      'langs',
      abbr: 'l',
      defaultsTo: LazyLocConfig.defaultTargetLangs,
      help: 'Target languages (comma-separated, e.g., en,ko,ja)',
    );

  try {
    final argResults = parser.parse(arguments);

    if (argResults['help'] as bool) {
      _printUsage(parser);
      return;
    }

    final globPattern = argResults['path'] as String;
    final targetDir = argResults['output'] as String;
    final rawLangs = argResults['langs'] as List<String>;

    // Clean up languages (trim whitespace)
    final targetLangs = rawLangs
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (targetLangs.isEmpty) {
      print('❌ Error: No target languages specified.');
      _printUsage(parser);
      exit(1);
    }

    print('🚀 LazyLoc Sync Started...');
    print('   Scanning: $globPattern');
    print('   Output: $targetDir');
    print('   Languages: $targetLangs');
    print('');

    // 1. Scan
    print('⏳ Scanning for .tr() calls...');
    final scanner = CodeScanner(globPattern: globPattern);
    final codeKeys = await scanner.scan();

    if (codeKeys.isEmpty) {
      print('⚠️  No translation keys found.');
      print(
        '   Check if your path pattern is correct and contains .tr() calls.',
      );
    } else {
      print('🔍 Found ${codeKeys.length} unique keys in code.');
    }

    // 2. Process
    print('⏳ Processing translation files...');
    final translationManager = TranslationManager(targetDir: targetDir);
    for (var lang in targetLangs) {
      await translationManager.processLanguage(lang, codeKeys);
    }

    print('');
    print('✅ All done!');
  } catch (e) {
    print('❌ Error: $e');
    print('');
    _printUsage(parser);
    exit(1);
  }
}

void _printUsage(ArgParser parser) {
  print('LazyLoc - Lightweight Flutter Localization Tool');
  print('');
  print('Usage: dart run lazy_loc [options]');
  print('');
  print('Options:');
  print(parser.usage);
}
