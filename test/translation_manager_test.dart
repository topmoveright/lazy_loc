import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazy_loc/src/translation_manager.dart';
import 'package:path/path.dart' as p;

void main() {
  group('TranslationManager', () {
    late Directory tempDir;
    late TranslationManager manager;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('lazy_loc_tm_test');
      manager = TranslationManager(targetDir: tempDir.path);
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('creates new file with keys', () async {
      final keys = {'hello', 'world'};
      await manager.processLanguage('en', keys);

      final file = File(p.join(tempDir.path, 'en.json'));
      expect(await file.exists(), isTrue);

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      expect(json, containsPair('hello', ''));
      expect(json, containsPair('world', ''));
    });

    test('merges existing keys and preserves values', () async {
      final file = File(p.join(tempDir.path, 'en.json'));
      await file.writeAsString(jsonEncode({'hello': 'Hello World'}));

      final keys = {'hello', 'new_key'};
      await manager.processLanguage('en', keys);

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      expect(json['hello'], 'Hello World'); // Preserved
      expect(json['new_key'], ''); // Added
    });
  });
}
