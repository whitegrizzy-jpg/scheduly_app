import 'package:flutter/material.dart';

import 'constants/app_colors.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/group_schedule_screen.dart';
import 'screens/memo_scan_screen.dart';
import 'ocr/memo_ocr_service.dart';
import 'components/bottom_nav.dart';
import 'services/app_services.dart';

export 'services/app_services.dart';

// export type Screen = 'home' | 'calendar' | 'group' | 'handwriting'
enum ActiveScreen { home, calendar, group, handwriting }

// 데모 사용자 (실제 개인정보 아님)
class MockUser {
  static const String name = '데모 사용자';
  static const String initial = 'D';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // .env(--dart-define-from-file)에 Firebase 값이 있으면 초기화, 없으면 로컬 전용 모드
  await AppServices.init();
  // 프라이버시: 이전 실행에서 남았을 수 있는 임시 사진을 앱 시작 시 정리
  await PhotoDisposal.purgePickerCache();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scheduly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.bg,
        fontFamily: 'Pretendard',
        useMaterial3: true,
      ),
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _loggedIn = false;
  bool _resuming = false;
  ActiveScreen _activeScreen = ActiveScreen.home;

  @override
  void initState() {
    super.initState();
    // 이전에 로그인한 Firebase 사용자가 있으면 로그인 화면 없이 동기화 세션을 다시 연다.
    final user = AppServices.currentUser;
    if (user != null) {
      _resuming = true;
      AppServices.startCloudSession(user).whenComplete(() {
        if (mounted) {
          setState(() {
            _resuming = false;
            _loggedIn = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // if (!loggedIn) return <LoginScreen onLogin={() => setLoggedIn(true)} />
    if (_resuming) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_loggedIn) {
      return LoginScreen(
        onLogin: () {
          setState(() {
            _loggedIn = true;
          });
        },
      );
    }

    // 로그인 후 메인 레이아웃 (max-w-md mx-auto 대응)
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 448,
            ), // Tailwind max-w-md
            child: Column(
              children: [
                // 화면 본문 영역 (flex-1 overflow-y-auto)
                Expanded(child: _buildCurrentScreen()),
                // 하단 네비게이션 바 (<BottomNav active={activeScreen} onChange={setActiveScreen} />)
                BottomNav(
                  active: _activeScreen,
                  onChange: (screen) {
                    setState(() {
                      _activeScreen = screen;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_activeScreen) {
      case ActiveScreen.home:
        return const HomeScreen();
      case ActiveScreen.calendar:
        return const CalendarScreen();
      case ActiveScreen.group:
        return const GroupScheduleScreen();
      case ActiveScreen.handwriting:
        // MP4: 손글씨 시안 화면 → 실제 온디바이스 OCR 메모 가져오기
        return MemoScanScreen(
          onAdded: (_) => setState(() => _activeScreen = ActiveScreen.home),
        );
    }
  }
}
