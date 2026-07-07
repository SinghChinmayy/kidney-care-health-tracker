import 'dart:async';

import 'package:app/data/local/app_database.dart';
import 'package:app/data/sync/sync_coordinator.dart';
import 'package:app/data/sync/sync_engine.dart';
import 'package:app/data/sync/syncable_table.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

void main() {
  late AppDatabase db;
  late _BlockingSyncTable blockingTable;
  late SyncCoordinator coordinator;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    blockingTable = _BlockingSyncTable();
    final engine = SyncEngine(
      db: db,
      supabase: SupabaseClient('http://localhost:54321', 'test-anon-key'),
      currentAuthUserId: () => null,
      registry: [blockingTable],
    );
    coordinator = SyncCoordinator(engine: engine);
  });

  tearDown(() async {
    coordinator.dispose();
    blockingTable.release();
    await db.close();
  });

  test('queues follow-up run when sync is already in progress', () async {
    final firstRun = coordinator.run();
    await Future<void>.delayed(Duration.zero);
    expect(blockingTable.pushCount, 1);

    await coordinator.run();
    expect(blockingTable.pushCount, 1);

    blockingTable.release();
    await firstRun;
    await Future<void>.delayed(Duration.zero);

    expect(blockingTable.pushCount, 2);
  });
}

class _BlockingSyncTable implements SyncableTable {
  _BlockingSyncTable();

  final _blocker = Completer<void>();
  int pushCount = 0;

  @override
  String get tableKey => 'blocking';

  @override
  String get remoteTableName => 'blocking';

  @override
  Future<void> push(SupabaseClient supabase) async {
    pushCount++;
    await _blocker.future;
  }

  @override
  Future<void> pull(SupabaseClient supabase) async {}

  void release() {
    if (!_blocker.isCompleted) {
      _blocker.complete();
    }
  }
}
