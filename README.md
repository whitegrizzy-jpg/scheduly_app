# Scheduly — 할 일 앱 (주제 #2109 MP4: 온디바이스 AI로 종이 메모 가져오기)

Flutter 할 일 앱입니다. MP1(화면) → MP2(SQLite 저장·CRUD) → MP3(Firebase 동기화)에 이어 MP4에서는
**종이 메모 사진을 찍거나 고르면 기기 안의 OCR(Google ML Kit)이 글자를 읽어 줄 단위 할 일 후보로 만들고**,
사용자가 확인·수정한 항목만 저장하는 기능을 추가했습니다. 서버 없이 동작하므로 **비행기 모드에서도 인식**됩니다.

## 실행 절차

- 프레임워크/SDK: **Flutter 3.47.5 (stable) / Dart 3.13.4**
- 실행 기기: Android 에뮬레이터 **Pixel_8 (Android 17 / API 37, 1080×2400, x86_64)**
- 온디바이스 OCR: **Google ML Kit Text Recognition v2** — `google_mlkit_text_recognition ^1.0.3` + 번들형 한국어 모델 `com.google.mlkit:text-recognition-korean:16.0.1`(라틴 문자 포함)
- 사진·권한: `image_picker ^1.2.4`(카메라/시스템 사진 선택기), `permission_handler ^12.0.1`, `path_provider ^2.1.6`
- 잠금 파일: `pubspec.lock`, `android/gradle/wrapper/gradle-wrapper.properties`

제출 ZIP에서는 Flutter 프로젝트가 `app/` 폴더에 있으므로 먼저 `cd app` 한 뒤 실행합니다.

```bash
flutter --version                      # Flutter 3.47.5 / Dart 3.13.4 확인
flutter pub get
flutter emulators --launch Pixel_8
flutter run                            # 로컬 전용 모드 (OCR 확인에는 서버가 필요 없음)
# 서버 동기화까지 쓰려면: cp .env.example .env 후 값 입력 → flutter run --dart-define-from-file=.env
```

테스트용 메모 픽스처(개인정보 없는 합성 이미지)를 만들어 에뮬레이터 갤러리에 넣습니다.

```bash
python tools/make_memo_fixture.py
adb push fixtures/memo_fixture.png /sdcard/Pictures/memo_fixture.png
adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/memo_fixture.png
```

테스트 실행 (MP1~MP3 18개 + MP4 6개 = 24개):

```bash
flutter test
```

앱에서는 하단 탭 **📷 메모 스캔**을 엽니다.
(로그인 화면에서는 「로그인 없이 둘러보기」로 들어가도 됩니다. Firebase 설정과 동기화는 MP3 README 내용과 같고, 아래 "MP3 동기화"에 요약했습니다.)

## 인식 기능과 라이브러리

| 항목 | 내용 |
|---|---|
| 라이브러리 | Google ML Kit Text Recognition v2 (`TextRecognizer(script: korean)`) |
| 실행 위치 | **기기 안** (번들형 모델 — 앱 설치 시 포함, 실행 중 내려받지 않음) |
| 지원 문자 | 한글 + 영문/숫자 (한국어 스크립트 모델이 라틴 문자도 인식) |
| 입력 | 카메라 촬영 또는 시스템 사진 선택기(Android Photo Picker — 고른 사진에만 접근) |
| 출력 | 블록 → 줄 순서의 텍스트 → `extractCandidates()`로 정리한 할 일 후보 |
| 후보 정리 규칙 | 글머리표(- • □ [ ])·번호(1. 2) ①) 제거, 빈 줄·1글자·숫자/기호만 있는 줄 제외, 중복 제거, 100자 제한 (`lib/ocr/memo_parser.dart`) |

**ML Kit을 고른 이유**: 9주차 보고서의 비교(ML Kit / LiteRT / Apple Vision / MediaPipe)에서 ML Kit만 Android·Flutter에서 한국어 OCR을 별도 모델 포팅 없이 바로 쓸 수 있었습니다. 번들형 모델을 선택해 Google Play 서비스의 모델 다운로드에 기대지 않고, 설치 직후부터 오프라인에서 동작합니다. (대가로 APK가 커집니다.)

