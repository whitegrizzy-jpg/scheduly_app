import 'login_screen.dart';

import 'package:flutter/material.dart';

// Figma 테마 색상 정의 (프로젝트 스타일에 맞게 수정 가능)
class _Theme {
  static const Color background = Color(0xfff8f9fa); // 기본 배경
  static const Color surface = Colors.white; // 카드 및 입력창 배경
  static const Color surface2 = Color(0xffe9ecef); // 보조 버튼 배경
  static const Color text = Color(0xff212529); // 기본 텍스트
  static const Color muted = Color(0xff6c757d); // 부연 설명 텍스트
  static const Color border = Color(0xffdee2e6); // 테두리 선
  static const Color primary = Color(0xff6c63ff); // 메인 포인트 색상
  static const Color primaryLight = Color(0xff8c85ff); // 연한 포인트 색상
  static const Color accent = Color(0xffff6b6b); // 강조 (오늘 마감 등)
  static const Color green = Color(0xff4ade80); // 완료 색상
}

// 데이터 모델 정의
class Todo {
  final int id;
  final String text;
  bool done;
  final String due;
  final String priority; // 'high' | 'mid' | 'low'

  Todo({
    required this.id,
    required this.text,
    required this.done,
    required this.due,
    required this.priority,
  });
}

class Memo {
  final int id;
  final String text;
  final Color color;
  final String date;

