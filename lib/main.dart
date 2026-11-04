import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// React CSS 변수 대응 테마 팔레트
class AppColors {
  static const Color bg = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surface2 = Color(0xFFF1F3F5);
  static const Color border = Color(0xFFE9ECEF);
  static const Color text = Color(0xFF212529);
  static const Color muted = Color(0xFF868E96);
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color accent = Color(0xFFFF6B6B);
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
        fontFamily: 'Pretendard', // 시스템 기본 폰트 적용
        useMaterial3: true,
      ),
      home: LoginScreen(
        onLogin: () {
          debugPrint('로그인 성공!');
        },
      ),
    );
  }
}

enum ScreenMode { login, signup, find }

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;

  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String validId = 'user1';
  static const String validPw = '1234';

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();

  String _error = '';
  ScreenMode _mode = ScreenMode.login;
  bool _showPw = false;

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_idController.text == validId && _pwController.text == validPw) {
      setState(() {
        _error = '';
      });
      widget.onLogin();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인되었습니다.')),
      );
    } else {
      setState(() {
        _error = '아이디 또는 비밀번호가 올바르지 않습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == ScreenMode.signup) {
      return SignupModal(onBack: () => setState(() => _mode = ScreenMode.login));
    }
    if (_mode == ScreenMode.find) {
      return FindPwModal(onBack: () => setState(() => _mode = ScreenMode.login));
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 384), // max-w-sm
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo Row
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primary, AppColors.primaryLight],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text('📅', style: TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scheduly',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            '개인 & 팀 일정을 한곳에서',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Form Container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ID Field Row
                        _buildInputRow(
                          label: '아이디',
                          child: TextField(
                            controller: _idController,
                            onChanged: (_) {
                              if (_error.isNotEmpty) setState(() => _error = '');
                            },
                            onSubmitted: (_) => _handleLogin(),
                            style: const TextStyle(fontSize: 14, color: AppColors.text),
                            decoration: _inputDecoration(
                              hintText: '아이디 입력',
                              hasError: _error.isNotEmpty,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // PW Field Row
                        _buildInputRow(
                          label: '비밀번호',
                          child: TextField(
                            controller: _pwController,
                            obscureText: !_showPw,
                            onChanged: (_) {
                              if (_error.isNotEmpty) setState(() => _error = '');
                            },
                            onSubmitted: (_) => _handleLogin(),
                            style: const TextStyle(fontSize: 14, color: AppColors.text),
                            decoration: _inputDecoration(
                              hintText: '비밀번호 입력',
                              hasError: _error.isNotEmpty,
                              suffixIcon: IconButton(
                                icon: Text(_showPw ? '🙈' : '👁️', style: const TextStyle(fontSize: 16)),
                                onPressed: () => setState(() => _showPw = !_showPw),
                              ),
                            ),
                          ),
                        ),

                        // Error Message
                        if (_error.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0x1FFF6B6B),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0x40FF6B6B)),
                            ),
                            child: Row(
                              children: [
                                const Text('⚠️', style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error,
                                    style: const TextStyle(fontSize: 12, color: AppColors.accent),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Actions Row (비밀번호 찾기 / 회원가입 & 로그인 버튼)
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _mode = ScreenMode.find),
                              child: const Text(
                                '비밀번호 찾기',
                                style: TextStyle(fontSize: 12, color: AppColors.muted),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text('|', style: TextStyle(fontSize: 12, color: AppColors.border)),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _mode = ScreenMode.signup),
                              child: const Text(
                                '회원가입',
                                style: TextStyle(fontSize: 12, color: AppColors.muted),
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('로그인', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Bottom Test Credentials Note
                  const SizedBox(height: 16),
                  const Text.rich(
                    TextSpan(
                      text: '테스트: ID ',
                      children: [
                        TextSpan(
                          text: 'user1',
                          style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' / PW '),
                        TextSpan(
                          text: '1234',
                          style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputRow({required String label, required Widget child}) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.muted),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: child),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hintText, bool hasError = false, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 14, color: AppColors.muted),
      filled: true,
      fillColor: AppColors.surface2,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: hasError ? AppColors.accent : AppColors.border,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: hasError ? AppColors.accent : AppColors.primary,
          width: 1.5,
        ),
      ),
    );
  }
}

// 회원가입 모달 화면
class SignupModal extends StatefulWidget {
  final VoidCallback onBack;

  const SignupModal({super.key, required this.onBack});

  @override
  State<SignupModal> createState() => _SignupModalState();
}

class _SignupModalState extends State<SignupModal> {
  final Map<String, TextEditingController> _controllers = {
    'id': TextEditingController(),
    'name': TextEditingController(),
    'email': TextEditingController(),
    'pw': TextEditingController(),
    'pw2': TextEditingController(),
  };

  bool _done = false;

  final List<Map<String, String>> _fields = const [
    {'key': 'id', 'label': '아이디', 'ph': '사용할 아이디'},
    {'key': 'name', 'label': '이름', 'ph': '실명'},
    {'key': 'email', 'label': '이메일', 'ph': 'example@email.com'},
    {'key': 'pw', 'label': '비밀번호', 'ph': '8자 이상'},
    {'key': 'pw2', 'label': '비밀번호 확인', 'ph': '다시 입력'},
  ];

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 384),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: widget.onBack,
                        icon: const Icon(Icons.arrow_back, color: AppColors.muted),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '회원가입',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_done)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          const Text('🎉', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 16),
                          const Text(
                            '가입이 완료되었습니다!',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: widget.onBack,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('로그인하기', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ..._fields.map((f) {
                            final isPw = f['key'] == 'pw' || f['key'] == 'pw2';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    f['label']!,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted),
                                  ),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: _controllers[f['key']],
                                    obscureText: isPw,
                                    style: const TextStyle(fontSize: 14, color: AppColors.text),
                                    decoration: InputDecoration(
                                      hintText: f['ph'],
                                      hintStyle: const TextStyle(fontSize: 14, color: AppColors.muted),
                                      filled: true,
                                      fillColor: AppColors.surface2,
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: AppColors.border),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: AppColors.primary),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => setState(() => _done = true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('가입하기', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 비밀번호 찾기 모달 화면
class FindPwModal extends StatefulWidget {
  final VoidCallback onBack;

  const FindPwModal({super.key, required this.onBack});

  @override
  State<FindPwModal> createState() => _FindPwModalState();
}

class _FindPwModalState extends State<FindPwModal> {
  final TextEditingController _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 384),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: widget.onBack,
                        icon: const Icon(Icons.arrow_back, color: AppColors.muted),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '비밀번호 찾기',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _sent
                        ? Column(
                            children: [
                              const Text('📧', style: TextStyle(fontSize: 40)),
                              const SizedBox(height: 12),
                              const Text(
                                '이메일을 발송했습니다',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.text),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _emailController.text,
                                style: const TextStyle(fontSize: 14, color: AppColors.muted),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: widget.onBack,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('확인', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '가입한 이메일로 임시 비밀번호를 발송합니다.',
                                style: TextStyle(fontSize: 14, color: AppColors.muted),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                '이메일',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(fontSize: 14, color: AppColors.text),
                                decoration: InputDecoration(
                                  hintText: '이메일 입력',
                                  hintStyle: const TextStyle(fontSize: 14, color: AppColors.muted),
                                  filled: true,
                                  fillColor: AppColors.surface2,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.primary),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => setState(() => _sent = true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('발송하기', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}