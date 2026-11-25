/// 할 일 항목 모델.
///
/// priority: 'high' | 'mid' | 'low'
/// createdAt: 정렬 기준(밀리초). 큰 값이 목록 위쪽에 온다.
class Todo {
  final int id;
  final String text;
  final bool done;
  final String due;
  final String priority;
  final int createdAt;

  const Todo({
    required this.id,
    required this.text,
    required this.done,
    required this.due,
    required this.priority,
    required this.createdAt,
  });

  Todo copyWith({String? text, bool? done, String? due, String? priority}) {
    return Todo(
      id: id,
      text: text ?? this.text,
      done: done ?? this.done,
      due: due ?? this.due,
      priority: priority ?? this.priority,
      createdAt: createdAt,
    );
  }

  /// SQLite 행으로 변환 (done은 0/1 정수로 저장)
  Map<String, Object?> toMap() => {
    'id': id,
    'text': text,
    'done': done ? 1 : 0,
    'due': due,
    'priority': priority,
    'created_at': createdAt,
  };

  factory Todo.fromMap(Map<String, Object?> map) => Todo(
    id: map['id'] as int,
    text: map['text'] as String,
    done: (map['done'] as int) == 1,
    due: map['due'] as String,
    priority: map['priority'] as String,
    createdAt: map['created_at'] as int,
  );
}
