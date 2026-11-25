import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scheduly_app/data/todo_repository.dart';
import 'package:scheduly_app/models/todo.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// SQLite 저장소 테스트: 실제 파일 DB를 열고 닫았다가 다시 열어 "앱 재시작"을 흉내 낸다.
void main() {
  sqfliteFfiInit();
  late Directory dir;
  late String dbPath;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('scheduly_test');
    dbPath = '${dir.path}/test.db';
  });

  tearDown(() async {
    await databaseFactoryFfi.deleteDatabase(dbPath);
    await dir.delete(recursive: true);
  });

  SqfliteTodoRepository open() =>
      SqfliteTodoRepository(dbFactory: databaseFactoryFfi, dbPath: dbPath);

  test('최초 실행 시 시험 데이터 4개가 들어간다', () async {
    final items = await open().loadAll();
    expect(items.length, 4);
    expect(items.first.text, '캡스톤 설계 보고서 제출');
  });

  test('TC-07 재시작 유지: 추가·완료·수정·삭제가 다시 열어도 남아 있다', () async {
    final repo = open();
    await repo.loadAll();
    const added = Todo(
      id: 100,
      text: '재시작 테스트',
      done: false,
      due: '기한 없음',
      priority: 'mid',
      createdAt: 100,
    );
    await repo.insert(added);
    await repo.update(added.copyWith(done: true, text: '재시작 테스트(수정)'));
    await repo.delete(2);

    // 새 인스턴스 = 앱을 껐다 켠 상황
    final reopened = await open().loadAll();
    expect(reopened.length, 4);
    expect(reopened.first.text, '재시작 테스트(수정)');
    expect(reopened.first.done, isTrue);
    expect(reopened.any((t) => t.id == 2), isFalse);
  });

  test('모두 삭제하면 다시 열어도 빈 목록이다 (시험 데이터 재삽입 없음)', () async {
    final repo = open();
    for (final t in await repo.loadAll()) {
      await repo.delete(t.id);
    }
    expect(await open().loadAll(), isEmpty);
  });
}
