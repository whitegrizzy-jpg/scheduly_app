import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scheduly_app/data/todo_repository.dart';
import 'package:scheduly_app/ocr/memo_ocr_service.dart';
import 'package:scheduly_app/ocr/memo_parser.dart';
import 'package:scheduly_app/ocr/photo_source.dart';
import 'package:scheduly_app/screens/memo_scan_screen.dart';
import 'package:scheduly_app/services/app_services.dart';

class FakePhotos implements PhotoSource {
  CameraAccess access;
  String? path;
  int pickCount = 0;
  bool settingsOpened = false;
  FakePhotos({this.access = CameraAccess.granted, this.path = '/tmp/memo.jpg'});

  @override
  Future<CameraAccess> requestCamera() async => access;

  @override
  Future<String?> pick(PhotoOrigin origin) async {
    pickCount++;
    return path;
  }

  @override
  Future<void> openSettings() async => settingsOpened = true;
}

class FakeRecognizer implements MemoRecognizer {
  final List<String> lines;
  final discarded = <String>[];
  FakeRecognizer(this.lines);

  @override
  Future<OcrResult> recognizeAndDiscard(String imagePath) async {
    discarded.add(imagePath); // 실제 구현처럼 "인식 후 사진 삭제"가 호출됐는지 기록
    return OcrResult(
      candidates: extractCandidates(lines),
      rawLineCount: lines.length,
      inference: const Duration(milliseconds: 420),
      total: const Duration(milliseconds: 510),
    );
  }
}

Future<void> pumpScreen(
  WidgetTester tester,
  FakePhotos photos,
  FakeRecognizer ocr, {
  ValueChanged<int>? onAdded,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: MemoScanScreen(
        photoSource: photos,
        recognizer: ocr,
        onAdded: onAdded,
      ),
    ),
  );
}

void main() {
  group('extractCandidates (줄 → 할 일 후보)', () {
    test('글머리표·번호·체크박스를 떼고 빈 줄과 기호만 있는 줄을 버린다', () {
      final out = extractCandidates([
        '  - 우유 사기 ',
        '• 보고서 제출',
        '1. 알고리즘 과제',
        '2) Call the dentist',
        '□ 운동 30분',
        '[x] 이미 한 일',
        '',
        '---',
        '11/25',
        'a',
      ]);
      expect(out, [
        '우유 사기',
        '보고서 제출',
        '알고리즘 과제',
        'Call the dentist',
        '운동 30분',
        '이미 한 일',
      ]);
    });

    test('같은 내용은 한 번만, 여러 공백은 하나로', () {
      expect(
        extractCandidates(['도서관   반납', '도서관 반납', 'Buy MILK', 'buy milk']),
        ['도서관 반납', 'Buy MILK'],
      );
    });
  });

  testWidgets('TC-11/12 사진 → 후보 검토(수정·선택 해제) → 선택한 것만 저장', (tester) async {
    final repo = InMemoryTodoRepository(const []);
    AppServices.todos = repo;
    final photos = FakePhotos();
    final ocr = FakeRecognizer(['- 우유 사기', '- 보고서 제출', '- 운동 30분']);
    int? added;
    await pumpScreen(tester, photos, ocr, onAdded: (n) => added = n);

    await tester.tap(find.byKey(const Key('scan_gallery')));
    await tester.pumpAndSettle();

    // 후보 3개 + 처리 시간 + 사진 삭제 안내
    expect(find.byKey(const Key('scan_timing')), findsOneWidget);
    expect(find.textContaining('인식 0.42초'), findsOneWidget);
    expect(find.textContaining('원본 사진은 삭제되었습니다'), findsOneWidget);
    expect(ocr.discarded, ['/tmp/memo.jpg']);
    expect(find.text('우유 사기'), findsOneWidget);

    // 1번 오타 수정, 3번 선택 해제
    await tester.enterText(
      find.byKey(const ValueKey('cand_text_0')),
      '저지방 우유 사기',
    );
    await tester.tap(find.byKey(const ValueKey('cand_check_2')));
    await tester.pump();
    expect(find.text('선택한 2개 추가'), findsOneWidget);

    await tester.tap(find.byKey(const Key('scan_save')));
    await tester.pumpAndSettle();

    final saved = (await repo.loadAll()).map((t) => t.text).toList();
    expect(saved, ['저지방 우유 사기', '보고서 제출'], reason: '메모 위쪽 줄이 목록 위에 온다');
    expect(added, 2);
  });

  testWidgets('TC-10 카메라 권한 거부: 앱이 멈추지 않고 안내와 대안(갤러리)을 보여 준다', (tester) async {
    final photos = FakePhotos(access: CameraAccess.denied);
    await pumpScreen(tester, photos, FakeRecognizer(const []));

    await tester.tap(find.byKey(const Key('scan_camera')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('camera_denied')), findsOneWidget);
    expect(find.text('🚫 카메라 권한이 필요합니다'), findsOneWidget);
    expect(find.text('권한 다시 요청'), findsOneWidget);
    expect(photos.pickCount, 0, reason: '권한이 없으면 카메라를 열지 않는다');
  });

  testWidgets('권한을 영구 거부하면 설정 열기 버튼을 보여 준다', (tester) async {
    final photos = FakePhotos(access: CameraAccess.permanentlyDenied);
    await pumpScreen(tester, photos, FakeRecognizer(const []));

    await tester.tap(find.byKey(const Key('scan_camera')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('설정 열기'));
    expect(photos.settingsOpened, isTrue);
  });

  testWidgets('사진 선택을 취소하면 아무 일도 일어나지 않는다', (tester) async {
    final ocr = FakeRecognizer(const ['x']);
    await pumpScreen(tester, FakePhotos(path: null), ocr);
    await tester.tap(find.byKey(const Key('scan_gallery')));
    await tester.pumpAndSettle();
    expect(ocr.discarded, isEmpty);
    expect(find.byKey(const Key('scan_gallery')), findsOneWidget);
  });
}
