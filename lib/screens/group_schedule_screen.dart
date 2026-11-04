import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

// Member 모델
class GroupMember {
  final String id;
  final String name;
  final String avatar;
  String status; // 'accepted' | 'declined' | 'pending'

  GroupMember({
    required this.id,
    required this.name,
    required this.avatar,
    required this.status,
  });
}

// Schedule 모델
class GroupSchedule {
  final int id;
  final String title;
  final String group;
  final String date;
  final String time;
  final String location;
  final String description;
  String myStatus; // 'accepted' | 'declined' | 'pending'
  final List<GroupMember> members;

  GroupSchedule({
    required this.id,
    required this.title,
    required this.group,
    required this.date,
    required this.time,
    required this.location,
    required this.description,
    required this.myStatus,
    required this.members,
  });
}

// 상태별 색상 및 라벨 맵
const Map<String, Color> statusColorMap = {
  'accepted': Color(0xFF4ADE80),
  'declined': Color(0xFFFF6B6B),
  'pending': Color(0xFFFBBF24),
};

const Map<String, String> statusLabelMap = {
  'accepted': '참여',
  'declined': '거절',
  'pending': '미응답',
};

const Map<String, Color> statusBgMap = {
  'accepted': Color(0x1F4ADE80), // rgba(74,222,128,0.12)
  'declined': Color(0x1FFF6B6B), // rgba(255,107,107,0.12)
  'pending': Color(0x1FFBBF24),  // rgba(251,191,36,0.12)
};

class GroupScheduleScreen extends StatefulWidget {
  const GroupScheduleScreen({super.key});

  @override
  State<GroupScheduleScreen> createState() => _GroupScheduleScreenState();
}

class _GroupScheduleScreenState extends State<GroupScheduleScreen> {
  // 초기 데이터 (React 버전과 동일)
  final List<GroupSchedule> _schedules = [
    GroupSchedule(
      id: 1,
      title: '캡스톤 팀 킥오프 미팅',
      group: '캡스톤 설계팀',
      date: '2026-09-25',
      time: '14:00 – 16:00',
      location: '공학관 304호',
      description: '프로젝트 역할 분담 및 일정 수립',
      myStatus: 'accepted',
      members: [
        GroupMember(id: 'm1', name: '김민준', avatar: '김', status: 'accepted'),
        GroupMember(id: 'm2', name: '이서연', avatar: '이', status: 'accepted'),
        GroupMember(id: 'm3', name: '박도현', avatar: '박', status: 'pending'),
        GroupMember(id: 'm4', name: '최유진', avatar: '최', status: 'declined'),
        GroupMember(id: 'm5', name: '정하은', avatar: '정', status: 'accepted'),
      ],
    ),
    GroupSchedule(
      id: 2,
      title: 'DB 스터디',
      group: '데이터베이스 스터디',
      date: '2026-09-27',
      time: '10:00 – 12:00',
      location: '도서관 스터디룸 2',
      description: '7장 정규화 개념 정리 및 퀴즈',
      myStatus: 'pending',
      members: [
        GroupMember(id: 'n1', name: '김민준', avatar: '김', status: 'pending'),
        GroupMember(id: 'n2', name: '오지민', avatar: '오', status: 'accepted'),
        GroupMember(id: 'n3', name: '윤채원', avatar: '윤', status: 'accepted'),
        GroupMember(id: 'n4', name: '강태양', avatar: '강', status: 'accepted'),
      ],
    ),
    GroupSchedule(
      id: 3,
      title: '동아리 정기 모임',
      group: '코딩 동아리 CTRL',
      date: '2026-10-02',
      time: '18:00 – 20:00',
      location: '학생회관 B102',
      description: '해커톤 준비 및 신입 환영회',
      myStatus: 'declined',
      members: [
        GroupMember(id: 'p1', name: '김민준', avatar: '김', status: 'declined'),
        GroupMember(id: 'p2', name: '한수아', avatar: '한', status: 'accepted'),
        GroupMember(id: 'p3', name: '임지호', avatar: '임', status: 'accepted'),
        GroupMember(id: 'p4', name: '서민재', avatar: '서', status: 'pending'),
        GroupMember(id: 'p5', name: '노예린', avatar: '노', status: 'accepted'),
        GroupMember(id: 'p6', name: '백준혁', avatar: '백', status: 'accepted'),
      ],
    ),
  ];

  int? _expandedId = 1; // 기본 1번 카드 확장

  void _respond(int id, String status) {
    setState(() {
      for (var s in _schedules) {
        if (s.id == id) {
          s.myStatus = status;
          for (var m in s.members) {
            if (m.name == '김민준') {
              m.status = status;
            }
          }
        }
      }
    });
  }

  String _bestTime(GroupSchedule s) {
    final acc = s.members.where((m) => m.status == 'accepted').length;
    return '$acc명 참여 가능';
  }