## 검토 UI 흐름

```
[📷 촬영하기] 또는 [🖼 갤러리에서 선택]
   │  (카메라는 권한 요청 → 거부 시 안내 + "권한 다시 요청/설정 열기/갤러리에서 선택")
   ▼
기기에서 글자를 읽는 중… (ML Kit, 처리 시간 측정)
   │  → 인식이 끝나면 사진 파일 즉시 삭제
   ▼
검토 화면: ⏱ 처리 시간 · 줄 수 → 후보 수 · "원본 사진은 삭제되었습니다"
   - 후보마다 체크박스(선택/해제) + 바로 고칠 수 있는 입력칸
   - 모두 선택/해제, 다시 찍기
   ▼
[선택한 n개 추가] → 할 일 목록에 저장 (메모 위쪽 줄이 목록 위) → 홈 탭으로 이동
   (로그인 상태면 MP3 동기화 대기열을 거쳐 서버에도 반영 — 오프라인이면 대기)
```

- 원본 사진은 검토 화면에도 띄우지 않습니다. 보이는 것은 인식된 글자뿐입니다.

## 처리 시간 측정값

측정 방법: `Stopwatch`로 `TextRecognizer.processImage()` 실행 시간(인식)과 사진 선택 직후부터 후보 정리까지(전체)를 재서 검토 화면에 보여 줍니다(`lib/ocr/memo_ocr_service.dart`).
입력: `fixtures/memo_fixture.png`(1266×1552, image_picker가 최대 2000px로 다시 인코딩) — 제목 1줄 + 할 일 5줄, 인식 8줄 → 후보 6개.
기기: Pixel_8 에뮬레이터(x86_64, 호스트 PC 공유), 디버그 빌드.

| 회차 | 네트워크 | 인식(processImage) | 전체 | 결과 |
|---|---|---|---|---|
| 1 (첫 실행, 모델 로딩 포함) | ✈️ 비행기 모드 | **2.52초** | 2.53초 | 6줄 모두 정확 |
| 2 | ✈️ 비행기 모드 | 1.71초 | 1.71초 | 동일 |
| 3 | ✈️ 비행기 모드 | 1.96초 | 1.96초 | 동일 |
| 4 | ✈️ 비행기 모드 | 1.92초 | 1.93초 | 동일 |
| 5 | 온라인(Wi-Fi) | 1.86초 | 1.86초 | 동일 |
| 6 | 온라인(Wi-Fi) | 1.77초 | 1.77초 | 동일 |
| 7 | 온라인(Wi-Fi) | 1.83초 | 1.83초 | 동일 |

- **비행기 모드 평균(2~4회) 1.86초 ≈ 온라인 평균 1.82초**: 네트워크 유무와 상관없이 같은 시간이 걸려, 인식이 서버가 아니라 기기에서 일어난다는 근거가 됩니다.
- 첫 실행만 모델을 메모리에 올리느라 약 0.7초 더 걸립니다.
- 에뮬레이터 디버그 빌드 기준이라, 실기기 릴리스 빌드에서는 더 빠를 것으로 예상합니다. (LG 실기기 측정은 아직 하지 않았습니다.)

## 프라이버시 원칙 (원본 사진 미저장) — 코드로 지키는 방법

