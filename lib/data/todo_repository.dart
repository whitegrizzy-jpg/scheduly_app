import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/todo.dart';
import 'sample_todos.dart';

/// 할 일 저장소 인터페이스.
/// 화면은 이 인터페이스만 알고, 실제 저장 방식(SQLite, 메모리, 이후 MP3의 BaaS)은 바꿔 끼운다.
abstract class TodoRepository {
  Future<List<Todo>> loadAll();
  Future<void> insert(Todo todo);
  Future<void> update(Todo todo);
  Future<void> delete(int id);
}

/// sqflite(SQLite) 기반 로컬 저장소. 앱을 껐다 켜도 데이터가 유지된다.
class SqfliteTodoRepository implements TodoRepository {
  static const _dbName = 'scheduly.db';
  static const _table = 'todos';

  final DatabaseFactory? dbFactory;
  final String? dbPath;
  Database? _db;

  /// [dbFactory]·[dbPath]는 테스트에서 메모리 DB를 쓰기 위한 주입점이다.
  SqfliteTodoRepository({this.dbFactory, this.dbPath});

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final factory = dbFactory ?? databaseFactory;
    final path = dbPath ?? p.join(await factory.getDatabasesPath(), _dbName);
    _db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $_table (
              id INTEGER PRIMARY KEY,
              text TEXT NOT NULL,
              done INTEGER NOT NULL DEFAULT 0,
              due TEXT NOT NULL,
              priority TEXT NOT NULL,
              created_at INTEGER NOT NULL
            )
          ''');
          // 최초 설치 시에만 시험 데이터를 넣는다. 사용자가 모두 지우면 빈 상태가 유지된다.
          final batch = db.batch();
          for (final t in buildSampleTodos()) {
            batch.insert(_table, t.toMap());
          }
          await batch.commit(noResult: true);
        },
      ),
    );
    return _db!;
  }

  @override
  Future<List<Todo>> loadAll() async {
    final db = await _database;
    final rows = await db.query(_table, orderBy: 'created_at DESC');
    return rows.map(Todo.fromMap).toList();
  }

  @override
  Future<void> insert(Todo todo) async {
    final db = await _database;
    await db.insert(
      _table,
      todo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> update(Todo todo) async {
    final db = await _database;
    await db.update(
      _table,
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  @override
  Future<void> delete(int id) async {
    final db = await _database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}

/// 메모리 저장소 (위젯 테스트용). 앱을 다시 시작하면 사라진다.
class InMemoryTodoRepository implements TodoRepository {
  final Map<int, Todo> _items;

  InMemoryTodoRepository([List<Todo>? seed])
    : _items = {for (final t in seed ?? buildSampleTodos()) t.id: t};

  @override
  Future<List<Todo>> loadAll() async =>
      _items.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<void> insert(Todo todo) async => _items[todo.id] = todo;

  @override
  Future<void> update(Todo todo) async => _items[todo.id] = todo;

  @override
  Future<void> delete(int id) async => _items.remove(id);
}
