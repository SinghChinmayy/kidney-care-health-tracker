import 'package:app/data/local/app_database.dart';
import 'package:app/data/sync/sync_coordinator.dart';
import 'package:app/data/sync/sync_engine.dart';
import 'package:app/data/sync/syncable_table.dart';
import 'package:app/ui/features/sync/widgets/sync_status_banner.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late AppDatabase db;
  late _FlakyTable table;
  late bool online;
  late SyncCoordinator coordinator;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    table = _FlakyTable();
    online = true;
    coordinator = SyncCoordinator(
      engine: SyncEngine(
        db: db,
        supabase: SupabaseClient('http://localhost:54321', 'test-anon-key'),
        currentAuthUserId: () => null,
        registry: [table],
      ),
      isOnline: () async => online,
    );
  });

  tearDown(() async {
    coordinator.dispose();
    await db.close();
  });

  Future<void> pumpBanner(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SyncStatusBanner(coordinator: coordinator)),
      ),
    );
  }

  testWidgets('hidden while sync is healthy', (tester) async {
    await pumpBanner(tester);
    await tester.runAsync(coordinator.run);
    await tester.pump();

    expect(find.text(SyncStatusBanner.offlineMessage), findsNothing);
    expect(find.text(SyncStatusBanner.errorMessage), findsNothing);
  });

  testWidgets('shows offline banner when the probe fails', (tester) async {
    await pumpBanner(tester);
    online = false;
    await tester.runAsync(coordinator.run);
    await tester.pump();

    expect(find.text(SyncStatusBanner.offlineMessage), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('error banner retries on tap and hides after success',
      (tester) async {
    await pumpBanner(tester);
    table.fail = true;
    await tester.runAsync(coordinator.run);
    await tester.pump();
    expect(find.text(SyncStatusBanner.errorMessage), findsOneWidget);

    table.fail = false;
    await tester.runAsync(() async {
      await tester.tap(find.text('Retry'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();

    expect(table.pulls, 2);
    expect(find.text(SyncStatusBanner.errorMessage), findsNothing);
  });
}

class _FlakyTable implements SyncableTable {
  bool fail = false;
  int pulls = 0;

  @override
  String get tableKey => 'flaky';

  @override
  String get remoteTableName => 'flaky';

  @override
  Future<void> push(SupabaseClient supabase, SyncScope scope) async {}

  @override
  Future<void> pull(SupabaseClient supabase, SyncScope scope) async {
    pulls++;
    if (fail) {
      throw StateError('boom');
    }
  }
}
