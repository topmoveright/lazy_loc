import 'dart:io';

/// A simple logger for CLI output to replace direct print calls.
class Logger {
  static void info(String message) {
    stdout.writeln(message);
  }

  static void error(String message) {
    stderr.writeln(message);
  }

  static void warn(String message) {
    stdout.writeln(message);
  }
}
