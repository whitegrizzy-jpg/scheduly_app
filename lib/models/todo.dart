/// 할 일 항목 모델.
///
/// priority: 'high' | 'mid' | 'low'
class Todo {
  final int id;
  final String text;
  bool done;
  final String due;
  final String priority;

  Todo({
    required this.id,
    required this.text,
    required this.done,
    required this.due,
    required this.priority,
  });
}