| 원칙 | 구현 | 위치 |
|---|---|---|
| 사진을 서버로 보내지 않음 | 번들형 온디바이스 모델만 사용, 사진을 업로드하는 코드 없음. 동기화되는 것은 사용자가 고른 **텍스트**뿐 | `MlKitMemoRecognizer` |
| 인식 후 사진 즉시 삭제 | `recognizeAndDiscard()`의 `finally`에서 성공·실패와 상관없이 사진 파일을 지우고, image_picker 캐시의 사본도 삭제 | `PhotoDisposal.discard()` |
| 남은 임시 사진 정리 | 앱 시작 시 캐시 폴더의 jpg/png/heic/webp를 모두 삭제 (비정상 종료로 남은 파일 대비) | `main()` → `PhotoDisposal.purgePickerCache()` |
| 갤러리에 저장하지 않음 | 카메라 촬영본은 앱 캐시에 임시로만 생기고 갤러리에 저장하지 않음 | `DevicePhotoSource.pick()` |
| 메타데이터 최소화 | `requestFullMetadata: false`로 위치 등 EXIF를 요청하지 않음 | 〃 |
| 화면에 원본 미표시 | 검토 화면은 인식된 글자만 보여 줌 | `MemoScanScreen` |
| 고른 사진만 접근 | 시스템 사진 선택기 사용 → 저장소 전체 읽기 권한을 요청하지 않음 | 〃 |

**확인**: 인식·저장 후 `adb shell run-as com.example.scheduly_app find /data/data/com.example.scheduly_app -type f`로 앱 저장소 전체를 확인한 결과, 사진 파일(jpg/png/heic/webp)이 **0개**였습니다. 남은 파일은 SQLite DB, Firebase·ML Kit 설정 파일뿐입니다.
(참고: ML Kit은 자체적으로 익명 사용 통계를 `datatransport` DB에 기록할 수 있지만 이미지는 포함되지 않습니다.)

### 권한 거부 처리

- **촬영하기**를 누르면 카메라 권한을 요청합니다. 거부하면 앱이 멈추지 않고 "🚫 카메라 권한이 필요합니다" 안내와 함께 **권한 다시 요청 / 갤러리에서 선택**을 보여 줍니다.
- "다시 묻지 않음" 상태(영구 거부)면 **설정 열기**(앱 설정 화면) 버튼을 보여 줍니다.
- 갤러리 선택은 시스템 사진 선택기를 써서 별도 권한이 필요 없으므로, 카메라를 거부해도 기능을 계속 쓸 수 있습니다.

## 구현 기능 목록

| 기능 | 설명 | 위치 |
|---|---|---|
| **메모 스캔 탭** | 하단 탭 「📷 메모 스캔」 (기존 손글씨 시안 화면을 대체) | `lib/screens/memo_scan_screen.dart` |
| 촬영/선택 | 카메라 촬영, 시스템 사진 선택기 | `lib/ocr/photo_source.dart` |
| 온디바이스 OCR | ML Kit 한국어+라틴, 처리 시간 측정, 사진 즉시 삭제 | `lib/ocr/memo_ocr_service.dart` |
| 후보 추출 | 줄 단위 정리(글머리표·번호 제거, 중복 제거 등) | `lib/ocr/memo_parser.dart` |
| 검토·수정·선택 저장 | 체크박스, 바로 고치는 입력칸, 모두 선택/해제, 다시 찍기, 선택한 것만 저장 | `MemoScanScreen` |
| 권한 거부 안내 | 다시 요청 / 설정 열기 / 갤러리 대안 | `_PermissionNotice` |
| (MP1~3 유지) | 할 일 CRUD·필터, SQLite 저장, Firebase 동기화(오프라인 대기열·LWW 충돌 처리) | `home_screen.dart`, `lib/data/` |

## 확인 방법

### 촬영/선택 화면

- 조작: 하단 탭 「📷 메모 스캔」을 누르고 「갤러리에서 선택」을 눌러 `memo_fixture.png`를 고른 뒤 **완료(Done)**를 누른다
- 기대 결과: 촬영하기/갤러리에서 선택 버튼과 온디바이스 안내가 보이고, 시스템 사진 선택기에 "고른 사진에만 접근" 안내와 메모 사진이 보인다
- 스크린샷: 01_scan_start.png, 02_pick.png

### 사진 → 항목 후보 → 선택 저장

