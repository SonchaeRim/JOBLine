import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/certification.dart';
import '../services/proof_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../xp/models/xp_rule.dart';

/// 인증 폼 작성 화면
class PhotoProofFormScreen extends StatefulWidget {
  final String userId;
  final File? imageFile; // 수정 모드에서는 null일 수 있음
  final String? certificationId; // 수정 모드일 때 사용
  final Certification? existingCertification; // 수정 모드일 때 기존 데이터

  const PhotoProofFormScreen({
    super.key,
    required this.userId,
    this.imageFile,
    this.certificationId,
    this.existingCertification,
  });

  @override
  State<PhotoProofFormScreen> createState() =>
      _PhotoProofFormScreenState();
}

class _PhotoProofFormScreenState
    extends State<PhotoProofFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _certificationNameController = TextEditingController();
  final ProofService _proofService = ProofService();
  bool _isLoading = false;
  
  // 인증 유형 선택
  CertificationType? _selectedCertificationType;
  
  bool get _isEditMode => widget.certificationId != null && widget.existingCertification != null;
  
  @override
  void initState() {
    super.initState();
    // 수정 모드인 경우 기존 데이터 로드
    if (_isEditMode && widget.existingCertification != null) {
      _loadExistingData(widget.existingCertification!);
    }
  }
  
  void _loadExistingData(Certification cert) {
    _certificationNameController.text = cert.description ?? '';
    _selectedCertificationType = cert.certificationType;
    
    if (cert.certificationDetails != null) {
      final details = cert.certificationDetails!;
      
      if (cert.certificationType == CertificationType.license) {
        _licenseType = details['licenseType'] as String?;
        _licenseCategory = details['category'] as String?;
        _licenseGrade = details['grade'] as String?;
        _privateLicenseType = details['privateType'] as String?;
      } else if (cert.certificationType == CertificationType.publicServiceExam) {
        _publicServiceExamType = details['examType'] as String?;
      } else if (cert.certificationType == CertificationType.languageExam) {
        _languageExamType = details['examType'] as String?;
        final score = details['score'] ?? details['grade'];
        if (score != null) {
          _languageScoreController.text = score.toString();
        }
      } else if (cert.certificationType == CertificationType.contest) {
        _contestScale = details['scale'] as String?;
        _contestResult = details['result'] as String?;
      }
    }
  }
  
  // 자격증 관련 필드
  String? _licenseType; // 'national', 'national_professional', 'private'
  String? _licenseCategory; // 'technical', 'service'
  String? _licenseGrade; // 등급
  String? _privateLicenseType; // 'national_approved', 'registered'
  
  // 공무원 시험 필드
  String? _publicServiceExamType; // '7급', '9급', '소방', '경찰'
  
  // 외국어 시험 필드
  String? _languageExamType; // '한국사', 'TOEIC', 'TOEFL' 등
  final _languageScoreController = TextEditingController();
  
  // 공모전 필드
  String? _contestScale; // 'international', 'national', 'local'
  String? _contestResult; // '대상', '입상', '입선', '참가'

  @override
  void dispose() {
    _certificationNameController.dispose();
    _languageScoreController.dispose();
    super.dispose();
  }
  
  /// 선택한 인증 유형에 따른 상세 정보 생성
  Map<String, dynamic>? _buildCertificationDetails() {
    if (_selectedCertificationType == null) return null;
    
    switch (_selectedCertificationType!) {
      case CertificationType.license:
        if (_licenseType == 'national') {
          return <String, dynamic>{
            'licenseType': _licenseType,
            'category': _licenseCategory,
            'grade': _licenseGrade,
          };
        } else if (_licenseType == 'national_professional') {
          return <String, dynamic>{
            'licenseType': _licenseType,
            'grade': _licenseGrade,
          };
        } else if (_licenseType == 'private') {
          return <String, dynamic>{
            'licenseType': _licenseType,
            'privateType': _privateLicenseType,
            'grade': _licenseGrade,
          };
        }
        return null;
        
      case CertificationType.publicServiceExam:
        return <String, dynamic>{
          'examType': _publicServiceExamType,
        };
        
      case CertificationType.languageExam:
        return _buildLanguageExamDetails();
        
      case CertificationType.contest:
        return <String, dynamic>{
          'scale': _contestScale,
          'result': _contestResult,
        };
        
      case CertificationType.exhibition:
      case CertificationType.otherActivity:
        return null; // 상세 정보 없음
    }
  }
  
  /// 외국어 시험 상세 정보 생성
  Map<String, dynamic> _buildLanguageExamDetails() {
    final details = <String, dynamic>{
      'examType': _languageExamType,
    };
    
    if (_languageScoreController.text.isEmpty) {
      return details;
    }
    
    final score = _languageScoreController.text.trim();
    
    if (_languageExamType == '한국사') {
      details['grade'] = score;
    } else if (_languageExamType == 'TOEIC' || 
               _languageExamType == 'TOEFL' || 
               _languageExamType == 'TEPS') {
      final intScore = int.tryParse(score);
      if (intScore != null) {
        details['score'] = intScore;
      } else {
        details['score'] = score;
      }
    } else if (_languageExamType == 'IELTS') {
      final doubleScore = double.tryParse(score);
      if (doubleScore != null) {
        details['score'] = doubleScore;
      } else {
        details['score'] = score;
      }
    } else {
      details['score'] = score;
      details['grade'] = score;
    }
    
    return details;
  }
  
  /// 예상 XP 계산
  int? _calculateExpectedXp() {
    if (_selectedCertificationType == null) return null;
    
    final details = _buildCertificationDetails();
    if (details == null && 
        _selectedCertificationType != CertificationType.exhibition &&
        _selectedCertificationType != CertificationType.otherActivity) {
      return null;
    }
    
    switch (_selectedCertificationType!) {
      case CertificationType.license:
        if (_licenseType == 'national') {
          return XpRule.getNationalLicenseXp(
            _licenseCategory ?? '',
            _licenseGrade ?? '',
          );
        } else if (_licenseType == 'national_professional') {
          return XpRule.getNationalProfessionalLicenseXp(_licenseGrade ?? '');
        } else if (_licenseType == 'private') {
          return XpRule.getPrivateLicenseXp(
            _privateLicenseType ?? '',
            _licenseGrade ?? '',
          );
        }
        return null;
        
      case CertificationType.publicServiceExam:
        return XpRule.getPublicServiceExamXp(_publicServiceExamType ?? '');
        
      case CertificationType.languageExam:
        if (_languageExamType == '한국사') {
          return XpRule.getKoreanHistoryExamXp(_languageScoreController.text.trim());
        } else if (_languageExamType == 'TOEIC' || 
                   _languageExamType == 'TOEIC_Speaking' ||
                   _languageExamType == 'TOEFL' || 
                   _languageExamType == 'OPIC' ||
                   _languageExamType == 'TEPS' || 
                   _languageExamType == 'IELTS') {
          final score = _languageScoreController.text.trim();
          if (score.isEmpty) return null;
          return XpRule.getEnglishExamXp(_languageExamType!, score);
        } else {
          final score = _languageScoreController.text.trim();
          if (score.isEmpty) return null;
          return XpRule.getOtherLanguageExamXp(
            _languageExamType ?? '',
            score,
          );
        }
        
      case CertificationType.contest:
        return XpRule.getContestXp(_contestScale ?? '', _contestResult ?? '');
        
      case CertificationType.exhibition:
        return XpRule.exhibitionParticipationXp;
        
      case CertificationType.otherActivity:
        return XpRule.otherActivityXp;
    }
  }
  
  /// 인증 유형별 상세 정보 입력 필드 생성
  List<Widget> _buildDetailFields() {
    switch (_selectedCertificationType!) {
      case CertificationType.license:
        return _buildLicenseFields();
      case CertificationType.publicServiceExam:
        return _buildPublicServiceExamFields();
      case CertificationType.languageExam:
        return _buildLanguageExamFields();
      case CertificationType.contest:
        return _buildContestFields();
      case CertificationType.exhibition:
      case CertificationType.otherActivity:
        return []; // 상세 정보 없음
    }
  }
  
  /// 자격증 필드
  List<Widget> _buildLicenseFields() {
    return [
      const Text(
        '자격증 종류',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: _licenseType,
        decoration: InputDecoration(
          hintText: '자격증 종류를 선택하세요',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        items: const [
          DropdownMenuItem(value: 'national', child: Text('국가자격증')),
          DropdownMenuItem(value: 'national_professional', child: Text('국가전문자격')),
          DropdownMenuItem(value: 'private', child: Text('민간자격증')),
        ],
        validator: (value) {
          if (value == null) {
            return '자격증 종류를 선택해주세요';
          }
          return null;
        },
                      onChanged: (value) {
                        setState(() {
                          _licenseType = value;
                          _licenseCategory = null;
                          _licenseGrade = null;
                          _privateLicenseType = null;
                        });
                        // 폼 검증을 위해 상태 업데이트
                        _formKey.currentState?.validate();
                      },
      ),
      if (_licenseType == 'national') ...[
        const SizedBox(height: 25),
        const Text(
          '분야',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _licenseCategory,
          decoration: InputDecoration(
            hintText: '분야를 선택하세요',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'technical', child: Text('기술·기능 분야')),
            DropdownMenuItem(value: 'service', child: Text('서비스 분야')),
          ],
          validator: (value) {
            if (value == null) {
              return '분야를 선택해주세요';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              _licenseCategory = value;
            });
            _formKey.currentState?.validate();
          },
        ),
        const SizedBox(height: 25),
        const Text(
          '등급',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _licenseGrade,
          decoration: InputDecoration(
            hintText: _licenseCategory == 'technical' 
                ? '기술사, 기능장, 기사, 산업기사, 기능사'
                : '1급, 2급, 3급',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          items: (_licenseCategory == 'technical'
              ? ['기술사', '기능장', '기사', '산업기사', '기능사']
              : ['1급', '2급', '3급']
          ).map((grade) => DropdownMenuItem(
            value: grade,
            child: Text(grade),
          )).toList(),
          validator: (value) {
            if (value == null) {
              return '등급을 선택해주세요';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              _licenseGrade = value;
            });
            _formKey.currentState?.validate();
          },
        ),
      ] else if (_licenseType == 'national_professional') ...[
        const SizedBox(height: 25),
        const Text(
          '등급',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _licenseGrade,
          decoration: InputDecoration(
            hintText: '등급을 선택하세요',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          items: const [
            DropdownMenuItem(value: '1급', child: Text('1급')),
            DropdownMenuItem(value: '단일등급', child: Text('단일등급')),
            DropdownMenuItem(value: '2급', child: Text('2급')),
            DropdownMenuItem(value: '3급', child: Text('3급')),
          ],
          validator: (value) {
            if (value == null) {
              return '등급을 선택해주세요';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              _licenseGrade = value;
            });
            _formKey.currentState?.validate();
          },
        ),
      ] else if (_licenseType == 'private') ...[
        const SizedBox(height: 25),
        const Text(
          '민간자격 유형',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _privateLicenseType,
          decoration: InputDecoration(
            hintText: '민간자격 유형을 선택하세요',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'national_approved', child: Text('국가공인')),
            DropdownMenuItem(value: 'registered', child: Text('등록민간자격')),
          ],
          validator: (value) {
            if (value == null) {
              return '민간자격 유형을 선택해주세요';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              _privateLicenseType = value;
            });
            _formKey.currentState?.validate();
          },
        ),
        const SizedBox(height: 25),
        const Text(
          '등급',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _licenseGrade,
          decoration: InputDecoration(
            hintText: '등급을 선택하세요',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          items: const [
            DropdownMenuItem(value: '1급', child: Text('1급')),
            DropdownMenuItem(value: '단일등급', child: Text('단일등급')),
            DropdownMenuItem(value: '2급', child: Text('2급')),
            DropdownMenuItem(value: '3급', child: Text('3급')),
          ],
          validator: (value) {
            if (value == null) {
              return '등급을 선택해주세요';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              _licenseGrade = value;
            });
            _formKey.currentState?.validate();
          },
        ),
      ],
    ];
  }
  
  /// 공무원 시험 필드
  List<Widget> _buildPublicServiceExamFields() {
    return [
      const Text(
        '시험 종류',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: _publicServiceExamType,
        decoration: InputDecoration(
          hintText: '시험 종류를 선택하세요',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        items: const [
          DropdownMenuItem(value: '7급', child: Text('7급 공무원')),
          DropdownMenuItem(value: '9급', child: Text('9급 공무원')),
          DropdownMenuItem(value: '소방', child: Text('소방 공무원')),
          DropdownMenuItem(value: '경찰', child: Text('경찰 공무원')),
        ],
        validator: (value) {
          if (value == null) {
            return '시험 종류를 선택해주세요';
          }
          return null;
        },
        onChanged: (value) {
          setState(() {
            _publicServiceExamType = value;
          });
          _formKey.currentState?.validate();
        },
      ),
    ];
  }
  
  /// 외국어 시험 필드
  List<Widget> _buildLanguageExamFields() {
    return [
      const Text(
        '시험 종류',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: _languageExamType,
        decoration: InputDecoration(
          hintText: '시험 종류를 선택하세요',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        items: const [
          DropdownMenuItem(value: '한국사', child: Text('한국사능력검정시험')),
          DropdownMenuItem(value: 'TOEIC', child: Text('TOEIC')),
          DropdownMenuItem(value: 'TOEIC_Speaking', child: Text('TOEIC Speaking')),
          DropdownMenuItem(value: 'TOEFL', child: Text('TOEFL')),
          DropdownMenuItem(value: 'OPIC', child: Text('OPIC')),
          DropdownMenuItem(value: 'TEPS', child: Text('TEPS')),
          DropdownMenuItem(value: 'IELTS', child: Text('IELTS')),
          DropdownMenuItem(value: 'G-TELP', child: Text('G-TELP')),
          DropdownMenuItem(value: 'HSK', child: Text('HSK')),
          DropdownMenuItem(value: 'JPT', child: Text('JPT')),
          DropdownMenuItem(value: 'JPTT', child: Text('JPTT')),
          DropdownMenuItem(value: 'DALF/DELF', child: Text('DALF/DELF')),
          DropdownMenuItem(value: 'DELE', child: Text('DELE')),
          DropdownMenuItem(value: 'ZD', child: Text('ZD')),
        ],
        validator: (value) {
          if (value == null) {
            return '시험 종류를 선택해주세요';
          }
          return null;
        },
        onChanged: (value) {
          setState(() {
            _languageExamType = value;
            _languageScoreController.clear();
          });
          _formKey.currentState?.validate();
        },
      ),
      const SizedBox(height: 25),
      Text(
        _languageExamType == '한국사' 
            ? '등급'
            : _languageExamType == 'IELTS'
                ? '점수'
                : '점수/등급',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: _languageScoreController,
        decoration: InputDecoration(
          hintText: _languageExamType == 'TOEIC' 
              ? '예: 850'
              : _languageExamType == 'TOEIC_Speaking'
                  ? '예: AH, AM, AL'
                  : _languageExamType == 'OPIC'
                      ? '예: AL, IH, IM3'
                      : _languageExamType == '한국사'
                          ? '예: 1급, 2급, 3급'
                          : _languageExamType == 'IELTS'
                              ? '예: 6.5'
                              : '점수 또는 등급 입력',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        keyboardType: _languageExamType == 'IELTS' 
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        validator: (value) {
          if (_languageExamType == 'TOEIC' ||
              _languageExamType == 'TOEIC_Speaking' ||
              _languageExamType == 'TOEFL' ||
              _languageExamType == 'OPIC' ||
              _languageExamType == 'TEPS' ||
              _languageExamType == 'IELTS') {
            if (value == null || value.trim().isEmpty) {
              return '점수를 입력해주세요';
            }
          } else if (_languageExamType == '한국사') {
            if (value == null || value.trim().isEmpty) {
              return '등급을 입력해주세요';
            }
          } else {
            if (value == null || value.trim().isEmpty) {
              return '점수/등급을 입력해주세요';
            }
          }
          return null;
        },
        onChanged: (_) {
          setState(() {}); // XP 재계산을 위해
          _formKey.currentState?.validate();
        },
      ),
    ];
  }
  
  /// 공모전 필드
  List<Widget> _buildContestFields() {
    return [
      const Text(
        '규모',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: _contestScale,
        decoration: InputDecoration(
          hintText: '규모를 선택하세요',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        items: const [
          DropdownMenuItem(value: 'international', child: Text('국제')),
          DropdownMenuItem(value: 'national', child: Text('전국')),
          DropdownMenuItem(value: 'local', child: Text('시·도')),
        ],
        validator: (value) {
          if (value == null) {
            return '규모를 선택해주세요';
          }
          return null;
        },
        onChanged: (value) {
          setState(() {
            _contestScale = value;
          });
          _formKey.currentState?.validate();
        },
      ),
      const SizedBox(height: 25),
      const Text(
        '결과',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: _contestResult,
        decoration: InputDecoration(
          hintText: '결과를 선택하세요',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        items: const [
          DropdownMenuItem(value: '대상', child: Text('대상')),
          DropdownMenuItem(value: '입상', child: Text('입상')),
          DropdownMenuItem(value: '입선', child: Text('입선')),
          DropdownMenuItem(value: '참가', child: Text('참가')),
        ],
        validator: (value) {
          if (value == null) {
            return '결과를 선택해주세요';
          }
          return null;
        },
        onChanged: (value) {
          setState(() {
            _contestResult = value;
          });
          _formKey.currentState?.validate();
        },
      ),
    ];
  }

  /// 모든 필수 필드가 입력되었는지 확인
  bool _isFormValid() {
    // 인증 이름 확인
    if (_certificationNameController.text.trim().isEmpty) {
      return false;
    }

    // 인증 유형 확인
    if (_selectedCertificationType == null) {
      return false;
    }

    // 인증 유형별 필수 필드 확인
    switch (_selectedCertificationType!) {
      case CertificationType.license:
        if (_licenseType == null) return false;
        if (_licenseType == 'national') {
          if (_licenseCategory == null || _licenseGrade == null) return false;
        } else if (_licenseType == 'national_professional') {
          if (_licenseGrade == null) return false;
        } else if (_licenseType == 'private') {
          if (_privateLicenseType == null || _licenseGrade == null) return false;
        }
        break;

      case CertificationType.publicServiceExam:
        if (_publicServiceExamType == null) return false;
        break;

      case CertificationType.languageExam:
        if (_languageExamType == null) return false;
        // 일부 시험은 점수가 필수
        if (_languageExamType == 'TOEIC' ||
            _languageExamType == 'TOEIC_Speaking' ||
            _languageExamType == 'TOEFL' ||
            _languageExamType == 'OPIC' ||
            _languageExamType == 'TEPS' ||
            _languageExamType == 'IELTS') {
          if (_languageScoreController.text.trim().isEmpty) return false;
        }
        break;

      case CertificationType.contest:
        if (_contestScale == null || _contestResult == null) return false;
        break;

      case CertificationType.exhibition:
      case CertificationType.otherActivity:
        // 상세 정보 없음
        break;
    }

    return true;
  }

  /// 고유한 인증 ID 생성
  String _generateChallengeId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return '${widget.userId}_$timestamp$random';
  }

  Future<String?> _uploadImage() async {
    try {
      // 이미지 파일이 null인 경우 (수정 모드에서 이미지 변경 없음)
      if (widget.imageFile == null) {
        return null;
      }

      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      if (currentUser == null) {
        throw Exception('로그인이 필요합니다. Storage 업로드를 위해 인증이 필요합니다.');
      }

      if (!await widget.imageFile!.exists()) {
        throw Exception('이미지 파일을 찾을 수 없습니다.');
      }

      final fileSize = await widget.imageFile!.length();
      const maxSize = 10 * 1024 * 1024;
      if (fileSize > maxSize) {
        throw Exception('이미지 크기가 너무 큽니다. (최대 10MB)');
      }

      final storage = FirebaseStorage.instance;
      final fileName = '${widget.userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'challenge_proofs/$fileName';
      final storageRef = storage.ref().child(storagePath);

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': widget.userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = storageRef.putFile(
        widget.imageFile!,
        metadata,
      );
      
      final snapshot = await uploadTask;
      
      if (snapshot.state == TaskState.success) {
        final downloadUrl = await storageRef.getDownloadURL();
        return downloadUrl;
      } else {
        throw Exception('업로드가 완료되지 않았습니다. 상태: ${snapshot.state}');
      }
    } on FirebaseException catch (e) {
      String errorMessage = '이미지 업로드 실패: ';
      String detailedMessage = '';
      
      if (e.code == 'unauthorized' || e.code == 'permission-denied') {
        errorMessage += '권한이 없습니다.';
        detailedMessage = 'Storage 규칙을 확인해주세요. challenge_proofs 경로에 대한 쓰기 권한이 필요합니다.';
      } else if (e.code == 'object-not-found') {
        errorMessage += 'Storage 버킷을 찾을 수 없습니다.';
        detailedMessage = 'Firebase Console에서 Storage가 활성화되어 있는지 확인해주세요.';
      } else if (e.code == 'canceled') {
        errorMessage += '업로드가 취소되었습니다.';
      } else if (e.code == 'unknown') {
        errorMessage += '알 수 없는 오류가 발생했습니다.';
      } else {
        errorMessage += '${e.code}';
        detailedMessage = e.message ?? '알 수 없는 오류';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(errorMessage),
                if (detailedMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      detailedMessage,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            duration: const Duration(seconds: 7),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    } catch (e, stackTrace) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 업로드 실패: $e'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// 필수 항목이 모두 입력되었는지 확인
  String? _validateRequiredFields() {
    // 인증 이름 확인
    if (_certificationNameController.text.trim().isEmpty) {
      return '인증 이름을 입력해주세요';
    }

    // 인증 유형 선택 확인
    if (_selectedCertificationType == null) {
      return '인증 유형을 선택해주세요';
    }

    // 인증 유형별 필수 필드 확인
    switch (_selectedCertificationType!) {
      case CertificationType.license:
        if (_licenseType == null) {
          return '자격증 종류를 선택해주세요';
        }
        if (_licenseType == 'national') {
          if (_licenseCategory == null) {
            return '분야를 선택해주세요';
          }
          if (_licenseGrade == null) {
            return '등급을 선택해주세요';
          }
        } else if (_licenseType == 'national_professional') {
          if (_licenseGrade == null) {
            return '등급을 선택해주세요';
          }
        } else if (_licenseType == 'private') {
          if (_privateLicenseType == null) {
            return '민간자격 유형을 선택해주세요';
          }
          if (_licenseGrade == null) {
            return '등급을 선택해주세요';
          }
        }
        break;

      case CertificationType.publicServiceExam:
        if (_publicServiceExamType == null) {
          return '시험 종류를 선택해주세요';
        }
        break;

      case CertificationType.languageExam:
        if (_languageExamType == null) {
          return '시험 종류를 선택해주세요';
        }
        // 일부 시험은 점수가 필수
        if (_languageExamType == 'TOEIC' ||
            _languageExamType == 'TOEIC_Speaking' ||
            _languageExamType == 'TOEFL' ||
            _languageExamType == 'OPIC' ||
            _languageExamType == 'TEPS' ||
            _languageExamType == 'IELTS') {
          if (_languageScoreController.text.trim().isEmpty) {
            return '점수를 입력해주세요';
          }
        }
        break;

      case CertificationType.contest:
        if (_contestScale == null) {
          return '공모전 규모를 선택해주세요';
        }
        if (_contestResult == null) {
          return '수상 결과를 선택해주세요';
        }
        break;

      case CertificationType.exhibition:
      case CertificationType.otherActivity:
        // 상세 정보 없음
        break;
    }

    return null; // 모든 필수 항목 입력됨
  }

  Future<void> _submitProof() async {
    // 폼 검증
    if (!_formKey.currentState!.validate()) return;

    // 필수 항목 검증
    final validationError = _validateRequiredFields();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl;
      
      if (_isEditMode) {
        // 수정 모드: 이미지가 새로 업로드된 경우에만 업로드, 아니면 기존 URL 사용
        if (widget.imageFile != null) {
          imageUrl = await _uploadImage();
          if (imageUrl == null) {
            setState(() {
              _isLoading = false;
            });
            return;
          }
        } else {
          // 기존 이미지 URL 사용
          imageUrl = widget.existingCertification?.imageUrl;
        }
      } else {
        // 생성 모드: 이미지 업로드 필수
        imageUrl = await _uploadImage();
        if (imageUrl == null) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      final now = DateTime.now();
      
      if (_isEditMode) {
        // 수정 모드
        final existingCert = widget.existingCertification!;
        final certification = Certification(
          id: widget.certificationId!,
          challengeId: existingCert.challengeId,
          userId: widget.userId,
          imageUrl: imageUrl,
          description: _certificationNameController.text.trim(),
          proofDate: existingCert.proofDate, // 기존 날짜 유지
          createdAt: existingCert.createdAt, // 기존 생성일 유지
          isApproved: false,
          reviewStatus: ReviewStatus.pending, // 수정 시 다시 검토 중으로
          xpEarned: 0,
          certificationType: _selectedCertificationType,
          certificationDetails: _buildCertificationDetails(),
        );

        await _proofService.updateCertification(widget.certificationId!, certification);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('인증이 수정되었습니다. 다시 검토 후 경험치가 지급됩니다.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // 생성 모드
        final challengeId = _generateChallengeId();
        
        final certification = Certification(
          id: '',
          challengeId: challengeId,
          userId: widget.userId,
          imageUrl: imageUrl,
          description: _certificationNameController.text.trim(),
          proofDate: now,
          createdAt: now,
          isApproved: false,
          reviewStatus: ReviewStatus.pending,
          xpEarned: 0,
          certificationType: _selectedCertificationType,
          certificationDetails: _buildCertificationDetails(),
        );

        await _proofService.createCertification(certification);

        if (mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('인증이 제출되었습니다. 검토 후 경험치가 지급됩니다.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? '인증 정보 수정' : '인증 정보 입력',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 입력 필드 영역 (스크롤 가능)
          Padding(
            padding: const EdgeInsets.only(bottom: 100), // 버튼 공간 확보
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 사진 미리보기
                    if (widget.imageFile != null)
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            widget.imageFile!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      )
                    else if (_isEditMode && widget.existingCertification?.imageUrl != null)
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            widget.existingCertification!.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.broken_image, size: 48),
                              );
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 25),
                    // 자격증 이름 입력
                    const Text(
                      '인증 이름',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _certificationNameController,
                      decoration: InputDecoration(
                        hintText: '예: 정보처리기사, 토익 등',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '인증 이름을 입력해주세요';
                        }
                        return null;
                      },
                      onChanged: (_) {
                        setState(() {}); // 폼 상태 업데이트
                        _formKey.currentState?.validate();
                      },
                    ),
                    const SizedBox(height: 25),
                    // 인증 유형 선택
                    const Text(
                      '인증 유형',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<CertificationType>(
                      value: _selectedCertificationType,
                      decoration: InputDecoration(
                        hintText: '인증 유형을 선택하세요',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: CertificationType.values.map((type) {
                        String label;
                        switch (type) {
                          case CertificationType.license:
                            label = '자격증';
                            break;
                          case CertificationType.publicServiceExam:
                            label = '공무원 시험';
                            break;
                          case CertificationType.languageExam:
                            label = '외국어 시험';
                            break;
                          case CertificationType.contest:
                            label = '공모전·대회';
                            break;
                          case CertificationType.exhibition:
                            label = '전시회·공연';
                            break;
                          case CertificationType.otherActivity:
                            label = '기타 활동';
                            break;
                        }
                        return DropdownMenuItem(
                          value: type,
                          child: Text(label),
                        );
                      }).toList(),
                      validator: (value) {
                        if (value == null) {
                          return '인증 유형을 선택해주세요';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _selectedCertificationType = value;
                          // 관련 필드 초기화
                          _licenseType = null;
                          _licenseCategory = null;
                          _licenseGrade = null;
                          _privateLicenseType = null;
                          _publicServiceExamType = null;
                          _languageExamType = null;
                          _languageScoreController.clear();
                          _contestScale = null;
                          _contestResult = null;
                        });
                        _formKey.currentState?.validate();
                      },
                    ),
                    // 인증 유형별 상세 정보 입력 필드
                    if (_selectedCertificationType != null) ...[
                      const SizedBox(height: 25),
                      ..._buildDetailFields(),
                    ],
                    // 예상 XP 표시
                    if (_selectedCertificationType != null && _calculateExpectedXp() != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              '예상 획득 XP: ${_calculateExpectedXp()}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // 버튼 영역 (하단 고정)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: (_isLoading || !_isFormValid()) ? null : _submitProof,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        '인증 제출',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

