import 'dart:io';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';

class CodeScanner {
  final String globPattern;

  CodeScanner({this.globPattern = 'lib/**.dart'});

  Future<Set<String>> scan() async {
    // Match 'text'.tr() or "text".tr() ensuring matching quotes,
    // handling escaped quotes and whitespace around .tr()
    // Group 1: Opening quote (' or ")
    // Group 2: String content (handling escaped chars and ignoring closing quote)
    final regExp = RegExp(
      r"""(['"])((?:\\.|(?!\1).)*)\1\s*\.\s*tr\(\s*\)""",
      dotAll: true,
    );
    final Set<String> codeKeys = {};

    final dartFiles = Glob(globPattern);
    await for (var entity in dartFiles.list()) {
      if (entity is File) {
        final content = await File(entity.path).readAsString();
        final matches = regExp.allMatches(content);
        for (var match in matches) {
          if (match.group(2) != null) {
            codeKeys.add(_unescape(match.group(2)!));
          }
        }
      }
    }
    return codeKeys;
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
