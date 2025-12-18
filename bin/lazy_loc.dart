import 'dart:io';
import 'package:args/args.dart';
import 'package:lazy_loc/src/config.dart';
import 'package:lazy_loc/src/logger.dart';
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
    ..addOption(
      'sort',
      abbr: 's',
      allowed: ['asc', 'desc', 'empty-first', 'empty-last'],
      defaultsTo: 'empty-first',
      help: 'Sort order of keys in output files',
    )
    ..addOption(
      'source-lang',
      abbr: 'S',
      help: 'Source language code (e.g. ko) to skip empty value warnings',
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
    final sortOption = argResults['sort'] as String;
    final sourceLang = argResults['source-lang'] as String?;
    final rawLangs = argResults['langs'] as List<String>;

    // Clean up languages (trim whitespace)
    final targetLangs = rawLangs
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (targetLangs.isEmpty) {
      Logger.error('❌ Error: No target languages specified.');
      _printUsage(parser);
      exit(1);
    }

    Logger.info('🚀 LazyLoc Sync Started...');
    Logger.info('   Scanning: $globPattern');
    Logger.info('   Output: $targetDir');
    Logger.info('   Languages: $targetLangs');
    if (sourceLang != null) {
      Logger.info('   Source: $sourceLang');
    }
    Logger.info('   Sort: $sortOption');
    Logger.info('');

    // 1. Scan
    Logger.info('⏳ Scanning for .tr() and trKey() calls...');
    final scanner = CodeScanner(globPattern: globPattern);
    final scanResult = await scanner.scanWithWarnings();
    final codeKeys = scanResult.keys;

    if (codeKeys.isEmpty) {
      Logger.warn('⚠️  No translation keys found.');
      Logger.warn(
        '   Check if your path pattern is correct and contains .tr() calls.',
      );
    } else {
      Logger.info('🔍 Found ${codeKeys.length} unique keys in code.');
    }

    // Warn about variable .tr() calls that cannot be extracted
    if (scanResult.warnings.isNotEmpty) {
      Logger.warn('');
      Logger.warn(
        '⚠️  Found ${scanResult.warnings.length} variable-based .tr() call(s) that cannot be extracted:',
      );
      for (var warning in scanResult.warnings) {
        Logger.warn('   ${warning.filePath}:${warning.line}');
        Logger.warn('      ${warning.matchedText}');
      }
      Logger.warn('');
      Logger.warn(
        '   💡 Tip: Use LazyLoc.trKey(\'key\') instead of variable.tr() for extractable keys.',
      );
      Logger.warn('');
    }

    // 2. Process
    Logger.info('⏳ Processing translation files...');
    final translationManager = TranslationManager(targetDir: targetDir);
    for (var lang in targetLangs) {
      await translationManager.processLanguage(
        lang,
        codeKeys,
        sortOption: sortOption,
        sourceLang: sourceLang,
      );
    }

    Logger.info('');
    Logger.info('✅ All done!');
  } catch (e) {
    Logger.error('❌ Error: $e');
    Logger.error('');
    _printUsage(parser);
    exit(1);
  }
}

void _printUsage(ArgParser parser) {
  Logger.info('LazyLoc - Lightweight Flutter Localization Tool');
  Logger.info('');
  Logger.info('Usage: dart run lazy_loc [options]');
  Logger.info('');
  Logger.info('Options:');
  Logger.info(parser.usage);
}
