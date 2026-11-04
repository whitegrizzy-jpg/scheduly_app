import 'package:flutter/material.dart';
import '../main.dart';
import '../constants/app_colors.dart';

// const TABS = [...]
class TabItem {
  final ActiveScreen id;
  final String label;
  final String icon;

  const TabItem({required this.id, required this.label, required this.icon});
}

const List<TabItem> tabs = [
  TabItem(id: ActiveScreen.home, label: '홈', icon: '🏠'),
  TabItem(id: ActiveScreen.calendar, label: '캘린더', icon: '📅'),
  TabItem(id: ActiveScreen.group, label: '단체', icon: '👥'),
  TabItem(id: ActiveScreen.handwriting, label: '손글씨', icon: '✍️'),
];

class BottomNav extends StatelessWidget {
  final ActiveScreen active;
  final ValueChanged<ActiveScreen> onChange;

  const BottomNav({
    super.key,
    required this.active,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    // React의 fixed bottom-0 max-w-md 구조를 Flutter의 Container 스타일로 대응
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge, // overflow-hidden 대응
        child: Row(
          children: tabs.map((tab) {
            final bool isActive = active == tab.id;
            return Expanded(
              child: InkWell(
                onTap: () => onChange(tab.id),
                child: SizedBox(
                  height: 60,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 활성화된 탭 상단 바 (absolute top-0 w-8 h-0.5)
                      if (isActive)
                        Positioned(
                          top: 0,
                          child: Container(
                            width: 32,
                            height: 2,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      // 아이콘 및 라벨
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(tab.icon, style: const TextStyle(fontSize: 20)),
                          const SizedBox(height: 2),
                          Text(
                            tab.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isActive
                                  ? AppColors.primaryLight
                                  : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}