  Memo({
    required this.id,
    required this.text,
    required this.color,
    required this.date,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 우선순위 매핑 상수
  final Map<String, Color> priorityColor = {
    'high': const Color(0xffff6b6b),
    'mid': const Color(0xfffbbf24),
    'low': const Color(0xff4ade80),
  };

  final Map<String, String> priorityLabel = {
    'high': '긴급',
    'mid': '보통',
    'low': '여유',
  };

  // 상태 데이터 정의
  late List<Todo> _todos;
  late List<Memo> _memos;

  bool _showInput = false;
  final TextEditingController _todoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _todos = [
      Todo(
        id: 1,
        text: '캡스톤 설계 보고서 제출',
        done: false,
        due: '오늘 18:00',
        priority: 'high',
      ),
      Todo(
        id: 2,
        text: '알고리즘 과제 3번 풀기',
        done: false,
        due: '내일 23:59',
        priority: 'mid',
      ),
      Todo(
        id: 3,
        text: '데이터베이스 중간고사 공부',
        done: false,
        due: '10월 15일',
        priority: 'mid',
      ),
      Todo(id: 4, text: '체육관 예약하기', done: true, due: '완료', priority: 'low'),
    ];

    _memos = [
      Memo(
        id: 1,
        text: '팀 회의 시 아이디어 발표 준비\n- UI 흐름도\n- 역할 분담안',
        color: const Color(0xff6c63ff),
        date: '9월 23일',
      ),
      Memo(
        id: 2,
        text: '교수님 면담 → 연구실 302호 방문',
        color: const Color(0xffff6b6b),
        date: '9월 22일',
      ),
    ];
  }

  @override
  void dispose() {
    _todoController.dispose();
    super.dispose();
  }

  // 로직 함수들 구현
  void _addTodo() {
    final text = _todoController.text;
    if (text.trim().isEmpty) return;

    setState(() {
      _todos.insert(
        0,
        Todo(
          id: DateTime.now().millisecondsSinceEpoch,
          text: text,
          done: false,
          due: '기한 없음',
          priority: 'mid',
        ),
      );
      _todoController.clear();
      _showInput = false;
    });
  }

  void _toggleTodo(int id) {
    setState(() {
      for (var todo in _todos) {
        if (todo.id == id) {
          todo.done = !todo.done;
        }
      }
    });
  }

  void _deleteMemo(int id) {
    setState(() {
      _memos.removeWhere((m) => m.id == id);
    });
  }

  void _addBlankMemo() {
    setState(() {
      _memos.insert(
        0,
        Memo(
          id: DateTime.now().millisecondsSinceEpoch,
          text: '새 메모',
          color: const Color(0xff6c63ff),
          date: '오늘',
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final pending = _todos.where((t) => !t.done).toList();
    final done = _todos.where((t) => t.done).toList();
    final todayDueCount = _todos.where((t) => t.due.contains('오늘')).length;

    return Scaffold(
      backgroundColor: _Theme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (안녕하세요, 김민준님)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '안녕하세요 👋',
                        style: TextStyle(color: _Theme.muted, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '김민준님',
                        style: TextStyle(
                          color: _Theme.text,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: _Theme.muted,
                            fontSize: 14,
                          ),
                          children: [
                            const TextSpan(text: '오늘 '),
                            TextSpan(
                              text: '${pending.length}개',
                              style: const TextStyle(
                                color: _Theme.primaryLight,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(text: '의 할 일이 남아있어요'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      // 프로필 화면으로 이동 (추후 구현할 ProfileScreen 클래스로 연결)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [_Theme.primary, Color(0xffa78bfa)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '김',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Stats Grid (남은 할 일, 오늘 마감, 완료)
              Row(
                children: [
                  _buildStatCard(
                    '📋',
                    '${pending.length}',
                    '남은 할 일',
                    _Theme.primary,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    '🔥',
                    '$todayDueCount',
                    '오늘 마감',
                    _Theme.accent,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard('✅', '${done.length}', '완료', _Theme.green),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Todos Title & Toggle Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '📋 할 일',
                    style: TextStyle(
                      color: _Theme.text,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showInput = !_showInput),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _Theme.primary,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _showInput ? '×' : '+',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Todo Input Field
              if (_showInput) ...[
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: _Theme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _Theme.border),
                        ),
                        child: TextField(
                          controller: _todoController,
                          autofocus: true,
                          style: const TextStyle(
                            color: _Theme.text,
                            fontSize: 14,
                          ),
                          decoration: const InputDecoration(
                            hintText: '새 할 일 입력...',
                            hintStyle: TextStyle(color: _Theme.muted),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _addTodo(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addTodo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _Theme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '추가',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Todo List Items (진행 중 / 완료됨 리스트)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...pending.map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: _TodoCardWidget(
                        todo: t,
                        onToggle: _toggleTodo,
                        priorityColor: priorityColor,
                        priorityLabel: priorityLabel,
                      ),
                    ),
                  ),
                  if (done.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0, bottom: 4.0),
                      child: Text(
                        '완료됨',
                        style: TextStyle(color: _Theme.muted, fontSize: 12),
                      ),
                    ),
                    ...done.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _TodoCardWidget(
                          todo: t,
                          onToggle: _toggleTodo,
                          priorityColor: priorityColor,
                          priorityLabel: priorityLabel,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              // 4. Memos Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '📝 메모',
                    style: TextStyle(
                      color: _Theme.text,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: _addBlankMemo,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _Theme.surface2,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '+',
                        style: TextStyle(
                          color: _Theme.muted,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Memo List Items (좌측 컬러 보더 & 스택 내 닫기 버튼 구조)
              Column(
                children: _memos
                    .map(
                      (m) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: _Theme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border(
                            left: BorderSide(color: m.color, width: 3),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    m.text,
                                    style: const TextStyle(
                                      color: _Theme.text,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    m.date,
                                    style: const TextStyle(
                                      color: _Theme.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: _Theme.muted,
                                ),
                                onPressed: () => _deleteMemo(m.id),
                                splashRadius: 16,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 대시보드 통계 카드 빌더 함수
  Widget _buildStatCard(
    String icon,
    String value,
    String label,
    Color valueColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _Theme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: _Theme.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// 5. TodoCard Component 위젯 구현 (모든 경고 및 최신 API 반영 완료)
class _TodoCardWidget extends StatelessWidget {
  final Todo todo;
  final Function(int) onToggle;
  final Map<String, Color> priorityColor;
  final Map<String, String> priorityLabel;

  const _TodoCardWidget({
    required this.todo,
    required this.onToggle,
    required this.priorityColor,
    required this.priorityLabel,
  });

  @override
  Widget build(BuildContext context) {
    final pColor = priorityColor[todo.priority] ?? Colors.grey;
    final pLabel = priorityLabel[todo.priority] ?? '보통';

    return Opacity(
      opacity: todo.done ? 0.5 : 1.0,
      child: InkWell(
        onTap: () => onToggle(todo.id),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: _Theme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // 커스텀 원형 체크박스 인터페이스
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: todo.done ? _Theme.green : pColor,
                    width: 2,
                  ),
                  color: todo.done ? _Theme.green : Colors.transparent,
                ),
                alignment: Alignment.center,
                child: todo.done
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              // 중앙 할 일 텍스트 및 마감 기한
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _Theme.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        decoration: todo.done
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      todo.due,
                      style: const TextStyle(color: _Theme.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 우측 우선순위 태그 배지
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  // 최신 Flutter 버전 권장 문법 .withValues(alpha: 0.12)로 수정 완료!
                  color: pColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  pLabel,
                  style: TextStyle(
                    color: pColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 새로운 프로필 및 로그아웃 화면 위젯
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Theme.background, // 기존 배경색 유지
      appBar: AppBar(
        title: const Text(
          '프로필 정보',
          style: TextStyle(
            color: _Theme.text,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: _Theme.surface,
        iconTheme: const IconThemeData(color: _Theme.text),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: _Theme.border, height: 1.0), // 하단 테두리 선
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // 대형 프로필 아바타
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_Theme.primary, Color(0xffa78bfa)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '김',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '김민준님',
                style: TextStyle(
                  color: _Theme.text,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'minjun@example.com',
                style: TextStyle(color: _Theme.muted, fontSize: 14),
              ),
              const SizedBox(height: 40),

              // 계정 관리 영역 카드
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _Theme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildMenuRow('내 계정 설정', Icons.arrow_forward_ios),
                    const Divider(color: _Theme.border, height: 24),
                    _buildMenuRow('알림 설정', Icons.arrow_forward_ios),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 🛑 로그아웃 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // 로그아웃 확인 다이얼로그 띄우기
                    _showLogoutDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Theme.accent, // 테마의 강조 색상 (빨간색 계열) 사용
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '로그아웃',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 메뉴 항목 빌더
  Widget _buildMenuRow(String title, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _Theme.text,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        Icon(icon, size: 14, color: _Theme.muted),
      ],
    );
  }

  // 로그아웃 확인 팝업창
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _Theme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '로그아웃',
            style: TextStyle(color: _Theme.text, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            '정말 로그아웃 하시겠습니까?',
            style: TextStyle(color: _Theme.muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // 팝업 닫기
              child: const Text('취소', style: TextStyle(color: _Theme.muted)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // 1. 우선 로그아웃 팝업창을 닫습니다.

                // 2. ✨ 핵심 기능을 가진 실제 코드 작동:
                // 이전의 모든 화면 기록을 지우고 분리된 실제 LoginScreen으로 이동시킵니다.
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(onLogin: () {}),
                  ),
                  (route) => false, // 이 조건에 의해 이전의 모든 뒤로가기 기록이 파괴됩니다.
                );
              },
              child: const Text(
                '확인',
                style: TextStyle(
                  color: _Theme.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
