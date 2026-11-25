import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scheduly_app/data/remote_todo_store.dart';
import 'package:scheduly_app/data/sync_service.dart';
import 'package:scheduly_app/data/todo_repository.dart';
import 'package:scheduly_app/models/todo.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 기기 한 대 = 로컬 SQLite + 동기화 엔진 + 네트워크 스위치
class Device {
  final SqfliteTodoRepository local;
  final SyncService sync;
  final StreamController<bool> net;
  final SyncingTodoRepository repo;

  Device._(this.local, this.sync, this.net, this.repo);

  static Future<Device> create(
    String dbPath,
    RemoteTodoStore server,
    int Function() clock, {
    bool online = true,
  }) async {
    final local = SqfliteTodoRepository(
      dbFactory: databaseFactoryFfi,
      dbPath: dbPath,
      seedSamples: false,
      now: clock,
    );
    final net = StreamController<bool>.broadcast();
    final sync = SyncService(
      local: local,
      remote: server,
      connectivity: net.stream,
      initiallyOnline: online,
      retryInterval: const Duration(hours: 1),
    );
    await sync.start();
    return Device._(local, sync, net, SyncingTodoRepository(local, sync));
  }

  /// 네트워크 상태를 바꾸고 이벤트 처리를 기다린다.
  Future<void> setOnline(bool v) async {
    net.add(v);
    await Future<void>.delayed(Duration.zero);
    await sync.syncNow();
  }

  Future<void> dispose() async {
    sync.dispose();
    await net.close();
    await local.close();
  }
}

Todo todo(int id, String text) => Todo(
  id: id,
  text: text,
  done: false,
  due: '기한 없음',
  priority: 'mid',
  createdAt: id,
);

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late InMemoryRemoteTodoStore server;
  late Device a;
  late Device b;
  var t = 1000;
  int clock() => t++;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('scheduly_sync');
    server = InMemoryRemoteTodoStore();
    a = await Device.create('${dir.path}/a.db', server, clock);
    b = await Device.create('${dir.path}/b.db', server, clock);
  });

  tearDown(() async {
    await a.dispose();
    await b.dispose();
    await server.close();
    await dir.delete(recursive: true);
  });

  test('TC-08 기기 A에서 추가한 할 일이 기기 B 새로고침 후 보인다', () async {
    await a.repo.insert(todo(1, '기기 A에서 추가'));
    await a.sync.syncNow();
    expect(server.docs.containsKey(1), isTrue);

    await b.sync.syncNow(); // 새로고침
    final listB = await b.repo.loadAll();
    expect(listB.map((e) => e.text), contains('기기 A에서 추가'));
    expect(await a.local.pendingCount(), 0);
  });

  test('TC-09 오프라인에서 쓴 항목은 대기열에 남았다가 온라인 복귀 시 서버에 반영된다', () async {
    await a.setOnline(false);
    await a.repo.insert(todo(2, '오프라인 작성'));
    await a.repo.insert(todo(3, '오프라인 작성 2'));
    await a.sync.syncNow();

    expect(a.sync.status, SyncStatus.offline);
    expect(await a.local.pendingCount(), 2);
    expect(server.docs, isEmpty);
    expect((await a.repo.loadAll()).length, 2, reason: '오프라인에서도 화면에는 바로 보인다');

    await a.setOnline(true); // 온라인 복귀
    expect(server.docs.keys, containsAll([2, 3]));
    expect(await a.local.pendingCount(), 0);
    expect(a.sync.status, SyncStatus.synced);

    await b.sync.syncNow();
    expect((await b.repo.loadAll()).length, 2);
  });

  test('충돌: 두 기기가 오프라인에서 같은 항목을 고치면 나중에 고친 쪽이 이긴다(LWW)', () async {
    await a.repo.insert(todo(4, '원본'));
    await a.sync.syncNow();
    await b.sync.syncNow();

    await a.setOnline(false);
    await b.setOnline(false);
    final orig = (await a.repo.loadAll()).first;
    await a.repo.update(orig.copyWith(text: 'A가 먼저 수정')); // 더 이른 시각
    await b.repo.update(orig.copyWith(text: 'B가 나중에 수정')); // 더 늦은 시각

    // A가 먼저 온라인 → 서버에 A 값, 이후 B가 온라인 → B가 더 최신이라 덮어씀
    await a.setOnline(true);
    expect(server.docs[4]!.text, 'A가 먼저 수정');
    await b.setOnline(true);
    expect(server.docs[4]!.text, 'B가 나중에 수정');

    await a.sync.syncNow();
    expect((await a.repo.loadAll()).first.text, 'B가 나중에 수정');
    expect((await b.repo.loadAll()).first.text, 'B가 나중에 수정');
  });

  test('충돌: 서버가 더 최신이면 늦게 올라온 옛 수정은 버려지고 서버 값으로 맞춰진다', () async {
    await a.repo.insert(todo(5, '원본'));
    await a.sync.syncNow();
    await b.sync.syncNow();

    await a.setOnline(false);
    final orig = (await a.repo.loadAll()).first;
    await a.repo.update(orig.copyWith(text: 'A 오프라인 수정(옛날)'));
    await b.repo.update(orig.copyWith(text: 'B 온라인 수정(최신)'));
    await b.sync.syncNow();

    await a.setOnline(true);
    expect(server.docs[5]!.text, 'B 온라인 수정(최신)');
    expect((await a.repo.loadAll()).first.text, 'B 온라인 수정(최신)');
    expect(await a.local.pendingCount(), 0);
  });

  test('삭제도 다른 기기에 전파된다 (삭제 표시)', () async {
    await a.repo.insert(todo(6, '지울 항목'));
    await a.sync.syncNow();
    await b.sync.syncNow();
    expect((await b.repo.loadAll()).length, 1);

    await a.repo.delete(6);
    await a.sync.syncNow();
    expect(server.docs[6]!.deleted, isTrue);

    await b.sync.syncNow();
    expect(await b.repo.loadAll(), isEmpty);
  });

  test('서버 오류(네트워크 불안정)면 대기열을 유지하고 다음 동기화에서 다시 올린다', () async {
    server.reachable = false;
    await a.repo.insert(todo(7, '재시도 항목'));
    await a.sync.syncNow();
    expect(a.sync.status, SyncStatus.error);
    expect(await a.local.pendingCount(), 1);

    server.reachable = true;
    await a.sync.syncNow();
    expect(server.docs.containsKey(7), isTrue);
    expect(await a.local.pendingCount(), 0);
  });

  test('MP2(v1) DB를 쓰던 기기도 데이터를 잃지 않고 v2로 올라간다', () async {
    final path = '${dir.path}/old.db';
    final v1 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute(
            'CREATE TABLE todos (id INTEGER PRIMARY KEY, text TEXT NOT NULL, '
            'done INTEGER NOT NULL DEFAULT 0, due TEXT NOT NULL, '
            'priority TEXT NOT NULL, created_at INTEGER NOT NULL)',
          );
          await db.insert('todos', {
            'id': 9,
            'text': 'MP2 시절 할 일',
            'done': 0,
            'due': '기한 없음',
            'priority': 'mid',
            'created_at': 9,
          });
        },
      ),
    );
    await v1.close();

    final upgraded = SqfliteTodoRepository(
      dbFactory: databaseFactoryFfi,
      dbPath: path,
    );
    final items = await upgraded.loadAll();
    expect(items.single.text, 'MP2 시절 할 일');
    expect(
      await upgraded.pendingCount(),
      1,
      reason: '기존 데이터는 첫 로그인 때 서버로 올라간다',
    );
    await upgraded.close();
  });
}
