import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

import 'memo_parser.dart';

/// OCR 한 번의 결과
class OcrResult {
  /// 정리된 할 일 후보
  final List<String> candidates;

  /// ML Kit가 돌려준 원본 줄 수
  final int rawLineCount;

  /// 온디바이스 추론(processImage)에 걸린 시간
  final Duration inference;

  /// 사진 선택 직후부터 후보 정리까지 전체 시간
  final Duration total;

  const OcrResult({
    required this.candidates,
    required this.rawLineCount,
    required this.inference,
    required this.total,
  });
}

/// 메모 사진 → 할 일 후보. 테스트에서는 가짜 구현으로 바꿔 끼운다.
abstract class MemoRecognizer {
  /// [imagePath]의 사진을 인식하고, 끝나면 **사진 파일을 반드시 지운다**.
  Future<OcrResult> recognizeAndDiscard(String imagePath);
}

/// Google ML Kit Text Recognition v2 (한국어 스크립트 + 라틴 문자 포함).
/// 모델이 앱에 번들되어 있어 네트워크 없이 기기 안에서만 처리한다.
class MlKitMemoRecognizer implements MemoRecognizer {
  @override
  Future<OcrResult> recognizeAndDiscard(String imagePath) async {
    final total = Stopwatch()..start();
    final recognizer = TextRecognizer(script: TextRecognitionScript.korean);
    try {
      final inference = Stopwatch()..start();
      final text = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      inference.stop();

      // 블록 → 줄 순서대로 모은다 (사진 속 위에서 아래 순서)
      final lines = <String>[
        for (final block in text.blocks)
          for (final line in block.lines) line.text,
      ];
      final candidates = extractCandidates(lines);
      total.stop();
      return OcrResult(
        candidates: candidates,
        rawLineCount: lines.length,
        inference: inference.elapsed,
        total: total.elapsed,
      );
    } finally {
      await recognizer.close();
      await PhotoDisposal.discard(imagePath);
    }
  }
}

/// 프라이버시 원칙: 원본 사진은 앱에 남기지 않는다.
class PhotoDisposal {
  /// 인식에 쓴 사진 파일을 지우고, image_picker가 캐시에 남긴 사본도 정리한다.
  static Future<void> discard(String imagePath) async {
    await _deleteQuietly(File(imagePath));
    await purgePickerCache();
  }

  /// 앱 캐시 폴더의 image_picker 임시 사진(jpg/png/heic)을 모두 지운다.
  /// 이전 실행이 비정상 종료되어 남은 파일도 앱 시작 시 이 함수로 정리한다.
  static Future<int> purgePickerCache() async {
    var removed = 0;
    try {
      final dir = await getTemporaryDirectory();
      if (!await dir.exists()) return 0;
      await for (final e in dir.list(recursive: true, followLinks: false)) {
        if (e is File && _isPhoto(e.path)) {
          await _deleteQuietly(e);
          removed++;
        }
      }
    } catch (_) {
      // 정리 실패는 앱 동작을 막지 않는다
    }
    return removed;
  }

  static bool _isPhoto(String path) =>
      RegExp(r'\.(jpe?g|png|heic|webp)$', caseSensitive: false).hasMatch(path);

  static Future<void> _deleteQuietly(File f) async {
    try {
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
