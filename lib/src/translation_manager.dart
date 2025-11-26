import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'logger.dart';
import 'backup_manager.dart';
import 'config.dart';

class TranslationManager {
  final String targetDir;
  final BackupManager backupManager;

  TranslationManager({
    this.targetDir = LazyLocConfig.targetDir,
    BackupManager? backupManager,
  }) : backupManager = backupManager ?? BackupManager(targetDir: targetDir);

  Future<void> processLanguage(
    String lang,
    Set<String> codeKeys, {
    String sortOption = 'empty-first',
    String? sourceLang,
  }) async {
    final filePath = p.join(targetDir, '$lang.json');
    final file = File(filePath);

    Map<String, dynamic> existingData = {};

    // Read and Backup
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        existingData = jsonDecode(content);
        await backupManager.createBackup(file, lang);
      } catch (e) {
        Logger.warn(
          '⚠️ Failed to parse $lang.json. Starting with empty file after backup.',
        );
        await backupManager.createBackup(file, lang);
      }
    }

    // Merge
    Map<String, dynamic> newData = Map.from(existingData);
    int addedCount = 0;

    for (var key in codeKeys) {
      if (!newData.containsKey(key)) {
        newData[key] = ""; // Initialize with empty string
        addedCount++;
      }
    }

    // Sort
    final sortedKeys = newData.keys.toList();
    _sortKeys(sortedKeys, newData, sortOption);

    final sortedMap = {for (var k in sortedKeys) k: newData[k]};

    // Write
    await file.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(sortedMap));

    // Calculate missing (empty) entries
    int emptyCount = 0;
    for (var value in sortedMap.values) {
      if (value.toString().isEmpty) emptyCount++;
    }

    String statusMsg;
    if (lang == sourceLang) {
      statusMsg = '(Source Lang - Skipped Empty Check)';
    } else {
      statusMsg = emptyCount > 0 ? '⚠️ Missing: $emptyCount' : '✅';
    }

    Logger.info(
      '   📄 [$lang] Processed: Existing ${existingData.length} + New $addedCount $statusMsg',
    );
  }

  void _sortKeys(
    List<String> keys,
    Map<String, dynamic> data,
    String sortOption,
  ) {
    switch (sortOption) {
      case 'desc':
        keys.sort((a, b) => b.compareTo(a));
        break;
      case 'empty-first':
        keys.sort((a, b) {
          final aEmpty = data[a]?.toString().isEmpty ?? true;
          final bEmpty = data[b]?.toString().isEmpty ?? true;
          if (aEmpty && !bEmpty) return -1;
          if (!aEmpty && bEmpty) return 1;
          return a.compareTo(b);
        });
        break;
      case 'empty-last':
        keys.sort((a, b) {
          final aEmpty = data[a]?.toString().isEmpty ?? true;
          final bEmpty = data[b]?.toString().isEmpty ?? true;
          if (aEmpty && !bEmpty) return 1;
          if (!aEmpty && bEmpty) return -1;
          return a.compareTo(b);
        });
        break;
      case 'asc':
      default:
        keys.sort();
    }
  }
}
