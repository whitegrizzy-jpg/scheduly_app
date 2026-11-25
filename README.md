# Scheduly — 할 일 앱 (주제 #2109 MP2: 저장되는 앱으로 만들기)

Flutter로 만든 할 일 관리 앱입니다. MP1의 화면(목록·추가·완료 토글·빈 상태)에 이어 MP2에서는
**로컬 저장(SQLite)** 을 붙이고 **수정·삭제·필터** 를 더해 CRUD를 완성했습니다. 앱을 껐다 켜도 할 일이 그대로 남습니다.

## 실행 절차

- 프레임워크/SDK: **Flutter 3.47.5 (stable) / Dart 3.13.4**
- 실행 기기: Android 에뮬레이터 **Pixel_8 (Android 17 / API 37, 1080×2400)**
- 로컬 저장소 라이브러리: `sqflite 2.4.x` (+ `path`), 테스트용 `sqflite_common_ffi`
- 잠금 파일: `pubspec.lock`, `android/gradle/wrapper/gradle-wrapper.properties`

제출 ZIP에서는 Flutter 프로젝트가 `app/` 폴더에 있으므로 먼저 `cd app` 한 뒤 실행합니다.

```bash
flutter --version          # Flutter 3.47.5 / Dart 3.13.4 확인
flutter pub get
flutter emulators --launch Pixel_8
flutter run
```

테스트 실행 (위젯 테스트 8개 + SQLite 저장소 테스트 3개):

```bash
flutter test
```

앱이 켜지면 로그인 화면에서 **「로그인 없이 둘러보기」** 를 누르거나, 아무 아이디·비밀번호를 입력하고 **로그인** 을 누르면 홈(할 일 목록)으로 들어갑니다.
(MP1·MP2는 데모 모드입니다. 계정 정보는 소스에 두지 않으며, 실제 인증은 MP3에서 BaaS로 연결합니다.)

처음 설치하면 시험 데이터 4개가 DB에 한 번 들어갑니다. 처음 상태로 되돌리려면 앱 데이터를 지우거나 다시 설치합니다.

```bash
adb shell pm clear com.example.scheduly_app
```

## 저장 방식: sqflite(SQLite)를 고른 이유

### 대안 비교

| 항목 | **sqflite (SQLite)** ✅ | shared_preferences | Hive / Isar (NoSQL) | Drift (SQLite ORM) |
|---|---|---|---|---|
| 저장 형태 | 테이블(행·열), SQL | 키-값 (문자열·숫자·bool·문자열 목록) | 객체·박스 단위 | 테이블 + 타입 안전 쿼리 |
| 할 일 목록 저장 | 행 단위 INSERT / UPDATE / DELETE | 목록 전체를 JSON 문자열로 만들어 통째로 덮어써야 함 | 객체 단위 저장 가능 | 행 단위, 코드 생성 필요 |
| 정렬·필터 | `ORDER BY`, `WHERE`로 바로 가능 | 앱에서 전부 읽은 뒤 직접 처리 | 쿼리 기능 있음(라이브러리마다 다름) | SQL과 같음 |
| 스키마 변경 | `version` + `onUpgrade` 마이그레이션 | 없음 (형식이 바뀌면 직접 변환) | 어댑터·스키마 관리 필요 | 마이그레이션 도구 제공 |
| 설정 난이도 | 낮음 (코드 생성 없음) | 가장 낮음 | 중간 (어댑터·코드 생성) | 높음 (build_runner) |
| 유지 상태 | Flutter 진영 표준, 꾸준히 관리됨 | 공식 플러그인 | Hive v2는 관리가 사실상 멈췄고, Isar도 유지보수가 불안정 | 활발 |
| MP3(BaaS 동기화)와의 연결 | 행마다 `id`·`created_at`이 있어 동기화 대기열·충돌 비교 칼럼을 추가하기 쉬움 | 부분 동기화가 어려움 | 가능 | 가능 |

### 선택 이유

1. **할 일은 "같은 모양의 레코드 여러 개"** 입니다. 추가·수정·삭제가 한 행씩 일어나므로, 목록 전체를 매번 다시 쓰는 shared_preferences보다 행 단위 SQL이 자연스럽고 데이터가 깨질 위험도 적습니다.
2. **정렬(최신순)과 필터(완료 여부)** 를 SQL로 표현할 수 있고, 항목이 늘어도 성능이 안정적입니다.
3. **MP3 대비**: 다음 단계에서 `updated_at`, `sync_status` 같은 칼럼을 추가해 오프라인 대기열을 만들 계획입니다. `onUpgrade` 마이그레이션으로 기존 사용자의 데이터를 지키며 스키마를 바꿀 수 있습니다.
4. Drift도 좋지만 코드 생성(build_runner)이 필요해 팀원 모두의 빌드 과정이 복잡해지고, Hive/Isar는 유지보수 상태가 불안정해 제외했습니다.
5. shared_preferences는 "마지막으로 고른 필터" 같은 **작은 설정값** 저장에는 알맞아, 이후 설정 저장용으로 함께 쓸 수 있습니다.

### 구조

```
HomeScreen ──▶ TodoRepository (인터페이스)
                 ├─ SqfliteTodoRepository   ← 앱 실행 시 (scheduly.db / todos 테이블)
                 └─ InMemoryTodoRepository  ← 위젯 테스트
```