  @override
  Widget build(BuildContext context) {
    // 요약 바 계산
    final int acceptedCount = _schedules.where((s) => s.myStatus == 'accepted').length;
    final int pendingCount = _schedules.where((s) => s.myStatus == 'pending').length;
    final int declinedCount = _schedules.where((s) => s.myStatus == 'declined').length;

    // 정렬: 미응답(pending)인 일정을 위로 배치 (.sort 모사)
    List<GroupSchedule> sortedSchedules = List.from(_schedules);
    sortedSchedules.sort((a, b) {
      if (a.myStatus == 'pending' && b.myStatus != 'pending') return -1;
      if (a.myStatus != 'pending' && b.myStatus == 'pending') return 1;
      return 0;
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '👥 단체 스케쥴',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '참여 가능 인원 기준으로 일정이 정리됩니다',
                style: TextStyle(fontSize: 14, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Summary Bar (3 columns)
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  label: '참여 예정',
                  count: acceptedCount,
                  color: const Color(0xFF4ADE80),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  label: '미응답',
                  count: pendingCount,
                  color: const Color(0xFFFBBF24),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  label: '거절',
                  count: declinedCount,
                  color: const Color(0xFFFF6B6B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Schedule List
          Column(
            children: sortedSchedules.map((s) {
              final bool isOpen = _expandedId == s.id;
              final statusColor = statusColorMap[s.myStatus] ?? AppColors.primary;
              final statusLabel = statusLabelMap[s.myStatus] ?? '미응답';
              final statusBg = statusBgMap[s.myStatus] ?? AppColors.surface2;

              final acceptedMembers = s.members.where((m) => m.status == 'accepted').toList();
              final pendingMembers = s.members.where((m) => m.status == 'pending').toList();
              final declinedMembers = s.members.where((m) => m.status == 'declined').toList();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Card Header Button
                    InkWell(
                      onTap: () {
                        setState(() {
                          _expandedId = isOpen ? null : s.id;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: statusBg,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              statusLabel,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: statusColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            s.group,
                                            style: const TextStyle(fontSize: 12, color: AppColors.muted),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        s.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.text,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text('📅 ${s.date}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                                          const SizedBox(width: 12),
                                          Text('🕐 ${s.time}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  isOpen ? '▲' : '▽',
                                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Participation Bar
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_bestTime(s), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                                    Text('${s.members.length}명 중', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: s.members.map((m) {
                                    final mColor = statusColorMap[m.status] ?? AppColors.muted;
                                    return Expanded(
                                      child: Container(
                                        height: 8,
                                        margin: const EdgeInsets.symmetric(horizontal: 1),
                                        decoration: BoxDecoration(
                                          color: mColor,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text('참여 ${acceptedMembers.length}', style: const TextStyle(fontSize: 12, color: Color(0xFF4ADE80))),
                                    const SizedBox(width: 12),
                                    Text('미응답 ${pendingMembers.length}', style: const TextStyle(fontSize: 12, color: Color(0xFFFBBF24))),
                                    const SizedBox(width: 12),
                                    Text('거절 ${declinedMembers.length}', style: const TextStyle(fontSize: 12, color: Color(0xFFFF6B6B))),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Expanded Detail Section
                    if (isOpen) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(color: AppColors.border, height: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('📍', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 8),
                                Text(s.location, style: const TextStyle(fontSize: 14, color: AppColors.text)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('📝', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 8),
                                Text(s.description, style: const TextStyle(fontSize: 14, color: AppColors.text)),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Members by Status Group
                            ...[
                              {'label': '✅ 참여', 'members': acceptedMembers, 'color': const Color(0xFF4ADE80)},
                              {'label': '⏳ 미응답', 'members': pendingMembers, 'color': const Color(0xFFFBBF24)},
                              {'label': '❌ 거절', 'members': declinedMembers, 'color': const Color(0xFFFF6B6B)},
                            ].where((g) => (g['members'] as List).isNotEmpty).map((g) {
                              final gColor = g['color'] as Color;
                              final gMembers = g['members'] as List<GroupMember>;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${g['label']} ${gMembers.length}명',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: gColor),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: gMembers.map((m) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppColors.surface2,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 20,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  color: gColor.withValues(alpha: 0.3),
                                                  shape: BoxShape.circle,
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  m.avatar,
                                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: gColor),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(m.name, style: const TextStyle(fontSize: 12, color: AppColors.text)),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 8),

                            // RSVP Action Buttons
                            if (s.myStatus == 'pending')
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _respond(s.id, 'accepted'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0x264ADE80),
                                        foregroundColor: const Color(0xFF4ADE80),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        side: const BorderSide(color: Color(0x4D4ADE80)),
                                      ),
                                      child: const Text('✅ 참여하기', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _respond(s.id, 'declined'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0x26FF6B6B),
                                        foregroundColor: const Color(0xFFFF6B6B),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        side: const BorderSide(color: Color(0x4DFF6B6B)),
                                      ),
                                      child: const Text('❌ 거절하기', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              )
                            else
                              SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  onPressed: () => _respond(
                                    s.id,
                                    s.myStatus == 'accepted' ? 'declined' : 'accepted',
                                  ),
                                  style: TextButton.styleFrom(
                                    backgroundColor: AppColors.surface2,
                                    foregroundColor: AppColors.muted,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('응답 변경하기', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // New Group Schedule Button
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('+ 단체 일정 만들기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({required String label, required int count, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}