import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/todo.dart';
import '../ocr/memo_ocr_service.dart';
import '../ocr/photo_source.dart';
import '../services/app_services.dart';

enum _Phase { idle, processing, review }

/// 종이 메모 가져오기 (MP4)
///
/// 사진(촬영/갤러리) → 온디바이스 OCR(ML Kit) → 줄 단위 후보 검토·수정 → 선택 항목만 할 일로 저장.
/// 원본 사진은 인식 직후 삭제하고 화면에도 띄우지 않는다.
class MemoScanScreen extends StatefulWidget {
  /// 할 일을 추가한 뒤 호출 (홈 탭으로 이동 등)
  final ValueChanged<int>? onAdded;
  final PhotoSource? photoSource;
  final MemoRecognizer? recognizer;

  const MemoScanScreen({
    super.key,
    this.onAdded,
    this.photoSource,
    this.recognizer,
  });

  @override
  State<MemoScanScreen> createState() => _MemoScanScreenState();
}

class _Candidate {
  final TextEditingController controller;
  bool selected = true;
  _Candidate(String text) : controller = TextEditingController(text: text);
}

class _MemoScanScreenState extends State<MemoScanScreen> {
  late final PhotoSource _photos = widget.photoSource ?? DevicePhotoSource();
  late final MemoRecognizer _ocr = widget.recognizer ?? MlKitMemoRecognizer();

  _Phase _phase = _Phase.idle;
  CameraAccess? _cameraBlocked; // 권한 거부 안내 표시용
  String _error = '';
  OcrResult? _result;
  List<_Candidate> _candidates = [];

