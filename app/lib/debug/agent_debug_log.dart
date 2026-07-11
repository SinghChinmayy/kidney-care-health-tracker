import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Debug-session logger (session e45fa5). Posts to host ingest; also prints.
/// Do not log PII.
void agentDebugLog({
  required String hypothesisId,
  required String location,
  required String message,
  Map<String, Object?> data = const {},
  String runId = 'pre-fix',
}) {
  // #region agent log
  final payload = <String, Object?>{
    'sessionId': 'e45fa5',
    'runId': runId,
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    'data': data,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
  final body = jsonEncode(payload);
  debugPrint('AGENT_DEBUG $body');

  Future<void> post(String host) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(milliseconds: 400);
      final req = await client.postUrl(
        Uri.parse(
          'http://$host:7643/ingest/f83e0040-ade2-4d1e-af2d-1af74852eea1',
        ),
      );
      req.headers.set('Content-Type', 'application/json');
      req.headers.set('X-Debug-Session-Id', 'e45fa5');
      req.add(utf8.encode(body));
      await req.close();
      client.close(force: true);
    } catch (_) {}
  }

  // Android emulator → host is 10.0.2.2; iOS sim / desktop → 127.0.0.1
  post('10.0.2.2');
  post('127.0.0.1');
  // #endregion
}
