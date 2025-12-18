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

    group('variable string extraction limitation', () {
      test(
        'does NOT extract variable .tr() calls (expected limitation)',
        () async {
          final file = File(p.join(tempDir.path, 'test.dart'));
          await file.writeAsString('''
          void main() {
            final key = 'dynamic_key';
            print(key.tr()); // Variable - NOT extractable

            String getKey() => 'func_key';
            print(getKey().tr()); // Function return - NOT extractable

            final keys = ['list_key_1', 'list_key_2'];
            print(keys[0].tr()); // Array element - NOT extractable

            final map = {'k': 'map_key'};
            print(map['k']!.tr()); // Map value - NOT extractable
          }
        ''');

          final scanner = CodeScanner(
            globPattern: p.join(tempDir.path, '**.dart'),
          );
          final keys = await scanner.scan();

          // These keys are NOT extracted because they use variables
          expect(keys, isNot(contains('dynamic_key')));
          expect(keys, isNot(contains('func_key')));
          expect(keys, isNot(contains('list_key_1')));
          expect(keys, isNot(contains('map_key')));
          expect(keys, isEmpty);
        },
      );

      test(
        'extracts hardcoded strings but not variables in same file',
        () async {
          final file = File(p.join(tempDir.path, 'test.dart'));
          await file.writeAsString('''
          void main() {
            // Hardcoded - extractable
            print('hardcoded_key'.tr());

            // Variable - NOT extractable
            final key = 'variable_key';
            print(key.tr());

            // Ternary with hardcoded - also NOT extractable (parentheses break regex)
            final condition = true;
            print((condition ? 'ternary_true' : 'ternary_false').tr());
          }
        ''');

          final scanner = CodeScanner(
            globPattern: p.join(tempDir.path, '**.dart'),
          );
          final keys = await scanner.scan();

          // Only direct hardcoded strings are extracted
          expect(keys, contains('hardcoded_key'));

          // Variable-based key is NOT extracted
          expect(keys, isNot(contains('variable_key')));

          // Ternary expression also NOT extracted (current limitation)
          expect(keys, isNot(contains('ternary_true')));
          expect(keys, isNot(contains('ternary_false')));
        },
      );

      test('problematic real-world pattern: enum/constant mapping', () async {
        final file = File(p.join(tempDir.path, 'test.dart'));
        await file.writeAsString('''
          enum Status { loading, success, error }

          extension StatusExt on Status {
            String get label {
              switch (this) {
                case Status.loading:
                  return 'status.loading';
                case Status.success:
                  return 'status.success';
                case Status.error:
                  return 'status.error';
              }
            }
          }

          void main() {
            final status = Status.loading;
            print(status.label.tr()); // NOT extractable!
          }
        ''');

        final scanner = CodeScanner(
          globPattern: p.join(tempDir.path, '**.dart'),
        );
        final keys = await scanner.scan();

        // None of these keys are extracted
        expect(keys, isNot(contains('status.loading')));
        expect(keys, isNot(contains('status.success')));
        expect(keys, isNot(contains('status.error')));
        expect(keys, isEmpty);
      });
    });

    group('trKey() extraction (solution for variable keys)', () {
      test('extracts LazyLoc.trKey() calls', () async {
        final file = File(p.join(tempDir.path, 'test.dart'));
        await file.writeAsString('''
          void main() {
            print(LazyLoc.trKey('key_from_trKey'));
            print(LazyLoc.trKey("double_quoted_key"));
          }
        ''');

        final scanner = CodeScanner(
          globPattern: p.join(tempDir.path, '**.dart'),
        );
        final keys = await scanner.scan();

        expect(keys, contains('key_from_trKey'));
        expect(keys, contains('double_quoted_key'));
      });

      test('extracts trKey() without LazyLoc prefix', () async {
        final file = File(p.join(tempDir.path, 'test.dart'));
        await file.writeAsString('''
          void main() {
            print(trKey('standalone_trKey'));
          }
        ''');

        final scanner = CodeScanner(
          globPattern: p.join(tempDir.path, '**.dart'),
        );
        final keys = await scanner.scan();

        expect(keys, contains('standalone_trKey'));
      });

      test('solution: use trKey() for enum/constant mapping', () async {
        final file = File(p.join(tempDir.path, 'test.dart'));
        await file.writeAsString('''
          enum Status { loading, success, error }

          extension StatusExt on Status {
            String get label {
              switch (this) {
                case Status.loading:
                  return LazyLoc.trKey('status.loading');
                case Status.success:
                  return LazyLoc.trKey('status.success');
                case Status.error:
                  return LazyLoc.trKey('status.error');
              }
            }
          }

          void main() {
            final status = Status.loading;
            print(status.label); // Now extractable!
          }
        ''');

        final scanner = CodeScanner(
          globPattern: p.join(tempDir.path, '**.dart'),
        );
        final keys = await scanner.scan();

        // Now all keys are extracted!
        expect(keys, contains('status.loading'));
        expect(keys, contains('status.success'));
        expect(keys, contains('status.error'));
      });
    });

    group('variable .tr() warning detection', () {
      test('detects variable.tr() and generates warnings', () async {
        final file = File(p.join(tempDir.path, 'test.dart'));
        await file.writeAsString('''
          void main() {
            final key = 'dynamic_key';
            print(key.tr());
            print(someVariable.tr());
          }
        ''');

        final scanner = CodeScanner(
          globPattern: p.join(tempDir.path, '**.dart'),
        );
        final result = await scanner.scanWithWarnings();

        expect(result.warnings, isNotEmpty);
        expect(result.warnings.length, equals(2));
        expect(result.warnings[0].matchedText, contains('key.tr()'));
        expect(result.warnings[1].matchedText, contains('someVariable.tr()'));
      });

      test('does not warn for literal string .tr()', () async {
        final file = File(p.join(tempDir.path, 'test.dart'));
        await file.writeAsString('''
          void main() {
            print('literal'.tr());
          }
        ''');

        final scanner = CodeScanner(
          globPattern: p.join(tempDir.path, '**.dart'),
        );
        final result = await scanner.scanWithWarnings();

        expect(result.warnings, isEmpty);
        expect(result.keys, contains('literal'));
      });

      test('detects chained property access .tr()', () async {
        final file = File(p.join(tempDir.path, 'test.dart'));
        await file.writeAsString('''
          void main() {
            print(status.label.tr());
            print(obj.prop.nestedProp.tr());
          }
        ''');

        final scanner = CodeScanner(
          globPattern: p.join(tempDir.path, '**.dart'),
        );
        final result = await scanner.scanWithWarnings();

        expect(result.warnings.length, equals(2));
        expect(result.warnings[0].matchedText, contains('status.label.tr()'));
        expect(
          result.warnings[1].matchedText,
          contains('obj.prop.nestedProp.tr()'),
        );
      });
    });
  });
}
