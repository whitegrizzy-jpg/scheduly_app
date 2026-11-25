# Scheduly — 할 일 앱 (주제 #2109 MP3: 백엔드 서비스로 동기화하기)

Flutter 할 일 앱입니다. MP2의 로컬 저장(SQLite) CRUD에 이어 MP3에서는 **Firebase(Authentication + Cloud Firestore)** 와 연동해
**같은 계정으로 로그인한 여러 기기에서 같은 목록**을 보고, **오프라인에서 쓴 항목이 온라인으로 돌아오면 서버에 반영**되도록 했습니다.

## 실행 절차

- 프레임워크/SDK: **Flutter 3.47.5 (stable) / Dart 3.13.4**
- 실행 기기: Android 에뮬레이터 **Pixel_8 (기기 A)**, **Pixel_8_B (기기 B)** — 둘 다 Android 17 / API 37, 1080×2400
- 백엔드: **Firebase** 무료 요금제(Spark) — Authentication(이메일/비밀번호), Cloud Firestore(서울 `asia-northeast3`)
- 주요 패키지: `firebase_core 5.x`, `firebase_auth 7.x`, `cloud_firestore 7.x`, `connectivity_plus 7.x`, `sqflite 2.4.x`
- 잠금 파일: `pubspec.lock`, `android/gradle/wrapper/gradle-wrapper.properties`

제출 ZIP에서는 Flutter 프로젝트가 `app/` 폴더에 있으므로 먼저 `cd app` 한 뒤 실행합니다.

```bash
flutter --version                      # Flutter 3.47.5 / Dart 3.13.4 확인
flutter pub get
cp .env.example .env                   # 아래 "백엔드 설정 절차"대로 값을 채운다
flutter emulators --launch Pixel_8
flutter run --dart-define-from-file=.env
```

두 번째 기기(동기화 확인용):

```bash
flutter emulators --launch Pixel_8_B
flutter run -d emulator-5556 --dart-define-from-file=.env
```

테스트 실행 (위젯 8개 + SQLite 3개 + 동기화 시나리오 7개 = 18개, 서버 없이 실행됨):

```bash
flutter test
```

- `.env` 없이 `flutter run`만 하면 서버 동기화 없이 **로컬 전용 모드**(MP2와 동일)로 동작합니다.
- 클라우드 모드에서는 로그인 화면의 **회원가입**으로 테스트 계정(예: `test1@example.com` 같은 더미 주소)을 만든 뒤, 두 기기에서 **같은 계정으로 로그인**합니다.

## 백엔드 설정 절차 (Firebase)

