import 'package:flutter/foundation.dart';

/// Lightweight console logger for datasource requests, cache/network state
/// transitions, and responses. No-ops outside debug builds.
class AppLogger {
  const AppLogger._();

  static void request(String tag, String method, [Map<String, dynamic>? params]) {
    if (!kDebugMode) return;
    debugPrint('[$tag] → $method${_formatParams(params)}');
  }

  static void response(String tag, String method, [Object? result]) {
    if (!kDebugMode) return;
    debugPrint('[$tag] ← $method ${_formatResult(result)}');
  }

  static void state(String tag, String message) {
    if (!kDebugMode) return;
    debugPrint('[$tag] • $message');
  }

  static void error(
    String tag,
    String method,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    if (!kDebugMode) return;
    debugPrint('[$tag] ✕ $method failed: $error');
  }

  static String _formatParams(Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) return '()';
    final entries = params.entries.map((e) => '${e.key}=${e.value}').join(', ');
    return '($entries)';
  }

  static String _formatResult(Object? result) {
    if (result == null) return '';
    if (result is List) return '[${result.length} item(s)]';
    if (result is Map) return '{${result.length} key(s)}';
    return '$result';
  }
}
