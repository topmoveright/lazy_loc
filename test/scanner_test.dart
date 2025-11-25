import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazy_loc/src/scanner.dart';
import 'package:path/path.dart' as p;

void main() {
  group('CodeScanner', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('lazy_loc_test');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('scans .tr() keys correctly', () async {
      final file = File(p.join(tempDir.path, 'test.dart'));
      await file.writeAsString('''
        void main() {
          print('hello'.tr());
          print("world".tr());
          print('mixed"quote'.tr());
        }
      ''');

      final scanner = CodeScanner(globPattern: p.join(tempDir.path, '**.dart'));
      final keys = await scanner.scan();

      expect(keys, containsAll(['hello', 'world', 'mixed"quote']));
    });
  });
}
