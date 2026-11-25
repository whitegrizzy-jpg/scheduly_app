import '../models/todo.dart';

/// 시험 데이터: 데이터베이스가 처음 만들어질 때 한 번만 넣는 더미 할 일 목록.
/// 실제 인물·연락처 등 개인정보를 포함하지 않는다.
List<Todo> buildSampleTodos() => const [
  Todo(
    id: 1,
    text: '캡스톤 설계 보고서 제출',
    done: false,
    due: '오늘 18:00',
    priority: 'high',
    createdAt: 4,
  ),
  Todo(
    id: 2,
    text: '알고리즘 과제 3번 풀기',
    done: false,
    due: '내일 23:59',
    priority: 'mid',
    createdAt: 3,
  ),
  Todo(
    id: 3,
    text: '데이터베이스 중간고사 공부',
    done: false,
    due: '10월 15일',
    priority: 'mid',
    createdAt: 2,
  ),
  Todo(
    id: 4,
    text: '체육관 예약하기',
    done: true,
    due: '완료',
    priority: 'low',
    createdAt: 1,
  ),
];
