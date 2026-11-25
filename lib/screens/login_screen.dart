import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/app_services.dart';
import '../services/auth_service.dart';

enum ScreenMode { login, signup, find }

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;

  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 계정 정보는 소스에 두지 않는다.
  // - Firebase 설정(.env)이 있으면: Firebase Authentication 이메일·비밀번호 로그인 → 클라우드 동기화
  // - 없으면: 아이디·비밀번호가 입력되기만 하면 로컬 전용(데모) 모드로 진입

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();

  String _error = '';
  ScreenMode _mode = ScreenMode.login;
  bool _showPw = false;
  bool _busy = false;

  bool get _cloud => AppServices.firebaseReady;

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_busy) return;
    final id = _idController.text.trim();
    final pw = _pwController.text;
    if (id.isEmpty || pw.isEmpty) {
      setState(() {
        _error = _cloud ? '이메일과 비밀번호를 입력해주세요.' : '아이디와 비밀번호를 입력해주세요.';
      });
      return;
    }
    setState(() {
      _error = '';
      _busy = true;
    });
    try {
      if (_cloud) {
        final user = await AuthService.signIn(id, pw);
        await AppServices.startCloudSession(user);
      } else {
        await AppServices.startLocalSession();
      }
      if (!mounted) return;
      widget.onLogin();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cloud ? '로그인되었습니다. 서버와 동기화합니다.' : '로그인되었습니다.'),
        ),
      );
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startLocal() async {
    await AppServices.startLocalSession();
    widget.onLogin();
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
              constraints: const BoxConstraints(maxWidth: 384),
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
                          label: _cloud ? '이메일' : '아이디',
                          child: TextField(
                            key: const Key('login_id'),
                            controller: _idController,
                            keyboardType: _cloud ? TextInputType.emailAddress : TextInputType.text,
                            onChanged: (_) {
                              if (_error.isNotEmpty) setState(() => _error = '');
                            },
                            onSubmitted: (_) => _handleLogin(),
                            style: const TextStyle(fontSize: 14, color: AppColors.text),
                            decoration: _inputDecoration(
                              hintText: _cloud ? 'test@example.com' : '아이디 입력',
                              hasError: _error.isNotEmpty,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // PW Field Row
                        _buildInputRow(
                          label: '비밀번호',
                          child: TextField(
                            key: const Key('login_pw'),
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

                        // Actions Row
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
                              key: const Key('login_button'),
                              onPressed: _busy ? null : _handleLogin,
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

                  const SizedBox(height: 16),
                  Text(
                    _cloud
                        ? '☁️ 클라우드 모드: 같은 계정으로 로그인한 기기끼리 목록이 동기화됩니다'
                        : '데모 모드: 아무 아이디·비밀번호나 입력하면 시작합니다',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  TextButton(
                    key: const Key('demo_start'),
                    onPressed: _busy ? null : _startLocal,
                    child: Text(
                      _cloud ? '로그인 없이 둘러보기 (이 기기에만 저장)' : '로그인 없이 둘러보기',
                      style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
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

class SignupModal extends StatefulWidget {
  final VoidCallback onBack;

  const SignupModal({super.key, required this.onBack});

  @override
  State<SignupModal> createState() => _SignupModalState();
}

class _SignupModalState extends State<SignupModal> {
  final Map<String, TextEditingController> _controllers = {
    'email': TextEditingController(),
    'pw': TextEditingController(),
    'pw2': TextEditingController(),
  };

  bool _done = false;
  bool _busy = false;
  String _error = '';

  // 실명 등 불필요한 개인정보는 받지 않는다. (이메일은 테스트용 주소 사용 권장)
  final _fields = const [
    {'key': 'email', 'label': '이메일', 'ph': 'test@example.com'},
    {'key': 'pw', 'label': '비밀번호', 'ph': '6자 이상'},
    {'key': 'pw2', 'label': '비밀번호 확인', 'ph': '다시 입력'},
  ];

  Future<void> _submit() async {
    final email = _controllers['email']!.text.trim();
    final pw = _controllers['pw']!.text;
    final pw2 = _controllers['pw2']!.text;
    String err = '';
    if (email.isEmpty || pw.isEmpty) {
      err = '이메일과 비밀번호를 입력해주세요.';
    } else if (pw.length < 6) {
      err = '비밀번호는 6자 이상이어야 합니다.';
    } else if (pw != pw2) {
      err = '비밀번호 확인이 일치하지 않습니다.';
    }
    if (err.isNotEmpty) {
      setState(() => _error = err);
      return;
    }
    if (!AppServices.firebaseReady) {
      // 로컬 전용 모드: 서버가 없으므로 화면 흐름만 보여 준다.
      setState(() => _done = true);
      return;
    }
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      await AuthService.signUp(email, pw);
      // 가입 직후 자동 로그인 상태를 해제하고, 로그인 화면에서 직접 로그인하게 한다.
      await AppServices.endSession();
      if (mounted) setState(() => _done = true);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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
                                    key: ValueKey('signup_${f['key']}'),
                                    controller: _controllers[f['key']],
                                    keyboardType: f['key'] == 'email' ? TextInputType.emailAddress : TextInputType.text,
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
                          if (_error.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '⚠️ $_error',
                                style: const TextStyle(fontSize: 12, color: AppColors.accent),
                              ),
                            ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              key: const Key('signup_submit'),
                              onPressed: _busy ? null : _submit,
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