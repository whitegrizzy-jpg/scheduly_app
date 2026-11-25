import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../config/env.dart';
import '../data/remote_todo_store.dart';
import '../data/sync_service.dart';
import '../data/todo_repository.dart';

/// 앱 전역 서비스.
/// - 로컬 전용 모드: SQLite만 사용 (MP2와 동일, 서버 설정이 없을 때)
/// - 클라우드 모드: 로그인한 사용자별 SQLite + Firestore 동기화 (MP3)
class AppServices {
  /// 화면이 사용하는 저장소. 테스트에서는 메모리 저장소로 바꿔 끼운다.
  static TodoRepository todos = SqfliteTodoRepository();

  /// 로컬 전용 모드 저장소를 만드는 함수 (테스트에서 메모리 저장소로 교체)
  static TodoRepository Function() localRepoFactory = SqfliteTodoRepository.new;

  /// 클라우드 모드일 때만 존재한다.
  static SyncService? sync;

  static bool firebaseReady = false;

  /// 앱 시작 시: .env 값이 있으면 Firebase를 초기화한다.
  static Future<void> init() async {
    if (!Env.hasFirebase) return;
    await Firebase.initializeApp(options: Env.firebaseOptions);
    // 오프라인 대기열은 앱이 직접(SQLite) 관리하므로 Firestore 자체 오프라인 캐시는 끈다.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
    firebaseReady = true;
  }

  static User? get currentUser =>
      firebaseReady ? FirebaseAuth.instance.currentUser : null;

  /// 로그인 없이 쓰는 로컬 전용 모드
  static Future<void> startLocalSession() async {
    await endSession(signOut: false);
    todos = localRepoFactory();
  }

  /// 로그인한 사용자의 클라우드 동기화 세션
  static Future<void> startCloudSession(User user) async {
    await endSession(signOut: false);
    // 사용자마다 로컬 DB를 따로 둔다. 서버와 맞출 목록이므로 시험 데이터는 넣지 않는다.
    final local = SqfliteTodoRepository(
      dbName: 'scheduly_${user.uid}.db',
      seedSamples: false,
    );
    final remote = FirestoreTodoStore(
      firestore: FirebaseFirestore.instance,
      uid: user.uid,
    );
    final conn = Connectivity();
    bool isOnline(List<ConnectivityResult> r) =>
        r.any((e) => e != ConnectivityResult.none);
    final initial = isOnline(await conn.checkConnectivity());
    final service = SyncService(
      local: local,
      remote: remote,
      connectivity: conn.onConnectivityChanged.map(isOnline),
      initiallyOnline: initial,
    );
    sync = service;
    todos = SyncingTodoRepository(local, service);
    await service.start();
  }

  static Future<void> endSession({bool signOut = true}) async {
    sync?.dispose();
    sync = null;
    if (signOut && firebaseReady) await FirebaseAuth.instance.signOut();
  }
}