  @override
  void dispose() {
    for (final c in _candidates) {
      c.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _start(PhotoOrigin origin) async {
    setState(() {
      _error = '';
      _cameraBlocked = null;
    });
    if (origin == PhotoOrigin.camera) {
      final access = await _photos.requestCamera();
      if (access != CameraAccess.granted) {
        setState(() => _cameraBlocked = access);
        return;
      }
    }
    final String? path;
    try {
      path = await _photos.pick(origin);
    } catch (e) {
      setState(() => _error = '사진을 가져오지 못했습니다. 다시 시도해주세요.');
      return;
    }
    if (path == null) return; // 사용자가 취소

    setState(() => _phase = _Phase.processing);
    try {
      final r = await _ocr.recognizeAndDiscard(path);
      if (!mounted) return;
      for (final c in _candidates) {
        c.controller.dispose();
      }
      setState(() {
        _result = r;
        _candidates = r.candidates.map(_Candidate.new).toList();
        _phase = _Phase.review;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.idle;
        _error = '글자를 인식하지 못했습니다. 밝은 곳에서 메모 전체가 보이게 다시 찍어주세요.';
      });
    }
  }

  Future<void> _save() async {
    final picked = _candidates
        .where((c) => c.selected)
        .map((c) => c.controller.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (picked.isEmpty) {
      setState(() => _error = '추가할 항목을 하나 이상 선택해주세요.');
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    // 메모의 위쪽 줄이 목록 위에 오도록 createdAt을 역순으로 준다
    for (var i = 0; i < picked.length; i++) {
      await AppServices.todos.insert(
        Todo(
          id: now + i,
          text: picked[i],
          done: false,
          due: '기한 없음',
          priority: 'mid',
          createdAt: now + picked.length - i,
        ),
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('메모에서 할 일 ${picked.length}개를 추가했습니다.')),
    );
    _reset();
    widget.onAdded?.call(picked.length);
  }

  void _reset() {
    setState(() {
      _phase = _Phase.idle;
      _result = null;
      _error = '';
      for (final c in _candidates) {
        c.controller.dispose();
      }
      _candidates = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          children: [
            const Text(
              '📷 종이 메모 가져오기',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '메모를 찍으면 기기 안에서 글자를 읽어 할 일 후보로 만들어 줍니다.',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            if (_phase == _Phase.idle) ..._buildIdle(),
            if (_phase == _Phase.processing) _buildProcessing(),
            if (_phase == _Phase.review) ..._buildReview(),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 12),
              _Notice(
                key: const Key('scan_error'),
                icon: '⚠️',
                text: _error,
                color: AppColors.accent,
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildIdle() => [
    Row(
      children: [
        Expanded(
          child: _BigButton(
            key: const Key('scan_camera'),
            icon: Icons.photo_camera_outlined,
            label: '촬영하기',
            onTap: () => _start(PhotoOrigin.camera),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _BigButton(
            key: const Key('scan_gallery'),
            icon: Icons.photo_library_outlined,
            label: '갤러리에서 선택',
            onTap: () => _start(PhotoOrigin.gallery),
          ),
        ),
      ],
    ),
    if (_cameraBlocked != null) ...[
      const SizedBox(height: 12),
      _PermissionNotice(
        permanentlyDenied: _cameraBlocked == CameraAccess.permanentlyDenied,
        onSettings: _photos.openSettings,
        onRetry: () => _start(PhotoOrigin.camera),
        onGallery: () => _start(PhotoOrigin.gallery),
      ),
    ],
    const SizedBox(height: 16),
    const _Notice(
      icon: '🔒',
      text:
          '온디바이스 인식: 사진은 서버로 보내지 않고, 인식이 끝나면 앱에서 바로 삭제됩니다. '
          '비행기 모드에서도 동작합니다.',
      color: AppColors.primary,
    ),
    const SizedBox(height: 8),
    const _Notice(
      icon: '💡',
      text: '한 줄에 할 일 하나씩 적은 메모가 가장 잘 인식됩니다. 개인정보가 없는 메모로 테스트해주세요.',
      color: AppColors.muted,
    ),
  ];

  Widget _buildProcessing() => const Padding(
    key: Key('scan_processing'),
    padding: EdgeInsets.symmetric(vertical: 48),
    child: Column(
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('기기에서 글자를 읽는 중…', style: TextStyle(color: AppColors.muted)),
      ],
    ),
  );

  List<Widget> _buildReview() {
    final r = _result!;
    final selected = _candidates.where((c) => c.selected).length;
    final allOn = _candidates.isNotEmpty && selected == _candidates.length;
    return [
      _Notice(
        key: const Key('scan_timing'),
        icon: '⏱️',
        text:
            '인식 ${_sec(r.inference)}초 (전체 ${_sec(r.total)}초) · 기기 내 처리 · '
            '${r.rawLineCount}줄 → 후보 ${r.candidates.length}개\n'
            '원본 사진은 삭제되었습니다.',
        color: const Color(0xff16a34a),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          const Text(
            '할 일 후보',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const Spacer(),
          if (_candidates.isNotEmpty)
            TextButton(
              onPressed: () => setState(() {
                for (final c in _candidates) {
                  c.selected = !allOn;
                }
              }),
              child: Text(allOn ? '모두 해제' : '모두 선택'),
            ),
        ],
      ),
      if (_candidates.isEmpty)
        const _Notice(
          icon: '🔍',
          text: '읽어 낸 글자가 없습니다. 메모가 화면을 가득 채우도록 다시 찍어주세요.',
          color: AppColors.muted,
        ),
      for (var i = 0; i < _candidates.length; i++) _candidateTile(i),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              key: const Key('scan_retry'),
              onPressed: _reset,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('다시 찍기'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              key: const Key('scan_save'),
              onPressed: selected == 0 ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '선택한 $selected개 추가',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _candidateTile(int i) {
    final c = _candidates[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: c.selected ? AppColors.primaryLight : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            key: ValueKey('cand_check_$i'),
            value: c.selected,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => c.selected = v ?? false),
          ),
          Expanded(
            child: TextField(
              key: ValueKey('cand_text_$i'),
              controller: c.controller,
              style: TextStyle(
                fontSize: 14,
                color: c.selected ? AppColors.text : AppColors.muted,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: '내용 입력',
              ),
            ),
          ),
          const Icon(Icons.edit_outlined, size: 16, color: AppColors.muted),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  static String _sec(Duration d) =>
      (d.inMilliseconds / 1000).toStringAsFixed(2);
}

class _BigButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BigButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, size: 36, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final String icon;
  final String text;
  final Color color;

  const _Notice({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: color, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// 카메라 권한 거부 안내
class _PermissionNotice extends StatelessWidget {
  final bool permanentlyDenied;
  final VoidCallback onSettings;
  final VoidCallback onRetry;
  final VoidCallback onGallery;

  const _PermissionNotice({
    required this.permanentlyDenied,
    required this.onSettings,
    required this.onRetry,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('camera_denied'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🚫 카메라 권한이 필요합니다',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            permanentlyDenied
                ? '카메라 권한이 꺼져 있어 촬영할 수 없습니다. 설정 > 권한 > 카메라에서 허용하거나, 갤러리에서 사진을 선택해주세요.'
                : '카메라 권한을 거부해 촬영할 수 없습니다. 다시 요청하거나 갤러리에서 사진을 선택해주세요.',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.text,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              if (permanentlyDenied)
                TextButton(onPressed: onSettings, child: const Text('설정 열기'))
              else
                TextButton(onPressed: onRetry, child: const Text('권한 다시 요청')),
              TextButton(onPressed: onGallery, child: const Text('갤러리에서 선택')),
            ],
          ),
        ],
      ),
    );
  }
}
