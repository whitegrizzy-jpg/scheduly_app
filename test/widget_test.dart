import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scheduly_app/main.dart';

/// 로그인 화면에서 '로그인 없이 둘러보기'로 홈에 진입한다.
Future<void> enterHome(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MyApp());
  await tester.tap(find.byKey(const Key('demo_start')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TC-02 항목 추가: 입력한 할 일이 목록에 미완료로 추가된다', (tester) async {
    await enterHome(tester);
    await tester.tap(find.byKey(const Key('todo_add_toggle')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('todo_input')),
      '모프 9주차 보고서 제출',
    );
    await tester.tap(find.byKey(const Key('todo_add_button')));
    await tester.pump();

    expect(find.text('모프 9주차 보고서 제출'), findsOneWidget);
    expect(find.text('기한 없음'), findsOneWidget);
  });

  testWidgets('TC-03 공백 입력: 추가되지 않고 안내 문구가 보인다', (tester) async {
    await enterHome(tester);
    await tester.tap(find.byKey(const Key('todo_add_toggle')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('todo_input')), '   ');
    await tester.tap(find.byKey(const Key('todo_add_button')));
    await tester.pump();

    expect(find.textContaining('할 일을 입력해주세요'), findsOneWidget);
    expect(find.text('기한 없음'), findsNothing);
  });

  testWidgets('완료 토글: 탭하면 완료됨 영역으로 옮겨지고 취소선이 생긴다', (tester) async {
    await enterHome(tester);
    final title = find.text('캡스톤 설계 보고서 제출');
    await tester.tap(title);
    await tester.pump();

    final text = tester.widget<Text>(title);
    expect(text.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('TC-01 빈 상태: 할 일을 모두 지우면 안내 화면이 보인다', (tester) async {
    await enterHome(tester);
    for (final t in [
      '캡스톤 설계 보고서 제출',
      '알고리즘 과제 3번 풀기',
      '데이터베이스 중간고사 공부',
      '체육관 예약하기',
    ]) {
      await tester.drag(find.text(t), const Offset(-600, 0));
      await tester.pumpAndSettle();
    }

    expect(find.byKey(const Key('todo_empty_state')), findsOneWidget);
    expect(find.text('등록된 할 일이 없습니다'), findsOneWidget);
  });
}