- 화면은 `TodoRepository`만 알기 때문에, MP3에서 BaaS 저장소를 추가해도 화면 코드는 거의 바꾸지 않아도 됩니다. (`lib/data/todo_repository.dart`)
- 화면 상태를 먼저 바꿔 즉시 반영하고, 같은 내용을 DB에 기록합니다.
- 테이블: `todos(id INTEGER PK, text TEXT, done INTEGER(0/1), due TEXT, priority TEXT, created_at INTEGER)`

## 구현 기능 목록

| 기능 | 설명 | 위치 |
|---|---|---|
| **조회(Read)** | 앱이 시작되면 DB에서 최신순으로 읽어 미완료 → 완료됨 순으로 표시 | `_loadTodos()` |
| **추가(Create)** | `+` → 입력 → **추가**. 공백은 "할 일을 입력해주세요" 안내 후 무시 | `_addTodo()` |
| **수정(Update)** | 카드의 ✏️ 버튼(또는 길게 누르기) → 수정 시트에서 제목·기한·우선순위를 바꿔 **저장** (빈 제목은 저장 불가) | `_editTodo()`, `_EditTodoSheet` |
| 완료 토글 | 카드를 탭하면 완료/미완료가 바뀌고 DB에도 저장 | `_toggleTodo()` |
| **삭제(Delete)** | 카드를 왼쪽으로 밀면 삭제, 스낵바 **되돌리기**로 복구 (DB에서도 삭제/복구) | `_deleteTodo()` |
| **필터** | 전체 / 미완료 / 완료 칩. 각 칩에 개수 표시 | `_FilterBar`, `_buildTodoList()` |
| 재시작 후 유지 | 위 모든 변경이 SQLite에 저장되어 앱을 강제 종료 후 다시 켜도 유지 | `SqfliteTodoRepository` |
| 빈 상태 안내 | 할 일이 0개면 안내와 **할 일 추가하기** 버튼 표시 (전부 지운 상태도 재시작 후 유지) | `_EmptyTodoState` |

캘린더·단체·손글씨 탭과 홈 화면의 메모는 아직 화면 시안이며 저장하지 않습니다. (손글씨는 MP4에서 OCR로 교체 예정)

## 확인 방법

### 할 일 목록 조회

- 조작: 앱을 처음 설치해 실행하고 「로그인 없이 둘러보기」를 누른다
- 기대 결과: DB에 들어간 시험 데이터 4개가 보이고, 필터 칩에 전체 4 / 미완료 3 / 완료 1이 표시된다
- 스크린샷: 01_list.png

### 항목 수정

- 조작: 「알고리즘 과제 3번 풀기」 카드의 ✏️를 눌러 제목 끝에 " + ch.4"를 붙이고, 기한을 "Fri 18:00"으로 바꾸고, 우선순위를 「긴급」으로 고른 뒤 **저장**을 누른다
- 기대 결과: 카드 제목·기한이 바뀌고 배지가 「긴급」(빨간색)으로 바뀐다
- 스크린샷: 02_edit_sheet.png, 03_edited.png

### 필터 전환

- 조작: 「캡스톤 설계 보고서 제출」을 탭해 완료한 뒤, 「미완료」와 「완료」 칩을 차례로 누르고 「전체」로 돌아온다
- 기대 결과: 미완료에는 완료 안 된 2개만, 완료에는 완료된 2개만 보이고, 칩 개수가 전체 4 / 미완료 2 / 완료 2로 바뀐다
- 스크린샷: 04_filter_pending.png, 05_filter_done.png

### 항목 삭제

- 조작: 「데이터베이스 중간고사 공부」 카드를 왼쪽으로 민다
- 기대 결과: 카드가 사라지고 "'데이터베이스 중간고사 공부' 삭제됨" 스낵바와 **되돌리기**가 3초간 보인다. 칩이 전체 3 / 미완료 1 / 완료 2가 된다
- 스크린샷: 06_delete_undo.png

### 재시작 후 데이터 유지

- 조작: 위 상태에서 앱을 강제 종료한 뒤(최근 앱에서 밀어 닫기 또는 `adb shell am force-stop com.example.scheduly_app`) 다시 실행하고 「로그인 없이 둘러보기」를 누른다
- 기대 결과: 종료 전과 같이 수정된 제목·기한·우선순위, 완료 상태, 삭제 결과가 그대로 보인다 (전체 3 / 미완료 1 / 완료 2)
- 스크린샷: 07_before_restart.png, 08_relaunch_login.png, 09_after_restart.png

시험 데이터: lib/data/sample_todos.dart (처음 설치할 때 DB에 한 번 들어가는 더미 할 일 4개, 실제 개인정보 없음)

네트워크: 불필요 (모든 데이터는 기기 안의 SQLite에 저장, 오프라인/비행기 모드에서도 동작)

## 개인정보

- 앱 화면과 소스의 이름·계정은 모두 더미 값입니다(「데모 사용자」, 「팀원A~L」).
- 계정 정보와 API 키는 소스에 없습니다.

## AI 도구 사용

주요 프롬프트와 AI 응답을 채택·수정한 내역은 `prompts_log.md`에 적었습니다.
