import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/todo.dart';
import 'sample_todos.dart';

/// 화면이 사용하는 할 일 저장소 인터페이스.
abstract class TodoRepository {
  Future<List<Todo>> loadAll();
  Future<void> insert(Todo todo);
  Future<void> update(Todo todo);
  Future<void> delete(int id);
}

/// 동기화 엔진이 추가로 쓰는 로컬 저장소 기능.
abstract class SyncableTodoStore implements TodoRepository {
  /// 서버에 아직 올라가지 않은 변경(추가·수정·삭제 표시 포함)
  Future<List<Todo>> pendingChanges();

  /// 서버 반영 완료. 그 사이 다시 수정됐으면(updatedAt 다름) 대기 상태를 유지한다.
  Future<void> markSynced(int id, int updatedAt);

  /// 서버에서 받은 항목을 반영한다. 반영했으면 true.
  /// 충돌 규칙: updatedAt이 더 큰 쪽이 이긴다(Last-Write-Wins).
  Future<bool> applyRemote(Todo remote);

  Future<int> pendingCount();
}

/// sqflite(SQLite) 기반 로컬 저장소. 앱을 껐다 켜도 데이터가 유지된다.
///
/// MP3: 각 행에 updated_at·deleted·sync_status 칼럼을 두어 오프라인 변경을 대기열로 관리한다.
class SqfliteTodoRepository implements SyncableTodoStore {
  static const _table = 'todos';
  static const _pending = 'pending';
  static const _synced = 'synced';

  final DatabaseFactory? dbFactory;
  final String? dbPath;
  final String dbName;

  /// 처음 DB를 만들 때 시험 데이터를 넣을지 (로컬 전용 모드에서만 true)
  final bool seedSamples;
  final int Function() _now;
  Database? _db;

  /// [dbFactory]·[dbPath]·[now]는 테스트 주입용이다.
  SqfliteTodoRepository({
    this.dbFactory,
    this.dbPath,
    this.dbName = 'scheduly.db',
    this.seedSamples = true,
    int Function()? now,
  }) : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final factory = dbFactory ?? databaseFactory;
    final path = dbPath ?? p.join(await factory.getDatabasesPath(), dbName);
    _db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $_table (
              id INTEGER PRIMARY KEY,
              text TEXT NOT NULL,
              done INTEGER NOT NULL DEFAULT 0,
              due TEXT NOT NULL,
              priority TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL DEFAULT 0,
              deleted INTEGER NOT NULL DEFAULT 0,
              sync_status TEXT NOT NULL DEFAULT '$_pending'
            )
          ''');
          if (seedSamples) {
            // 최초 설치 시에만 시험 데이터를 넣는다.
            final batch = db.batch();
            for (final t in buildSampleTodos()) {
              batch.insert(_table, {...t.toMap(), 'sync_status': _pending});
            }
            await batch.commit(noResult: true);
          }
        },
        // MP2(v1) DB를 쓰던 기기: 데이터는 지키고 동기화 칼럼만 추가한다.
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute(
              'ALTER TABLE $_table ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0',
            );
            await db.execute(
              'ALTER TABLE $_table ADD COLUMN deleted INTEGER NOT NULL DEFAULT 0',
            );
            await db.execute(
              "ALTER TABLE $_table ADD COLUMN sync_status TEXT NOT NULL DEFAULT '$_pending'",
            );
            await db.execute('UPDATE $_table SET updated_at = created_at');
          }
        },
      ),
    );
    return _db!;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  @override
  Future<List<Todo>> loadAll() async {
    final db = await _database;
    final rows = await db.query(
      _table,
      where: 'deleted = 0',
      orderBy: 'created_at DESC',
    );
    return rows.map(Todo.fromMap).toList();
  }

  /// 화면에서 생긴 변경: 수정 시각을 새로 찍고 '대기' 상태로 저장한다.
  Future<void> _saveLocal(Todo todo) async {
    final db = await _database;
    final stamped = todo.copyWith(updatedAt: _now());
    await db.insert(_table, {
      ...stamped.toMap(),
      'sync_status': _pending,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> insert(Todo todo) => _saveLocal(todo.copyWith(deleted: false));

  @override
  Future<void> update(Todo todo) => _saveLocal(todo);

  /// 삭제: 행을 바로 지우지 않고 삭제 표시만 해 둔다(다른 기기에도 삭제를 전달하기 위해).
  @override
  Future<void> delete(int id) async {
    final db = await _database;
    final rows = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return;
    await _saveLocal(Todo.fromMap(rows.first).copyWith(deleted: true));
  }

  @override
  Future<List<Todo>> pendingChanges() async {
    final db = await _database;
    final rows = await db.query(
      _table,
      where: 'sync_status = ?',
      whereArgs: [_pending],
      orderBy: 'updated_at ASC',
    );
    return rows.map(Todo.fromMap).toList();
  }

  @override
  Future<int> pendingCount() async {
    final db = await _database;
    final r = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM $_table WHERE sync_status = ?',
      [_pending],
    );
    return (r.first['c'] as int?) ?? 0;
  }

  @override
  Future<void> markSynced(int id, int updatedAt) async {
    final db = await _database;
    await db.update(
      _table,
      {'sync_status': _synced},
      where: 'id = ? AND updated_at = ?',
      whereArgs: [id, updatedAt],
    );
  }

  @override
  Future<bool> applyRemote(Todo remote) async {
    final db = await _database;
    final rows = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [remote.id],
    );
    if (rows.isNotEmpty) {
      final local = Todo.fromMap(rows.first);
      // 로컬이 같거나 더 최신이면 서버 값을 무시한다(로컬 변경은 이후 서버로 올라감).
      if (local.updatedAt >= remote.updatedAt) return false;
    }
    await db.insert(_table, {
      ...remote.toMap(),
      'sync_status': _synced,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return true;
  }
}

/// 메모리 저장소 (위젯 테스트용). 앱을 다시 시작하면 사라진다.
class InMemoryTodoRepository implements TodoRepository {
  final Map<int, Todo> _items;

  InMemoryTodoRepository([List<Todo>? seed])
    : _items = {for (final t in seed ?? buildSampleTodos()) t.id: t};

  @override
  Future<List<Todo>> loadAll() async =>
      _items.values.where((t) => !t.deleted).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<void> insert(Todo todo) async => _items[todo.id] = todo;

  @override
  Future<void> update(Todo todo) async => _items[todo.id] = todo;

  @override
  Future<void> delete(int id) async => _items.remove(id);
}
