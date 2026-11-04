import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

// 인식된 아이템 모델
class RecognizedItem {
  final int id;
  final String text;
  final String type; // 'todo' | 'memo'
  bool saved;

  RecognizedItem({
    required this.id,
    required this.text,
    required this.type,
    required this.saved,
  });
}

// 목업 인식 결과 데이터 (React 버전과 동일)
final List<RecognizedItem> mockResults = [
  RecognizedItem(id: 1, text: '내일 오전 11시 교수님 면담', type: 'todo', saved: false),
  RecognizedItem(id: 2, text: '알고리즘 책 8장 예습', type: 'todo', saved: false),
  RecognizedItem(id: 3, text: '팀원 연락 → 회의실 예약 확인', type: 'memo', saved: false),
];

// 화면 단계 (idle, camera, drawing, result)
enum HandwritingPhase { idle, camera, drawing, result }

class HandwritingScreen extends StatefulWidget {
  const HandwritingScreen({super.key});

  @override
  State<HandwritingScreen> createState() => _HandwritingScreenState();
}

class _HandwritingScreenState extends State<HandwritingScreen> {
  HandwritingPhase _phase = HandwritingPhase.idle;
  List<RecognizedItem> _recognized = [];
  
  // 캔버스 드로잉을 위한 경로 리스트
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  void _startCamera() {
    setState(() {
      _phase = HandwritingPhase.camera;
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _phase = HandwritingPhase.drawing;
        });
      }
    });
  }

  void _recognize() {
    setState(() {
      _phase = HandwritingPhase.result;
      _recognized = mockResults.map((r) => RecognizedItem(
        id: r.id,
        text: r.text,
        type: r.type,
        saved: r.saved,
      )).toList();
      _strokes.clear();
      _currentStroke.clear();
    });
  }

  void _saveItem(int id) {
    setState(() {
      final item = _recognized.firstWhere((r) => r.id == id);
      item.saved = true;
    });
  }

  void _reset() {
    setState(() {
      _phase = HandwritingPhase.idle;
      _recognized.clear();
      _strokes.clear();
      _currentStroke.clear();
    });
  }

  void _clearCanvas() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '✍️ 손글씨 인식',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '손글씨를 인식해 일정을 자동으로 추가합니다',
                style: TextStyle(fontSize: 14, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 1. Idle State
          if (_phase == HandwritingPhase.idle) ...[
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.primaryLight],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text('📷', style: TextStyle(fontSize: 36)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '카메라 인식',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '카메라로 손글씨를 촬영하거나\n직접 캔버스에 써보세요',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.muted, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _startCamera,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('카메라 열기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Canvas Direct Write Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Text('또는 직접 써보기', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => setState(() => _phase = HandwritingPhase.drawing),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.surface2,
                        foregroundColor: AppColors.text,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('✍️ 캔버스에 직접 쓰기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 인식 팁', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                  const SizedBox(height: 8),
                  ...[
                    '밝은 곳에서 촬영하면 더 정확합니다',
                    '글씨를 크고 선명하게 써주세요',
                    '줄을 맞춰 쓰면 인식률이 높아집니다',
                  ].map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $t', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      )),
                ],
              ),
            ),
          ],

          // 2. Camera Loading State
          if (_phase == HandwritingPhase.camera)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 60),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('카메라 초기화 중...', style: TextStyle(fontSize: 14, color: AppColors.muted)),
                ],
              ),
            ),

          // 3. Drawing Canvas State
          if (_phase == HandwritingPhase.drawing)
            Column(
              children: [
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    children: [
                      // Canvas Painting Area
                      GestureDetector(
                        onPanStart: (details) {
                          setState(() {
                            _currentStroke = [details.localPosition];
                            _strokes.add(_currentStroke);
                          });
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            _currentStroke.add(details.localPosition);
                          });
                        },
                        onPanEnd: (details) {
                          _currentStroke = [];
                        },
                        child: CustomPaint(
                          painter: SignaturePainter(strokes: _strokes),
                          size: Size.infinite,
                        ),
                      ),
                      // Guide Lines
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: Column(
                            children: [60.0, 120.0, 180.0, 220.0].map((bottom) {
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                height: 1,
                                color: AppColors.primary.withValues(alpha: 0.1),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      // Badge
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0x336C63FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '✍️ 여기에 써주세요',
                            style: TextStyle(fontSize: 12, color: AppColors.primaryLight),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _clearCanvas,
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.surface2,
                          foregroundColor: AppColors.muted,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('지우기', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _recognize,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('인식하기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _reset,
                  child: const Text('취소', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                ),
              ],
            ),

          // 4. Result State
          if (_phase == HandwritingPhase.result)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text('✓', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_recognized.length}개 항목을 인식했습니다',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  children: _recognized.map((r) {
                    final bool isTodo = r.type == 'todo';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: r.saved ? const Color(0x144ADE80) : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: r.saved ? const Color(0x404ADE80) : Colors.transparent,
                        ),
                      ),
                      child: Row(
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
                                        color: isTodo ? const Color(0x266C63FF) : const Color(0x26FBBF24),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isTodo ? '📋 할 일' : '📝 메모',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: isTodo ? AppColors.primaryLight : const Color(0xFFFBBF24),
                                        ),
                                      ),
                                    ),
                                    if (r.saved) ...[
                                      const SizedBox(width: 8),
                                      const Text('저장됨 ✓', style: TextStyle(fontSize: 12, color: Color(0xFF4ADE80))),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  r.text,
                                  style: const TextStyle(fontSize: 14, color: AppColors.text),
                                ),
                              ],
                            ),
                          ),
                          if (!r.saved)
                            ElevatedButton(
                              onPressed: () => _saveItem(r.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              child: const Text('저장', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => setState(() => _phase = HandwritingPhase.drawing),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.surface2,
                          foregroundColor: AppColors.muted,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('다시 인식', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _reset,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('완료', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// 캔버스 드로잉을 위한 CustomPainter
class SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;

  SignaturePainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFFA78BFA) // AppColors.primaryLight
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (var stroke in strokes) {
      if (stroke.isEmpty) continue;
      final Path path = Path();
      path.moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SignaturePainter oldDelegate) {
    return true;
  }
}