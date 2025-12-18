import 'dart:io';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';

/// Result of scanning code for translation keys
class ScanResult {
  final Set<String> keys;
  final List<VariableTrWarning> warnings;

  ScanResult({required this.keys, required this.warnings});
}

/// Warning for variable-based .tr() calls that cannot be extracted
class VariableTrWarning {
  final String filePath;
  final int line;
  final String matchedText;

  VariableTrWarning({
    required this.filePath,
    required this.line,
    required this.matchedText,
  });

  @override
  String toString() => '$filePath:$line - $matchedText';
}

class CodeScanner {
  final String globPattern;

  CodeScanner({this.globPattern = 'lib/**.dart'});

  /// Scans for translation keys and returns only the keys (backward compatible)
  Future<Set<String>> scan() async {
    final result = await scanWithWarnings();
    return result.keys;
  }

  /// Scans for translation keys and returns both keys and warnings
  Future<ScanResult> scanWithWarnings() async {
    // Match 'text'.tr() or "text".tr() ensuring matching quotes,
    // handling escaped quotes and whitespace around .tr()
    // Group 1: Opening quote (' or ")
    // Group 2: String content (handling escaped chars and ignoring closing quote)
    final literalTrRegExp = RegExp(
      r"""(['"])((?:\\.|(?!\1).)*)\1\s*\.\s*tr\(\s*\)""",
      dotAll: true,
    );

    // Match LazyLoc.trKey('text') or trKey('text')
    // Group 1: Opening quote
    // Group 2: String content
    final trKeyRegExp = RegExp(
      r"""(?:LazyLoc\s*\.\s*)?trKey\s*\(\s*(['"])((?:\\.|(?!\1).)*)\1\s*\)""",
      dotAll: true,
    );

    // Match variable.tr() patterns (identifier followed by .tr())
    // This detects non-literal .tr() calls
    final variableTrRegExp = RegExp(
      r"""([a-zA-Z_][a-zA-Z0-9_]*(?:\[[^\]]+\])?(?:\.[a-zA-Z_][a-zA-Z0-9_]*)*)\s*\.\s*tr\(\s*\)""",
    );

    final Set<String> codeKeys = {};
    final List<VariableTrWarning> warnings = [];

    final dartFiles = Glob(globPattern);
    await for (var entity in dartFiles.list()) {
      if (entity is File) {
        final content = await File(entity.path).readAsString();

        // Extract 'literal'.tr() keys
        for (var match in literalTrRegExp.allMatches(content)) {
          if (match.group(2) != null) {
            codeKeys.add(_unescape(match.group(2)!));
          }
        }

        // Extract trKey('literal') keys
        for (var match in trKeyRegExp.allMatches(content)) {
          if (match.group(2) != null) {
            codeKeys.add(_unescape(match.group(2)!));
          }
        }

        // Detect variable.tr() patterns and warn
        for (var match in variableTrRegExp.allMatches(content)) {
          final fullMatch = match.group(0)!;
          final identifier = match.group(1)!;

          // Skip if this is actually a literal string (already handled)
          if (identifier.startsWith("'") || identifier.startsWith('"')) {
            continue;
          }

          // Calculate line number
          final beforeMatch = content.substring(0, match.start);
          final lineNumber = beforeMatch.split('\n').length;

          warnings.add(
            VariableTrWarning(
              filePath: entity.path,
              line: lineNumber,
              matchedText: fullMatch.trim(),
            ),
          );
        }
      }
    }
    return ScanResult(keys: codeKeys, warnings: warnings);
  }

  String _unescape(String input) {
    return input.replaceAllMapped(RegExp(r'\\(.)'), (match) {
      final char = match.group(1);
      switch (char) {
        case 'n':
          return '\n';
        case 'r':
          return '\r';
        case 't':
          return '\t';
        case 'b':
          return '\b';
        case 'f':
          return '\f';
        case '\\':
          return '\\';
        case "'":
          return "'";
        case '"':
          return '"';
        case '\$':
          return '\$';
        default:
          return char!;
      }
    });
  }
}