- 조작: 인식이 끝나면 검토 화면에서 「오늘 할 일」(제목 줄)의 체크를 끄고, 「우유 사기」 끝에 " 2L"을 붙인 뒤 **선택한 5개 추가**를 누른다
- 기대 결과: 후보 6개(오늘 할 일 / 우유 사기 / 알고리즘 과제 제출 / 도서관 책 반납 / 운동 30분 / Buy printer paper)가 보이고, 수정·해제가 반영된 5개가 홈 목록 맨 위에 메모 순서대로 추가된다. "메모에서 할 일 5개를 추가했습니다" 스낵바가 뜬다
- 스크린샷: 03_review.png, 04_review_edited.png, 05_added_list.png

### 비행기 모드에서 인식

- 조작: 위 과정을 비행기 모드에서 진행한다 (`adb shell cmd connectivity airplane-mode enable`)
- 기대 결과: 상태 표시줄에 ✈️가 있는 상태에서도 인식이 2.52초 만에 끝나고 후보가 나온다. 저장한 항목은 「📴 오프라인 · 대기 5건」으로 표시되었다가, 로그인 상태라면 비행기 모드를 끄면 서버에 반영된다
- 스크린샷: 01_scan_start.png, 03_review.png, 05_added_list.png (상태 표시줄 ✈️)

### 원본 사진 미저장

- 조작: 인식·저장 후 `adb shell run-as com.example.scheduly_app find /data/data/com.example.scheduly_app -type f`를 실행한다
- 기대 결과: 사진 파일(jpg/png/heic/webp)이 하나도 없다. 검토 화면에 "원본 사진은 삭제되었습니다"가 보인다
- 스크린샷: 03_review.png

### 권한 거부 안내

- 조작: `adb shell pm revoke com.example.scheduly_app android.permission.CAMERA`로 권한을 지운 뒤 「촬영하기」를 누르고, 시스템 창에서 **허용 안함(Don't allow)**을 누른다
- 기대 결과: 앱이 종료되지 않고 "🚫 카메라 권한이 필요합니다" 안내와 「권한 다시 요청」·「갤러리에서 선택」 버튼이 보인다
- 스크린샷: 06_permission_request.png, 07_permission_denied.png

### 처리 시간 측정값

- 조작: 같은 픽스처로 비행기 모드 4회, 온라인 3회 인식한다
- 기대 결과: 검토 화면 상단에 "인식 n.nn초 (전체 n.nn초) · 기기 내 처리"가 표시되고, 측정값은 위 표와 같다
- 스크린샷: 03_review.png

시험 데이터: `tools/make_memo_fixture.py`로 만든 합성 메모 이미지 `fixtures/memo_fixture.png`(개인정보 없음, 제출물에 포함하지 않음)

네트워크: 불필요 (비행기 모드에서 확인). 서버 동기화 확인에만 온라인 필요

## MP3 동기화 (요약)

- Firebase Authentication(이메일/비밀번호) + Cloud Firestore `users/{uid}/todos/{id}`, 보안 규칙으로 본인 데이터만 접근 (`firebase/firestore.rules`)
- 로컬 SQLite가 기준이고, 변경은 `sync_status=pending` 대기열 → 온라인이면 업로드, 서버 변경은 실시간 리스너·새로고침으로 받음
- 충돌: 항목 단위 **마지막 수정 우선(LWW)**, Firestore 트랜잭션으로 더 최신 값만 기록, 삭제는 삭제 표시(tombstone)로 전파
- 설정 키는 `.env`(커밋 안 함) → `--dart-define-from-file`, 제출물에는 `.env.example`만 포함

## 개인정보

- 테스트에는 개인정보 없는 합성 메모 픽스처만 썼고, 원본 사진은 제출하지 않았습니다(`fixtures/`는 `.gitignore`).
- 앱 화면·소스의 이름·계정은 모두 더미 값이고, API 키·비밀번호는 소스·커밋·제출물에 없습니다.

## AI 도구 사용

주요 프롬프트와 AI 응답을 채택·수정한 내역은 `prompts_log.md`에 적었습니다.
