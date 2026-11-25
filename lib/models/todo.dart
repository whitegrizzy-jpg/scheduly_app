/// 할 일 항목 모델.
///
/// priority: 'high' | 'mid' | 'low'
/// createdAt: 정렬 기준(밀리초). 큰 값이 목록 위쪽에 온다.
/// updatedAt: 마지막 수정 시각(밀리초). 동기화 충돌 시 더 최근 값이 이긴다(LWW).
/// deleted: 삭제 표시(tombstone). 삭제도 다른 기기로 전파하기 위해 바로 지우지 않는다.
class Todo {
  final int id;
  final String text;
  final bool done;
  final String due;
  final String priority;
  final int createdAt;
  final int updatedAt;
  final bool deleted;

  const Todo({
    required this.id,
    required this.text,
    required this.done,
    required this.due,
    required this.priority,
    required this.createdAt,
    int? updatedAt,
    this.deleted = false,
  }) : updatedAt = updatedAt ?? createdAt;

  Todo copyWith({
    String? text,
    bool? done,
    String? due,
    String? priority,
    int? updatedAt,
    bool? deleted,
  }) {
    return Todo(
      id: id,
      text: text ?? this.text,
      done: done ?? this.done,
      due: due ?? this.due,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
    );
  }

  /// SQLite 행으로 변환 (bool은 0/1 정수로 저장)
  Map<String, Object?> toMap() => {
    'id': id,
    'text': text,
    'done': done ? 1 : 0,
    'due': due,
    'priority': priority,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'deleted': deleted ? 1 : 0,
  };

  factory Todo.fromMap(Map<String, Object?> map) => Todo(
    id: map['id'] as int,
    text: map['text'] as String,
    done: (map['done'] as int) == 1,
    due: map['due'] as String,
    priority: map['priority'] as String,
    createdAt: map['created_at'] as int,
    updatedAt: (map['updated_at'] as int?) ?? map['created_at'] as int,
    deleted: ((map['deleted'] as int?) ?? 0) == 1,
  );

  /// 서버(Firestore) 문서로 변환
  Map<String, Object?> toRemote() => {
    'id': id,
    'text': text,
    'done': done,
    'due': due,
    'priority': priority,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'deleted': deleted,
  };

  factory Todo.fromRemote(Map<String, Object?> m) => Todo(
    id: (m['id'] as num).toInt(),
    text: m['text'] as String? ?? '',
    done: m['done'] as bool? ?? false,
    due: m['due'] as String? ?? '기한 없음',
    priority: m['priority'] as String? ?? 'mid',
    createdAt: (m['createdAt'] as num).toInt(),
    updatedAt: (m['updatedAt'] as num).toInt(),
    deleted: m['deleted'] as bool? ?? false,
  );
}
