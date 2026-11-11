import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Minimal in-memory PostgREST for sync tests. Supports the query shapes
/// the sync engine uses: `select` with `col=eq.x` / `updated_at=gt.t`
/// filters, `upsert` (POST), `update` (PATCH ... ?id=eq.x) and RPC calls.
class FakePostgrest {
  final Map<String, List<Map<String, dynamic>>> tables = {};
  final Map<String, Object? Function(Map<String, dynamic> params)> rpcs = {};
  final List<http.Request> requests = [];
  int _clock = 0;

  /// Server clock: strictly increasing ISO timestamps.
  String nextTimestamp() {
    _clock++;
    return DateTime.utc(2026, 11, 1).add(Duration(seconds: _clock))
        .toIso8601String();
  }

  void seed(String table, Map<String, dynamic> row) {
    tables.putIfAbsent(table, () => []).add({
      'created_at': row['created_at'] ?? nextTimestamp(),
      'updated_at': row['updated_at'] ?? nextTimestamp(),
      ...row,
    });
  }

  List<Map<String, dynamic>> rows(String table) =>
      tables.putIfAbsent(table, () => []);

  SupabaseClient client() {
    return SupabaseClient(
      'http://localhost:54321',
      'anon-key',
      httpClient: MockClient(_handle),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  }

  http.Request? _current;

  Future<http.Response> _handle(http.Request request) async {
    requests.add(request);
    _current = request;
    final segments = request.url.pathSegments;
    if (segments.length >= 3 && segments[1] == 'v1' && segments[2] == 'rpc') {
      final fn = rpcs[segments[3]];
      if (fn == null) {
        return _json({'message': 'no rpc ${segments[3]}'}, 404);
      }
      final params = request.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(request.body) as Map<String, dynamic>;
      return _json(fn(params), 200);
    }

    final table = segments.last;
    final filters = <bool Function(Map<String, dynamic>)>[];
    request.url.queryParametersAll.forEach((key, values) {
      if (const {'select', 'order', 'on_conflict', 'limit', 'columns'}
          .contains(key)) {
        return;
      }
      for (final value in values) {
        final dot = value.indexOf('.');
        final op = value.substring(0, dot);
        final operand = value.substring(dot + 1);
        filters.add((row) {
          final cell = row[key];
          return switch (op) {
            'eq' => '$cell' == operand,
            'gt' => DateTime.parse('$cell').isAfter(DateTime.parse(operand)),
            _ => throw UnsupportedError('filter op $op'),
          };
        });
      }
    });
    bool matches(Map<String, dynamic> row) => filters.every((f) => f(row));

    switch (request.method) {
      case 'GET':
        final result = rows(table).where(matches).toList()
          ..sort((a, b) => '${a['updated_at']}'.compareTo('${b['updated_at']}'));
        final single = request.headers['Accept']?.contains(
              'application/vnd.pgrst.object+json',
            ) ??
            false;
        if (single) {
          return result.isEmpty
              ? _json({'code': 'PGRST116', 'message': 'no rows'}, 406)
              : _json(result.first, 200);
        }
        return _json(result, 200);
      case 'POST':
        final body = jsonDecode(request.body);
        final incoming = (body is List ? body : [body])
            .cast<Map<String, dynamic>>();
        final out = <Map<String, dynamic>>[];
        for (final row in incoming) {
          final existing = rows(table)
              .where((r) => r['id'] == row['id'])
              .toList();
          final stored = {
            ...?(existing.isEmpty ? null : existing.first),
            ...row,
            'updated_at': nextTimestamp(),
          };
          rows(table).removeWhere((r) => r['id'] == row['id']);
          rows(table).add(stored);
          out.add(stored);
        }
        return _json(out, 201);
      case 'PATCH':
        final patch = jsonDecode(request.body) as Map<String, dynamic>;
        final out = <Map<String, dynamic>>[];
        for (final row in rows(table).where(matches)) {
          row.addAll(patch);
          row['updated_at'] = nextTimestamp();
          out.add(Map.of(row));
        }
        return _json(out, 200);
    }
    return _json({'message': 'unsupported'}, 405);
  }

  http.Response _json(Object? body, int status) {
    return http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
      request: _current,
    );
  }
}
