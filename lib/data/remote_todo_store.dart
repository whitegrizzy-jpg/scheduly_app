import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/todo.dart';

/// 서버(BaaS) 쪽 할 일 저장소 인터페이스.
abstract class RemoteTodoStore {
  /// 서버 목록의 실시간 변경 스트림 (삭제 표시된 항목 포함)
  Stream<List<Todo>> watch();

  /// 서버 목록 전체 (새로고침용)
  Future<List<Todo>> fetchAll();

  /// 서버 값보다 [todo]가 더 최신일 때만 기록한다.
  /// 반환값은 최종 승자: 기록했으면 [todo], 서버가 더 최신이면 서버 값.
  Future<Todo> pushIfNewer(Todo todo);
}

/// Cloud Firestore 구현: users/{uid}/todos/{todoId}
/// 보안 규칙으로 본인(uid)만 읽고 쓸 수 있다. (README 참고)
class FirestoreTodoStore implements RemoteTodoStore {
  final FirebaseFirestore firestore;
  final String uid;

  FirestoreTodoStore({required this.firestore, required this.uid});

  CollectionReference<Map<String, dynamic>> get _col =>
      firestore.collection('users').doc(uid).collection('todos');

  @override
  Stream<List<Todo>> watch() => _col.snapshots().map(
    (s) => s.docs.map((d) => Todo.fromRemote(d.data())).toList(),
  );

  @override
  Future<List<Todo>> fetchAll() async {
    final s = await _col.get(const GetOptions(source: Source.server));
    return s.docs.map((d) => Todo.fromRemote(d.data())).toList();
  }

  @override
  Future<Todo> pushIfNewer(Todo todo) {
    final ref = _col.doc('${todo.id}');
    // 트랜잭션: 서버 값을 읽고 비교한 뒤 쓰기를 한 번에 처리해, 두 기기가 동시에 올려도
    // 더 최신(updatedAt이 큰) 쪽만 남는다.
    return firestore.runTransaction<Todo>((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (data != null) {
        final server = Todo.fromRemote(data);
        if (server.updatedAt >= todo.updatedAt) return server;
      }
      tx.set(ref, todo.toRemote());
      return todo;
    });
  }
}

/// 메모리 서버 (테스트용). 여러 기기(SyncService)가 같은 인스턴스를 공유하면 "같은 서버"가 된다.
class InMemoryRemoteTodoStore implements RemoteTodoStore {
  final Map<int, Todo> docs = {};
  final _controller = StreamController<List<Todo>>.broadcast();

  /// false면 네트워크 오류처럼 예외를 던진다.
  bool reachable = true;

  void _check() {
    if (!reachable) throw StateError('network unreachable');
  }

  @override
  Stream<List<Todo>> watch() => _controller.stream;

  @override
  Future<List<Todo>> fetchAll() async {
    _check();
    return docs.values.toList();
  }

  @override
  Future<Todo> pushIfNewer(Todo todo) async {
    _check();
    final server = docs[todo.id];
    if (server != null && server.updatedAt >= todo.updatedAt) return server;
    docs[todo.id] = todo;
    _controller.add(docs.values.toList());
    return todo;
  }

  Future<void> close() => _controller.close();
}
