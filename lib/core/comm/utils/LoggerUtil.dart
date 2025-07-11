import 'package:flutter/foundation.dart'; // For kDebugMode

// ANSI escape codes for colors
class _LogColors {
  static const String reset = '\x1B[0m';
  static const String black = '\x1B[30m';
  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String magenta = '\x1B[35m';
  static const String cyan = '\x1B[36m';
  static const String white = '\x1B[37m';

  // Bright versions
  static const String brightBlack = '\x1B[90m';
  static const String brightRed = '\x1B[91m';
  static const String brightGreen = '\x1B[92m';
  static const String brightYellow = '\x1B[93m';
  static const String brightBlue = '\x1B[94m';
  static const String brightMagenta = '\x1B[95m';
  static const String brightCyan = '\x1B[96m';
  static const String brightWhite = '\x1B[97m';
}

enum LogLevel {
  debug, // For detailed debugging information
  info,  // General information about app flow
  warn,  // Potential issues or unexpected situations
  error, // Errors that have occurred
  wtf,   // "What a Terrible Failure" - for critical errors
}

class Log {
  // --- Configuration ---
  static LogLevel currentLogLevel = kDebugMode ? LogLevel.debug : LogLevel.info; // Default level
  static bool showTimestamp = true;
  static bool showLogLevel = true;
  static bool useColors = kDebugMode; // Only use colors in debug mode by default

  static String _timestamp() {
    if (!showTimestamp) return '';
    final now = DateTime.now();
    return '[${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}] ';
  }

  static String _levelPrefix(LogLevel level) {
    if (!showLogLevel) return '';
    switch (level) {
      case LogLevel.debug:
        return '[DEBUG] ';
      case LogLevel.info:
        return '[INFO] ';
      case LogLevel.warn:
        return '[WARN] ';
      case LogLevel.error:
        return '[ERROR] ';
      case LogLevel.wtf:
        return '[WTF] ';
    }
  }

  static void _log(LogLevel level, String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (level.index < currentLogLevel.index) {
      return; // Don't log if the level is below the current configured level
    }

    String colorCode;
    switch (level) {
      case LogLevel.debug:
        colorCode = _LogColors.brightBlue; // Or _LogColors.cyan
        break;
      case LogLevel.info:
        colorCode = _LogColors.brightGreen;
        break;
      case LogLevel.warn:
        colorCode = _LogColors.brightYellow;
        break;
      case LogLevel.error:
        colorCode = _LogColors.brightRed;
        break;
      case LogLevel.wtf:
        colorCode = _LogColors.magenta; // Or brightMagenta for more emphasis
        break;
    }

    final StringBuffer buffer = StringBuffer();
    if (useColors) buffer.write(colorCode);

    buffer.write(_timestamp());
    buffer.write(_levelPrefix(level));

    if (tag != null) {
      buffer.write('[$tag] ');
    }
    buffer.write(message);

    if (error != null) {
      buffer.write('\n  Error: $error');
    }
    if (stackTrace != null) {
      buffer.write('\n  StackTrace: \n$stackTrace');
    }

    if (useColors) buffer.write(_LogColors.reset);

    // Use debugPrint to avoid truncation, or print for simplicity
    // debugPrint can be slower for large volumes of logs
    // For critical logs like error, you might always want to print.
    if (level.index >= LogLevel.error.index) {
      // Using regular print for errors to ensure they are less likely to be throttled
      print(buffer.toString());
    } else {
      debugPrint(buffer.toString());
    }
  }

  // --- Public Logging Methods ---

  /// Log a debug message (most verbose).
  static void d(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Log an info message.
  static void i(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Log a warning message.
  static void w(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warn, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Log an error message.
  static void e(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Log a "What a Terrible Failure" message for critical errors.
  static void wtf(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.wtf, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  // --- Configuration Methods ---
  static void setLogLevel(LogLevel level) {
    currentLogLevel = level;
  }

  static void enableColors(bool enable) {
    useColors = enable;
  }

  static void enableTimestamp(bool enable) {
    showTimestamp = enable;
  }

  static void enableLogLevelPrefix(bool enable) {
    showLogLevel = enable;
  }
}

// --- Example Usage ---
