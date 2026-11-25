import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/todo.dart';
import 'remote_todo_store.dart';
import 'todo_repository.dart';

enum SyncStatus { offline, syncing, synced, error }

/// 로컬(SQLite)과 서버(BaaS)를 맞추는 동기화 엔진.
///
/// 흐름
/// 1. 화면의 모든 변경은 먼저 로컬 DB에 '대기(pending)'로 저장된다 → 오프라인에서도 바로 동작.
/// 2. 온라인이면 대기 항목을 오래된 순서로 서버에 올린다(push).
/// 3. 서버의 실시간 변경(watch)과 새로고침(fetchAll)을 로컬에 반영한다(pull).
/// 4. 충돌은 updatedAt이 더 큰 쪽이 이긴다(Last-Write-Wins). 삭제도 삭제 표시로 같은 규칙을 따른다.
class SyncService extends ChangeNotifier {
  final SyncableTodoStore local;
  final RemoteTodoStore remote;
  final Stream<bool> connectivity;
  final Duration retryInterval;

  SyncService({
    required this.local,
    required this.remote,
    required this.connectivity,
    bool initiallyOnline = true,
    this.retryInterval = const Duration(seconds: 20),
  }) : _online = initiallyOnline;

  bool _online;
  bool get online => _online;

  SyncStatus _status = SyncStatus.offline;
  SyncStatus get status => _status;

  int _pending = 0;
  int get pendingCount => _pending;

  DateTime? _lastSyncedAt;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  /// 서버 변경이 로컬에 반영될 때마다 증가 → 화면이 목록을 다시 읽는다.
  int _dataVersion = 0;
  int get dataVersion => _dataVersion;

  StreamSubscription<bool>? _connSub;
  StreamSubscription<List<Todo>>? _remoteSub;
  Timer? _retry;
  Future<void>? _running;
  bool _again = false;
  bool _disposed = false;

  Future<void> start() async {
    _connSub = connectivity.listen((isOnline) {
      final cameBack = isOnline && !_online;
      _online = isOnline;
      if (!isOnline) _setStatus(SyncStatus.offline);
      if (cameBack) syncNow(); // 온라인 복귀 → 대기열 업로드
    });
    _remoteSub = remote.watch().listen(
      _applyRemoteList,
      onError: (_) {}, // 오프라인 등으로 끊기면 무시하고 재연결을 기다린다
    );
    _retry = Timer.periodic(retryInterval, (_) {
      if (_online && _pending > 0) syncNow();
    });
    await _refreshPending();
    if (_online) {
      await syncNow();
    } else {
      _setStatus(SyncStatus.offline);
    }
  }

  /// 로컬 변경 직후 호출된다.
  Future<void> onLocalChange() async {
    await _refreshPending();
    if (_online) await syncNow();
  }

  /// 대기열 업로드 + 서버 목록 새로고침. 실행 중에 다시 불리면 끝난 뒤 한 번 더 돈다.
  Future<void> syncNow() {
    if (_running != null) {
      _again = true;
      return _running!;
    }
    _running = _runLoop().whenComplete(() => _running = null);
    return _running!;
  }

  Future<void> _runLoop() async {
    do {
      _again = false;
      await _syncOnce();
    } while (_again && !_disposed);
  }

  Future<void> _syncOnce() async {
    if (!_online || _disposed) {
      _setStatus(SyncStatus.offline);
      return;
    }
    _setStatus(SyncStatus.syncing);
    try {
      // push: 오래된 변경부터 순서대로
      for (final change in await local.pendingChanges()) {
        final winner = await remote.pushIfNewer(change);
        if (winner.updatedAt == change.updatedAt) {
          await local.markSynced(change.id, change.updatedAt);
        } else if (await local.applyRemote(winner)) {
          _dataVersion++; // 서버가 더 최신 → 서버 값으로 덮음
        }
      }
      // pull: 서버 전체를 받아 더 최신인 것만 반영
      await _applyRemoteList(await remote.fetchAll(), notify: false);
      _lastSyncedAt = DateTime.now();
      await _refreshPending(notify: false);
      _setStatus(SyncStatus.synced);
    } catch (_) {
      await _refreshPending(notify: false);
      _setStatus(_online ? SyncStatus.error : SyncStatus.offline);
    }
  }

  Future<void> _applyRemoteList(List<Todo> items, {bool notify = true}) async {
    var changed = false;
    for (final t in items) {
      if (await local.applyRemote(t)) changed = true;
    }
    if (changed) {
      _dataVersion++;
      if (notify) _notify();
    }
  }

  Future<void> _refreshPending({bool notify = true}) async {
    _pending = await local.pendingCount();
    if (notify) _notify();
  }

  void _setStatus(SyncStatus s) {
    _status = s;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _connSub?.cancel();
    _remoteSub?.cancel();
    _retry?.cancel();
    super.dispose();
  }
}

/// 화면용 저장소: 로컬에 쓰고 나서 동기화 엔진에 알린다.
class SyncingTodoRepository implements TodoRepository {
  final SyncableTodoStore local;
  final SyncService sync;

  SyncingTodoRepository(this.local, this.sync);

  @override
  Future<List<Todo>> loadAll() => local.loadAll();

  @override
  Future<void> insert(Todo todo) async {
    await local.insert(todo);
    unawaited(sync.onLocalChange());
  }

  @override
  Future<void> update(Todo todo) async {
    await local.update(todo);
    unawaited(sync.onLocalChange());
  }

  @override
  Future<void> delete(int id) async {
    await local.delete(id);
    unawaited(sync.onLocalChange());
  }
}