1. [Firebase 콘솔](https://console.firebase.google.com)에서 프로젝트를 만든다 (애널리틱스는 꺼도 됨).
2. **Authentication → 로그인 방법 → 이메일/비밀번호** 사용 설정
3. **Firestore Database → 데이터베이스 만들기** (위치 `asia-northeast3`, 프로덕션 모드) → **규칙** 탭에 [`firebase/firestore.rules`](firebase/firestore.rules) 내용을 붙여넣고 게시
4. **프로젝트 설정 → 내 앱 → Android 앱 추가**, 패키지 이름 `com.example.scheduly_app`
5. 같은 화면의 값으로 `.env`를 채운다. API 키는 내려받은 `google-services.json`의 `current_key` 값이다.

| `.env` 키 | 값을 찾는 곳 |
|---|---|
| `FIREBASE_API_KEY` | `google-services.json` → `client[0].api_key[0].current_key` |
| `FIREBASE_APP_ID` | 프로젝트 설정 → 내 앱 → 앱 ID (`1:…:android:…`) |
| `FIREBASE_MESSAGING_SENDER_ID` | 프로젝트 번호 (앱 ID 가운데 숫자) |
| `FIREBASE_PROJECT_ID` | 프로젝트 ID |
| `FIREBASE_STORAGE_BUCKET` | (선택) 비워도 됨 |

### 설정 키 분리

- 키는 소스에 없습니다. `--dart-define-from-file=.env`로 **빌드할 때만** 주입되고, `lib/config/env.dart`에서 읽습니다.
- `.env`, `.env.*`, `google-services.json`, `firebase_options.dart`는 `.gitignore`에 있습니다. 저장소와 제출물에는 **`.env.example`(빈 값)만** 들어 있습니다.
- 데이터 보호는 키를 숨기는 것이 아니라 **보안 규칙**으로 합니다: 로그인한 사용자는 자기 `uid` 아래(`users/{uid}/todos`)만 읽고 쓸 수 있습니다.

## 선택한 BaaS: Firebase, 그리고 이유

| 항목 | **Firebase (선택)** | Supabase |
|---|---|---|
| 데이터베이스 | Cloud Firestore (문서형 NoSQL) | PostgreSQL (관계형) |
| Flutter 지원 | 공식 FlutterFire 플러그인 (`firebase_auth`, `cloud_firestore`) | 공식 `supabase_flutter` |
| 실시간 변경 | 문서 스냅샷 리스너 기본 제공 | Realtime(Postgres 변경 구독) |
| 서버 쪽 비교 후 쓰기 | 트랜잭션(`runTransaction`)으로 바로 가능 | RPC(SQL 함수) 또는 정책 작성 필요 |
| 접근 제어 | 보안 규칙 (경로 + `request.auth.uid`) | Row Level Security 정책 |
| 무료 요금제 | Spark: 읽기 5만·쓰기 2만/일 | 프로젝트 2개, 7일 비활성 시 일시 중지 |

1. 팀이 9주차 기술 보고서에서 이미 Firebase를 골랐고, Authentication과 데이터베이스를 한 콘솔에서 바로 설정할 수 있습니다.
2. 동기화 충돌 처리에 필요한 **"서버 값과 비교한 뒤 더 최신일 때만 쓰기"** 를 Firestore 트랜잭션으로 SQL 함수 없이 클라이언트 코드에서 구현할 수 있습니다.
3. 할 일 데이터는 사용자별 독립 목록이라 관계형 JOIN이 필요 없고, `users/{uid}/todos/{id}` 문서 구조와 경로 기반 보안 규칙이 잘 맞습니다.
4. 무료 요금제에 일시 중지 정책이 없어, 과제 검수 기간에 서버가 멈출 걱정이 없습니다.

## 동기화 구조와 충돌 처리 방침

```
화면 ──▶ SyncingTodoRepository ──▶ SQLite (로컬, 항상 먼저 저장)
                                      │  sync_status = pending (대기열)
                                      ▼
                                 SyncService ──push──▶ Firestore users/{uid}/todos/{id}
                                      ▲      ◀─pull── (실시간 리스너 + 새로고침)
                         connectivity_plus (온라인/오프라인 감지)
```

### 오프라인 → 온라인 흐름

1. 추가·수정·완료·삭제는 **항상 로컬 SQLite에 먼저 저장**하고 `sync_status = pending`, `updated_at = 지금`으로 표시합니다. 그래서 오프라인에서도 화면에 바로 반영됩니다.
2. 온라인이면 대기 항목을 **오래된 순서대로** 서버에 올리고, 성공하면 `synced`로 바꿉니다.
3. 오프라인이면 홈 화면 배지에 `📴 오프라인 · 대기 n건`이 보이고, 대기열은 기기에 남아 있습니다(앱을 꺼도 유지).
4. **네트워크가 다시 연결되면**(`connectivity_plus` 이벤트) 자동으로 대기열을 올리고, 실패하면 20초마다 다시 시도합니다. 배지를 누르거나 목록을 당겨도 즉시 동기화합니다.
5. 서버 쪽 변경은 Firestore 실시간 리스너와 새로고침(당겨서 새로고침)으로 받아 로컬에 반영합니다.
6. Firestore 자체 오프라인 캐시는 끄고(`persistenceEnabled: false`) 대기열을 앱이 직접 관리합니다. 대기 건수를 화면에 보여 주고, 충돌 규칙을 한곳(`SyncService`)에서 통제하기 위해서입니다.

### 충돌 처리 방침: 마지막 수정 우선 (Last-Write-Wins, 항목 단위)

- 모든 항목에 `updated_at`(마지막 수정 시각, 밀리초)을 둡니다.
- **서버에 올릴 때**: Firestore 트랜잭션으로 서버 문서를 읽어 `서버.updated_at ≥ 내 updated_at`이면 쓰지 않고 서버 값을 받아 로컬을 덮어씁니다. 내 값이 더 최신일 때만 기록합니다. 두 기기가 동시에 올려도 더 최신 값만 남습니다.
- **서버에서 받을 때**: `서버.updated_at > 로컬.updated_at`일 때만 로컬에 반영합니다. 로컬이 더 최신(아직 못 올린 변경)이면 무시하고, 이후 로컬 값이 서버로 올라갑니다.
- **삭제**: 행을 바로 지우지 않고 `deleted = true`인 **삭제 표시(tombstone)** 로 저장해 같은 규칙으로 전파합니다. 그래서 "한 기기에서 삭제, 다른 기기에서 옛 값 재업로드"로 삭제한 항목이 되살아나지 않습니다.
- **판단 이유**: 할 일 한 건은 제목·기한·완료 여부가 짧고 한 사람이 쓰는 데이터라, 필드 단위 병합보다 "가장 나중에 고친 내용"을 남기는 편이 사용자가 예상하기 쉽고 구현·검증이 단순합니다.
- **한계와 보완**: 기기 시계가 크게 틀리면 순서가 뒤바뀔 수 있습니다(같은 계정의 개인 기기 기준이라 허용). 같은 항목을 두 기기에서 오프라인으로 동시에 고치면 먼저 고친 쪽 내용은 사라집니다. 이 동작은 `test/sync_service_test.dart`의 충돌 테스트 2개로 확인했습니다.

### 로컬 DB 변경 (MP2 → MP3)

`todos` 테이블에 `updated_at`, `deleted`, `sync_status` 칼럼을 추가하고 DB 버전을 2로 올렸습니다. MP2를 쓰던 기기는 `onUpgrade`로 데이터를 그대로 둔 채 칼럼만 추가되고, 기존 항목은 첫 로그인 때 서버로 올라갑니다. 로그인한 사용자마다 로컬 DB 파일을 따로 둡니다(`scheduly_{uid}.db`).

## 구현 기능 목록

| 기능 | 설명 | 위치 |
|---|---|---|
| 회원가입·로그인·로그아웃 | Firebase Authentication 이메일/비밀번호, 오류 문구 한국어 처리, 다시 실행하면 로그인 유지 | `lib/services/auth_service.dart`, `login_screen.dart` |
| 기기 간 동기화 | 같은 계정의 할 일이 Firestore를 통해 모든 기기에 반영 (실시간 + 당겨서 새로고침) | `lib/data/sync_service.dart` |
| 오프라인 작성 → 온라인 반영 | SQLite 대기열 + 연결 감지 후 자동 업로드 + 20초 재시도 | `SyncService`, `SqfliteTodoRepository` |
| 충돌 처리 | 항목 단위 LWW, Firestore 트랜잭션, 삭제 표시 | `FirestoreTodoStore.pushIfNewer`, `applyRemote` |
| 동기화 상태 배지 | ☁️ 서버와 동기화됨 / ⏳ 대기 n건 / 📴 오프라인 · 대기 n건 / ⚠️ 실패. 누르면 즉시 동기화 | `_SyncBadge` |
| 설정 키 분리 | `.env` → `--dart-define-from-file`, `.env.example`만 커밋 | `lib/config/env.dart` |
| 보안 규칙 | 본인 `uid` 경로만 읽기·쓰기 허용 | `firebase/firestore.rules` |
| (MP2 유지) CRUD·필터 | 추가·수정·완료·삭제(되돌리기), 전체/미완료/완료 필터 | `home_screen.dart` |

## 확인 방법

### 기기 A에서 추가 → 기기 B 새로고침 후 표시

- 조작: 두 에뮬레이터에서 같은 테스트 계정으로 로그인한다. 기기 A에서 `+`를 눌러 "Added on device A"를 추가한 뒤, 기기 B에서 목록을 아래로 당겨 새로고침한다
- 기대 결과: 기기 A 배지가 「☁️ 서버와 동기화됨」으로 돌아오고, 기기 B 목록에 "Added on device A"가 나타난다 (전체 1)
- 스크린샷: 01_deviceA_added.png, 02_deviceB_synced.png

### 오프라인 작성 → 온라인 복귀 후 서버 반영

- 조작: 기기 A를 비행기 모드로 바꾸고(`adb -s emulator-5554 shell cmd connectivity airplane-mode enable`) "Written while offline"을 추가한다. 기기 B를 새로고침한다. 그다음 기기 A의 비행기 모드를 끄고(`… airplane-mode disable`) 기기 B를 다시 새로고침한다
- 기대 결과: 오프라인인 기기 A에는 항목이 바로 보이고 배지가 「📴 오프라인 · 대기 1건」이다. 이때 기기 B에는 아직 없다. 비행기 모드를 끄면 기기 A 배지가 「☁️ 서버와 동기화됨」으로 바뀌고, 기기 B에도 "Written while offline"이 나타난다 (전체 2)
- 스크린샷: 03_offline_pending.png, 04_deviceB_before.png, 05_online_synced.png, 06_deviceB_after.png

### 백엔드 콘솔

- 조작: Firebase 콘솔 → Firestore Database → 데이터에서 `users/{uid}/todos`를 연다
- 기대 결과: 앱에서 추가한 두 항목이 문서(`text`, `done`, `updatedAt`, `deleted` 등)로 저장되어 있다
- 스크린샷: 07_backend_console.png

### 충돌 처리 (자동 테스트)

- 조작: `flutter test test/sync_service_test.dart`
- 기대 결과: 기기 A→B 동기화, 오프라인 대기열, 충돌 2종(LWW), 삭제 전파, 서버 오류 후 재시도, MP2 DB 업그레이드 등 7개 시나리오가 모두 통과한다
- 스크린샷: 없음 (터미널 결과)

시험 데이터: 앱에서 직접 입력한 더미 할 일 "Added on device A", "Written while offline" / 테스트 계정은 회원가입 화면에서 만든 더미 이메일(실제 개인 메일 아님)

네트워크: 필요 (온라인 상태에서 동기화 확인). 오프라인 확인은 에뮬레이터 비행기 모드로 진행

## 개인정보

- 앱 화면과 소스의 이름·계정은 모두 더미 값입니다. 회원가입에서 실명을 받지 않도록 이름 칸을 없앴습니다.
- API 키·테스트 계정 비밀번호는 소스·커밋·제출물에 없습니다(`.env`, `.env.test`는 `.gitignore`).

## AI 도구 사용

주요 프롬프트와 AI 응답을 채택·수정한 내역은 `prompts_log.md`에 적었습니다.
