import 'dart:io';
import 'package:path/path.dart' as p;
import 'config.dart';

class BackupManager {
  final String targetDir;

  BackupManager({this.targetDir = LazyLocConfig.targetDir});

  Future<void> createBackup(File originalFile, String lang) async {
    if (!await originalFile.exists()) return;

    final now = DateTime.now();
    final timestamp =
        "${now.year}${_two(now.month)}${_two(now.day)}_${_two(now.hour)}${_two(now.minute)}${_two(now.second)}";

    final backupDir = Directory(
      p.join(targetDir, LazyLocConfig.backupDirName, lang),
    );
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final backupPath = p.join(backupDir.path, '${lang}_$timestamp.json');
    await originalFile.copy(backupPath);
    print(
      '      🛡️ Backup created: .../${LazyLocConfig.backupDirName}/$lang/${lang}_$timestamp.json',
    );
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}
