import 'dart:async';

import 'package:app/data/local/app_database.dart';
import 'package:app/data/sync/sync_coordinator.dart';
import 'package:app/data/sync/sync_engine.dart';
import 'package:app/data/sync/sync_status.dart';
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

  group('status and retry', () {
    late _ScriptedSyncTable table;
    late bool online;

    SyncCoordinator buildCoordinator({
      Duration retryInterval = const Duration(seconds: 45),
    }) {
      final engine = SyncEngine(
        db: db,
        supabase: SupabaseClient('http://localhost:54321', 'test-anon-key'),
        currentAuthUserId: () => null,
        registry: [table],
      );
      return SyncCoordinator(
        engine: engine,
        retryInterval: retryInterval,
        isOnline: () async => online,
        clock: () => DateTime.utc(2026, 11, 12, 9),
      );
    }

    setUp(() {
      table = _ScriptedSyncTable();
      online = true;
    });

    test('successful run ends idle with lastSuccessAt', () async {
      final c = buildCoordinator();
      addTearDown(c.dispose);
      final phases = <SyncPhase>[];
      c.status.addListener(() => phases.add(c.status.value.phase));

      await c.run();

      expect(phases, [SyncPhase.syncing, SyncPhase.idle]);
      expect(c.status.value.lastSuccessAt, DateTime.utc(2026, 11, 12, 9));
      expect(c.status.value.needsAttention, isFalse);
    });

    test('table failure surfaces as error with the failing table', () async {
      final c = buildCoordinator();
      addTearDown(c.dispose);
      table.failPull = true;

      await c.run();

      expect(c.status.value.phase, SyncPhase.error);
      expect(c.status.value.failedTables, ['scripted']);
      expect(table.pushCount, 1, reason: 'push still ran');
    });

    test('offline probe skips the engine and reports offline', () async {
      final c = buildCoordinator();
      addTearDown(c.dispose);
      online = false;

      await c.run();

      expect(c.status.value.phase, SyncPhase.offline);
      expect(table.pushCount, 0);

      online = true;
      await c.run();
      expect(c.status.value.phase, SyncPhase.idle);
      expect(table.pushCount, 1);
    });

    test('periodic retry recovers from an error without user action',
        () async {
      final c = buildCoordinator(
        retryInterval: const Duration(milliseconds: 20),
      );
      addTearDown(c.dispose);
      table.failPull = true;
      await c.run();
      expect(c.status.value.phase, SyncPhase.error);

      table.failPull = false;
      c.startPeriodicRetry();
      expect(c.isPeriodicRetryActive, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 70));

      expect(c.status.value.phase, SyncPhase.idle);
      expect(table.pushCount, greaterThanOrEqualTo(2));

      c.stopPeriodicRetry();
      final countAfterStop = table.pushCount;
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(table.pushCount, countAfterStop);
    });

    test('reset clears status and stops the retry loop', () async {
      final c = buildCoordinator();
      addTearDown(c.dispose);
      table.failPull = true;
      await c.run();
      c.startPeriodicRetry();

      c.reset();

      expect(c.status.value.phase, SyncPhase.idle);
      expect(c.isPeriodicRetryActive, isFalse);
    });
  });
}

class _ScriptedSyncTable implements SyncableTable {
  int pushCount = 0;
  bool failPull = false;

  @override
  String get tableKey => 'scripted';

  @override
  String get remoteTableName => 'scripted';

  @override
  Future<void> push(SupabaseClient supabase) async {
    pushCount++;
  }

  @override
  Future<void> pull(SupabaseClient supabase) async {
    if (failPull) {
      throw StateError('pull failed');
    }
  }
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
