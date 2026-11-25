import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

enum PhotoOrigin { camera, gallery }

/// 카메라 권한 상태 (permission_handler 결과를 단순화)
enum CameraAccess { granted, denied, permanentlyDenied }

/// 사진 가져오기 + 카메라 권한. 테스트에서는 가짜 구현으로 바꿔 끼운다.
abstract class PhotoSource {
  Future<CameraAccess> requestCamera();

  /// 사진 파일 경로. 사용자가 취소하면 null.
  Future<String?> pick(PhotoOrigin origin);

  Future<void> openSettings();
}

class DevicePhotoSource implements PhotoSource {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<CameraAccess> requestCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted || status.isLimited) return CameraAccess.granted;
    if (status.isPermanentlyDenied || status.isRestricted) {
      return CameraAccess.permanentlyDenied;
    }
    return CameraAccess.denied;
  }

  @override
  Future<String?> pick(PhotoOrigin origin) async {
    final file = await _picker.pickImage(
      source: origin == PhotoOrigin.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      // 인식에 충분한 해상도로 줄여 처리 시간을 줄인다 (원본은 갤러리에 그대로, 앱에는 사본만)
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 90,
      requestFullMetadata: false, // 위치 등 EXIF 메타데이터를 요청하지 않음
    );
    return file?.path;
  }

  @override
  Future<void> openSettings() => openAppSettings();
}
