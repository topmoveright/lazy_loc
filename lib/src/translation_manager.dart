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

  Future<void> processLanguage(String lang, Set<String> codeKeys) async {
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
    final sortedKeys = newData.keys.toList()..sort();
    final sortedMap = {for (var k in sortedKeys) k: newData[k]};

    // Write
    await file.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(sortedMap));

    Logger.info(
      '   📄 [$lang] Processed: Existing ${existingData.length} + New $addedCount',
    );
  }
}
