import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/group_schedule_screen.dart';
import 'screens/handwriting_screen.dart';
import 'components/bottom_nav.dart';

// export type Screen = 'home' | 'calendar' | 'group' | 'handwriting'
enum ActiveScreen { home, calendar, group, handwriting }

// export const MOCK_USER = { id: 'user1', name: '김민준', email: 'minjun@example.com' }
class MockUser {
  static const String id = 'user1';
  static const String name = '김민준';
  static const String email = 'minjun@example.com';
}

void main() {
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
  ActiveScreen _activeScreen = ActiveScreen.home;

  @override
  Widget build(BuildContext context) {
    // if (!loggedIn) return <LoginScreen onLogin={() => setLoggedIn(true)} />
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
            constraints: const BoxConstraints(maxWidth: 448), // Tailwind max-w-md
            child: Column(
              children: [
                // 화면 본문 영역 (flex-1 overflow-y-auto)
                Expanded(
                  child: _buildCurrentScreen(),
                ),
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
        return const HandwritingScreen();
    }
  }
}