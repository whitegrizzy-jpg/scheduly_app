import 'package:flutter/material.dart';

// 1. Event 데이터 구조 정의
class CalendarEvent {
  final int id;
  final String date;
  final String title;
  final String time;
  final Color color;

  CalendarEvent({
    required this.id,
    required this.date,
    required this.title,
    required this.time,
    required this.color,
  });
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // 2. 더미 데이터 세팅 (EVENTS)
  final List<CalendarEvent> _events = [
    CalendarEvent(id: 1, date: '2026-09-23', title: '캡스톤 보고서 제출', time: '18:00', color: const Color(0xFFFF6B6B)),
    CalendarEvent(id: 2, date: '2026-09-25', title: '팀 미팅', time: '14:00', color: const Color(0xFF6C63FF)),
    CalendarEvent(id: 3, date: '2026-09-26', title: '알고리즘 과제 마감', time: '23:59', color: const Color(0xFFFBBF24)),
    CalendarEvent(id: 4, date: '2026-10-01', title: '개천절 공휴일', time: '종일', color: const Color(0xFF4ADE80)),
    CalendarEvent(id: 5, date: '2026-10-05', title: '중간고사 시작', time: '09:00', color: const Color(0xFFFF6B6B)),
    CalendarEvent(id: 6, date: '2026-09-30', title: '교수님 면담', time: '13:00', color: const Color(0xFF6C63FF)),
  ];

  final List<String> _days = ['일', '월', '화', '수', '목', '금', '토'];

  // 3. 상태 관리 변수 (today를 기준으로 초기화)
  late DateTime _today;
  late int _year;
  late int _month; 
  late int _selectedDay;

  @override
  void initState() {
    super.initState();
    _today = DateTime(2026, 9, 23);
    _year = _today.year;
    _month = _today.month;
    _selectedDay = _today.day;
  }

  // 4. 월 이동 로직
  void _prevMonth() {
    setState(() {
      if (_month == 1) {
        _year -= 1;
        _month = 12;
      } else {
        _month -= 1;
      }
      _selectedDay = 1;
    });
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) {
        _year += 1;
        _month = 1;
      } else {
        _month += 1;
      }
      _selectedDay = 1;
    });
  }

  // 5. 유틸리티 함수들
  String _dateStr(int day) {
    return '$_year-${_month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  List<CalendarEvent> _eventsFor(int day) {
    return _events.where((e) => e.date == _dateStr(day)).toList();
  }
  @override
  Widget build(BuildContext context) {
    // 6. 달력 날짜 칸 수 계산 영역
    final firstDayOfWeek = DateTime(_year, _month, 1).weekday % 7;
    final daysInMonth = DateTime(_year, _month + 1, 0).day;
    final totalCells = firstDayOfWeek + daysInMonth;

    final selectedEvents = _eventsFor(_selectedDay);

    final theme = Theme.of(context);
    final colorSurface = theme.cardColor;
    final colorText = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 타이틀 텍스트
              Text(
                '📆 개인 캘린더',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorText),
              ),
              const SizedBox(height: 20),

              // 월 이동 내비게이션 & 요일/날짜 격자판을 감싸는 박스
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: colorSurface,
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Column(
                  children: [
                    // 상단 < 2026년 9월 > 화살표 제어판
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: _prevMonth,
                          icon: const Text('‹', style: TextStyle(fontSize: 24)),
                        ),
                        Text(
                          '$_year년 $_month월',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorText),
                        ),
                        IconButton(
                          onPressed: _nextMonth,
                          icon: const Text('›', style: TextStyle(fontSize: 24)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 일, 월, 화, 수 ... 요일 헤더 격자
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                      ),
                      itemCount: 7,
                      itemBuilder: (context, index) {
                        Color dayColor = Colors.grey;
                        if (index == 0) dayColor = const Color(0xFFFF6B6B); // 일요일 색상
                        if (index == 6) dayColor = const Color(0xFF6C63FF); // 토요일 색상

                        return Center(
                          child: Text(
                            _days[index],
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: dayColor),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),

                    // 1일 ~ 말일까지 배치되는 날짜 숫자 격자판
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                      ),
                      itemCount: totalCells,
                      itemBuilder: (context, index) {
                        // 이전 달 빈칸 공백 처리
                        if (index < firstDayOfWeek) {
                          return const SizedBox.shrink();
                        }

                        final day = index - firstDayOfWeek + 1;
                        final isToday = day == _today.day && _month == _today.month && _year == _today.year;
                        final isSelected = day == _selectedDay;
                        final dayEvents = _eventsFor(day);
                        final dayOfWeek = index % 7;

                        // 배경색 분기 (선택됨, 오늘, 일반)
                        Color cellBg = Colors.transparent;
                        if (isSelected) {
                          cellBg = const Color(0xFF6C63FF);
                        } else if (isToday) {
                          cellBg = const Color(0xFF6C63FF).withValues(alpha: 0.15);
                        }

                        // 글자색 분기 (선택됨, 오늘, 주말 여부)
                        Color textStyleColor = colorText;
                        if (isSelected) {
                          textStyleColor = Colors.white;
                        } else if (isToday) {
                          textStyleColor = const Color(0xFF6C63FF);
                        } else if (dayOfWeek == 0) {
                          textStyleColor = const Color(0xFFFF6B6B);
                        } else if (dayOfWeek == 6) {
                          textStyleColor = const Color(0xFF818CF8);
                        }

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedDay = day;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: cellBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$day',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textStyleColor),
                                ),
                                const SizedBox(height: 2),
                                // 날짜 칸 내부 하단의 작은 도트(일정 점 표시) 목록
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: dayEvents.take(3).map((e) {
                                    return Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 0.5),
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected ? Colors.white.withValues(alpha: 0.7) : e.color,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // 🌿 선택된 날짜의 일정 목록 영역 타이틀
              Text(
                '$_month월 $_selectedDay일의 일정',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
              const SizedBox(height: 12),

              // 해당 날짜에 일정이 있을 때와 없을 때의 조건문 처리
              if (selectedEvents.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: colorSurface,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: const Column(
                    children: [
                      Text('🌿', style: TextStyle(fontSize: 24)),
                      SizedBox(height: 8),
                      Text('일정이 없습니다', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: selectedEvents.length,
                  itemBuilder: (context, index) {
                    final event = selectedEvents[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: colorSurface,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border(
                          left: BorderSide(color: event.color, width: 3.0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorText),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            event.time,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              // ➕ 일정 추가 버튼 바형태 위젯
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  // 일정 추가 팝업이나 페이지 이동 로직을 연결하세요.
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: colorSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  side: const BorderSide(color: Colors.grey),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('+', style: TextStyle(color: Colors.grey)),
                    SizedBox(width: 8),
                    Text('일정 추가', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
