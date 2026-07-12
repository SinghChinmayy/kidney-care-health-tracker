import 'dart:io';

import 'package:app/core/supabase_config.dart';

/// Lightweight online probe used by the initial sync gate (no connectivity_plus).
class ConnectivityService {
  ConnectivityService({String? probeUrl}) : _probeUrl = probeUrl;

  final String? _probeUrl;

  Future<bool> isOnline() async {
    final probeUrl = _probeUrl ??
        (SupabaseConfig.validationError == null ? SupabaseConfig.url : null);
    if (probeUrl == null) {
      return false;
    }

    final client = HttpClient();
    try {
      client.connectionTimeout = const Duration(seconds: 3);
      final request = await client.headUrl(Uri.parse(probeUrl));
      final response =
          await request.close().timeout(const Duration(seconds: 3));
      return response.statusCode < 500;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }
}
