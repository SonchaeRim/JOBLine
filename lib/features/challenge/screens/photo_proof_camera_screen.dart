import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_colors.dart';
import 'photo_proof_form_screen.dart';

/// 문서 스캔 화면
/// 
/// flutter_doc_scanner 패키지를 사용하여 네이티브 문서 스캔 UI를 제공합니다.
/// 
/// iOS 설정:
/// - Info.plist에 NSCameraUsageDescription 키와 설명을 추가해야 합니다.
///   예: [NSCameraUsageDescription] 키와 "문서를 스캔하기 위해 카메라 권한이 필요합니다." 설명
/// 
/// Android 설정:
/// - minSdkVersion을 21 이상으로 설정해야 합니다.
class PhotoProofCameraScreen extends StatefulWidget {
  final String userId;

  const PhotoProofCameraScreen({
    super.key,
    required this.userId,
  });

  @override
  State<PhotoProofCameraScreen> createState() =>
      _PhotoProofCameraScreenState();
}

class _PhotoProofCameraScreenState
    extends State<PhotoProofCameraScreen> {
  bool _isScanning = false;

  /// 카메라 및 저장소 권한을 확인하고 요청합니다.
  Future<bool> _requestPermissions() async {
    if (!mounted) return false;
    final messenger = ScaffoldMessenger.of(context);

    // 카메라 권한 확인
    var cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('카메라 권한이 필요합니다. 설정에서 권한을 허용해주세요.'),
            duration: Duration(seconds: 3),
          ),
        );
        return false;
      }
    }

    // 저장소 권한 확인 (Android 버전에 따라 다름)
    if (Platform.isAndroid) {
      try {
        // Android 13 이상 (API 33+)에서는 Permission.photos 사용 시도
        var photosStatus = await Permission.photos.status;
        if (!photosStatus.isGranted) {
          photosStatus = await Permission.photos.request();
          if (!photosStatus.isGranted) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('사진 접근 권한이 필요합니다. 설정에서 권한을 허용해주세요.'),
                duration: Duration(seconds: 3),
              ),
            );
            return false;
          }
        }
      } catch (e) {
        // Permission.photos가 지원되지 않는 경우 (Android 12 이하)
        // Android 12 이하에서는 Permission.storage 사용
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.request();
          if (!storageStatus.isGranted) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('저장소 접근 권한이 필요합니다. 설정에서 권한을 허용해주세요.'),
                duration: Duration(seconds: 3),
              ),
            );
            return false;
          }
        }
      }
    }

    return true;
  }

  /// 문서 스캔을 시작합니다.
  /// 
  /// 스캔 결과가 여러 장이면 첫 번째 이미지만 사용합니다.
  /// (나중에 여러 장 지원 확장 가능)
  Future<void> _startDocumentScan() async {
    // 중복 호출 방지
    if (_isScanning) return;

    if (!mounted) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // 권한 확인 및 요청
    final hasPermission = await _requestPermissions();
    if (!hasPermission) {
      return;
    }

    setState(() {
      _isScanning = true;
    });

    FlutterDocScanner? scanner;
    try {
      // 스캔 인스턴스 생성 (매번 새로 생성하여 리소스 관리)
      scanner = FlutterDocScanner();
      final dynamic scanResult = await scanner.getScannedDocumentAsImages();


      // 사용자가 취소한 경우 (null 반환)
      if (scanResult == null) {
        // 아무 동작 안 함 (사용자가 취소한 것으로 간주)
        return;
      }

      // Map 형태로 반환되는 경우 처리
      String? firstImagePath;
      int pageCount = 0; // 스캔된 페이지 수 추적
      if (scanResult is Map) {
        // flutter_doc_scanner는 Map['Uri'] 키에 List를 반환
        // List 안에는 Page{imageUri=file:///...} 형태의 객체가 있음
        if (scanResult.containsKey('Uri')) {
          final uriValue = scanResult['Uri'];
          
          if (uriValue is List) {
            pageCount = uriValue.length;
            
            // 여러 페이지가 스캔된 경우 사용자에게 알림
            if (pageCount > 1) {
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text('여러 장이 스캔되었습니다. 첫 번째 페이지만 사용됩니다. ($pageCount장 스캔됨)'),
                  duration: const Duration(seconds: 3),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            
            if (uriValue.isNotEmpty) {
              final firstPage = uriValue.first;
              
              // Page 객체가 Map인 경우
              if (firstPage is Map) {
                if (firstPage.containsKey('imageUri')) {
                  final imageUri = firstPage['imageUri'];
                  if (imageUri is String) {
                    firstImagePath = imageUri;
                  }
                }
              }
              // Page 객체가 String 형태인 경우 (Page{imageUri=file:///...})
              else if (firstPage is String) {
                // 정규식으로 file:// URI 추출
                final uriMatch = RegExp(r'file://(/[^\s}]+)').firstMatch(firstPage);
                if (uriMatch != null) {
                  firstImagePath = uriMatch.group(1);
                } else {
                  // 정규식 실패 시 그대로 사용
                  firstImagePath = firstPage;
                }
              }
            }
          } 
          // Map[Uri]가 String인 경우 (실제 반환 형태)
          else if (uriValue is String) {
            // String에서 file:// URI 추출
            // 예: [Page{imageUri=file:///data/...}] 형태에서 file:///... 부분 추출
            final uriMatch = RegExp(r'file://(/[^\s}]+)').firstMatch(uriValue);
            if (uriMatch != null) {
              firstImagePath = uriMatch.group(1);
            }
          }
        }
        // 다른 키들도 확인 (기존 호환성)
        else if (scanResult.containsKey('images') && scanResult['images'] is List) {
          final List images = scanResult['images'] as List;
          pageCount = images.length;
          if (pageCount > 1) {
            if (!mounted) return;
            messenger.showSnackBar(
              SnackBar(
                content: Text('여러 장이 스캔되었습니다. 첫 번째 페이지만 사용됩니다. ($pageCount장 스캔됨)'),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.orange,
              ),
            );
          }
          if (images.isNotEmpty && images.first is String) {
            firstImagePath = images.first as String;
          }
        } else if (scanResult.containsKey('paths') && scanResult['paths'] is List) {
          final List paths = scanResult['paths'] as List;
          pageCount = paths.length;
          if (pageCount > 1) {
            if (!mounted) return;
            messenger.showSnackBar(
              SnackBar(
                content: Text('여러 장이 스캔되었습니다. 첫 번째 페이지만 사용됩니다. ($pageCount장 스캔됨)'),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.orange,
              ),
            );
          }
          if (paths.isNotEmpty && paths.first is String) {
            firstImagePath = paths.first as String;
          }
        } else if (scanResult.containsKey('files') && scanResult['files'] is List) {
          final List files = scanResult['files'] as List;
          pageCount = files.length;
          if (pageCount > 1) {
            if (!mounted) return;
            messenger.showSnackBar(
              SnackBar(
                content: Text('여러 장이 스캔되었습니다. 첫 번째 페이지만 사용됩니다. ($pageCount장 스캔됨)'),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.orange,
              ),
            );
          }
          if (files.isNotEmpty && files.first is String) {
            firstImagePath = files.first as String;
          }
        }
      } else if (scanResult is List && scanResult.isNotEmpty && scanResult.first is String) {
        // List 형태로 반환되는 경우 (기존 코드 호환)
        pageCount = scanResult.length;
        if (pageCount > 1) {
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text('여러 장이 스캔되었습니다. 첫 번째 페이지만 사용됩니다. ($pageCount장 스캔됨)'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.orange,
            ),
          );
        }
        firstImagePath = scanResult.first as String;
      }
      
      // file:// URI를 일반 파일 경로로 변환
      if (firstImagePath != null && firstImagePath.startsWith('file://')) {
        firstImagePath = firstImagePath.replaceFirst('file://', '');
      }

      // 이미지 경로를 찾지 못한 경우
      if (firstImagePath == null || firstImagePath.isEmpty) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(
            content: Text('스캔 결과를 처리할 수 없습니다.'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // 파일 경로 정규화
      final normalizedPath = firstImagePath.replaceAll(RegExp(r'[/]+'), '/');
      final File imageFile = File(normalizedPath);
      
      // 파일 존재 여부 확인
      final fileExists = await imageFile.exists();
      
      if (!fileExists) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text('이미지 파일을 찾을 수 없습니다.\n경로: $firstImagePath'),
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }


      // 스캔 인스턴스 해제 (명시적으로 null로 설정하여 GC 유도)
      scanner = null;

      // Android ImageReader 및 Surface 리소스 해제를 위한 딜레이
      // GmsDocumentScanningDelegateActivity가 완전히 종료될 시간을 확보
      await Future.delayed(const Duration(milliseconds: 200));

      // 파일이 여전히 존재하는지 재확인
      if (!await imageFile.exists()) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(
            content: Text('파일이 삭제되었습니다. 다시 스캔해주세요.'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // 스캔 후 즉시 폼 화면으로 이동
      if (!mounted) return;
      navigator.push(
        MaterialPageRoute(
          builder: (context) => PhotoProofFormScreen(
            userId: widget.userId,
            imageFile: imageFile,
          ),
        ),
      );
    } on PlatformException catch (e) {
      // 스캔 실패 시 에러 메시지 표시
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('문서 스캔에 실패했습니다: ${e.message ?? '알 수 없는 오류'}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // 기타 예외 처리
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('문서 스캔 중 오류가 발생했습니다: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      // 스캔 인스턴스 명시적 해제
      scanner = null;
      
      // 스캔 상태 해제
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('문서 스캔'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.document_scanner,
              size: 80,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            const Text(
              '인증서류를 스캔하려면\n아래 버튼을 눌러주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '문서를 카메라로 촬영하면\n자동으로 스캔됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _isScanning ? null : _startDocumentScan,
              icon: _isScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.camera_alt),
              label: Text(
                _isScanning ? '스캔 중...' : '문서 스캔 시작',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

