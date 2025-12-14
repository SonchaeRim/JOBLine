import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/schedule.dart';
import '../services/calendar_service.dart';
import '../services/fcm_notification_service.dart';
import '../../../core/theme/app_colors.dart';

/// 일정 상세/추가/수정 화면
class ScheduleDetailScreen extends StatefulWidget {
  final String userId;
  final CalendarService calendarService;
  final Schedule? schedule; // null이면 새 일정 추가
  final DateTime? selectedDate; // 새 일정 추가 시 초기 날짜

  const ScheduleDetailScreen({
    super.key,
    required this.userId,
    required this.calendarService,
    this.schedule,
    this.selectedDate,
  });

  @override
  State<ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends State<ScheduleDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notificationService = FcmNotificationService();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isDeadline = false;
  bool _hasNotification = false;
  String? _category;
  bool _isLoading = false;
  bool _isEditing = false; // 편집 모드 여부 (새 일정이면 true, 기존 일정이면 false)

  final List<String> _categories = [
    '면접',
    '시험',
    '서류제출',
    '프로젝트',
    '기타',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.schedule != null) {
      // 기존 일정: 읽기 모드로 시작
      _isEditing = false;
      _titleController = TextEditingController(text: widget.schedule!.title);
      _descriptionController =
          TextEditingController(text: widget.schedule!.description ?? '');
      
      // UTC로 저장된 시간을 로컬 시간으로 변환하여 표시
      final startDateLocal = widget.schedule!.startDate.toLocal();
      _selectedDate = startDateLocal;
      _selectedTime = TimeOfDay.fromDateTime(startDateLocal);
      
      _isDeadline = widget.schedule!.isDeadline;
      _hasNotification = widget.schedule!.hasNotification;
      _category = widget.schedule!.category;
    } else {
      // 새 일정: 편집 모드로 시작
      _isEditing = true;
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _selectedDate = widget.selectedDate ?? DateTime.now();
      _selectedTime = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  /// 시간을 12시간 형식(AM/PM)으로 포맷팅
  String _formatTime(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 사용자가 선택한 로컬 시간을 UTC로 변환하여 저장
      final DateTime startLocal = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      // UTC로 변환
      final DateTime startUtc = startLocal.toUtc();

      final now = DateTime.now().toUtc();

      final schedule = Schedule(
        id: widget.schedule?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        startDate: startUtc, // UTC로 저장
        ownerId: widget.userId,
        createdAt: widget.schedule?.createdAt ?? now,
        updatedAt: now,
        isDeadline: _isDeadline,
        category: _category,
        hasNotification: _hasNotification,
      );


      String scheduleId;
      if (widget.schedule != null) {
        // 수정
        scheduleId = widget.schedule!.id;
        await widget.calendarService.updateSchedule(
          scheduleId,
          schedule,
        );
        
        // 일정이 변경되면 무조건 기존 알림 삭제 후 재예약
        final oldHasNotification = widget.schedule!.hasNotification;
        
        // 기존 알림이 있었으면 무조건 삭제
        if (oldHasNotification) {
          await _notificationService.cancelScheduleNotification(scheduleId);
        }
        
        // 알림 상태 변경 처리
        if (_hasNotification) {
          // 알림 켜기 또는 재예약
          final scheduleWithId = schedule.copyWith(id: scheduleId);
          await _notificationService.scheduleScheduleNotification(scheduleWithId);
        }
      } else {
        // 추가
        scheduleId = await widget.calendarService.createSchedule(schedule);
        
        // 알림이 켜져있으면 알림 예약
        if (_hasNotification) {
          final scheduleWithId = schedule.copyWith(id: scheduleId);
          await _notificationService.scheduleScheduleNotification(scheduleWithId);
        }
      }

      if (mounted) {
        if (widget.schedule == null) {
          // 새 일정 추가: 화면 닫기
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('일정이 추가되었습니다.')),
          );
        } else {
          // 기존 일정 수정: 읽기 모드로 전환
          setState(() {
            _isEditing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('일정이 수정되었습니다.')),
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

  Future<void> _toggleNotification() async {
    if (widget.schedule == null || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final scheduleId = widget.schedule!.id;
      final newNotificationState = !_hasNotification;

      // 기존 알림 삭제
      if (_hasNotification) {
        await _notificationService.cancelScheduleNotification(scheduleId);
      }

      // 일정 업데이트
      final updatedSchedule = widget.schedule!.copyWith(
        hasNotification: newNotificationState,
        updatedAt: DateTime.now().toUtc(),
      );
      await widget.calendarService.updateSchedule(scheduleId, updatedSchedule);

      // 알림 켜기
      if (newNotificationState) {
        await _notificationService.scheduleScheduleNotification(updatedSchedule);
      }

      if (mounted) {
        setState(() {
          _hasNotification = newNotificationState;
          // widget.schedule도 업데이트된 값으로 갱신
          if (widget.schedule != null) {
            // widget.schedule은 final이므로 직접 수정할 수 없지만,
            // _hasNotification 상태 변수로 UI는 업데이트됨
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newNotificationState ? '알림이 켜졌습니다.' : '알림이 꺼졌습니다.'),
          ),
        );
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

  Future<void> _deleteSchedule() async {
    if (widget.schedule == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일정 삭제'),
        content: const Text('정말 이 일정을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final scheduleId = widget.schedule!.id;
        
        // 일정 삭제 전 해당 일정의 모든 알림 요청과 작업 삭제
        await _notificationService.deleteScheduleNotifications(scheduleId);
        
        await widget.calendarService.deleteSchedule(scheduleId);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('일정이 삭제되었습니다.')),
          );
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing 
            ? (widget.schedule == null ? '새 일정' : '일정 수정')
            : '일정 상세'),
        actions: _isEditing
            ? widget.schedule != null
                ? [
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: _isLoading ? null : _deleteSchedule,
                    ),
                  ]
                : null
            : [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  tooltip: '수정',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _isLoading ? null : _deleteSchedule,
                ),
              ],
      ),
      body: _isEditing ? _buildEditForm() : _buildDetailView(),
    );
  }

  /// 읽기 모드: 일정 상세 정보 표시
  Widget _buildDetailView() {
    // 상태 변수들을 사용하여 최신 정보 표시
    final title = _titleController.text;
    final description = _descriptionController.text;
    final startDate = _selectedDate;
    
    // 시간 포맷팅 (한글 오전/오후 형식)
    final hour = _selectedTime.hour;
    final minute = _selectedTime.minute;
    final period = hour >= 12 ? '오후' : '오전';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final timeText = '$period ${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 제목
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '제목',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 날짜 및 시간
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '날짜 및 시간',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 20, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('yyyy년 M월 d일', 'ko_KR').format(
                          widget.schedule != null 
                            ? widget.schedule!.startDate.toLocal() 
                            : _selectedDate
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 20, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        timeText,
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 설명
          if (description.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '설명',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (description.isNotEmpty)
            const SizedBox(height: 16),
          // 카테고리
          if (_category != null && _category!.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '카테고리',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _category!,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_category != null && _category!.isNotEmpty)
            const SizedBox(height: 16),
          // 알림 설정
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  InkWell(
                    onTap: _isLoading ? null : _toggleNotification,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        _hasNotification ? Icons.notifications : Icons.notifications_off,
                        color: _hasNotification ? Colors.blue : Colors.grey,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hasNotification ? '알림 켜짐' : '알림 꺼짐',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_hasNotification)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              '알림이 다음 시간에 발송됩니다:\n'
                              '• 일정 동일 시간 하루 전\n'
                              '• 일정 1시간 전\n'
                              '• 일정 5분 전',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 편집 모드: 일정 편집 폼
  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 제목
            const Text(
              '제목 *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: '제목을 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '제목을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 25),
            // 날짜 선택
            const Text(
              '날짜 *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  hintText: '날짜를 선택하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('yyyy년 M월 d일', 'ko_KR').format(_selectedDate),
                ),
              ),
            ),
            const SizedBox(height: 25),
            // 시간 선택
            const Text(
              '시간 *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectTime,
              child: InputDecorator(
                decoration: InputDecoration(
                  hintText: '시간을 선택하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: const Icon(Icons.access_time),
                ),
                child: Text(
                  _formatTime(_selectedTime),
                ),
              ),
            ),
            const SizedBox(height: 25),
            // 설명
            const Text(
              '설명',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: '설명을 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 25),
            // 카테고리
            const Text(
              '카테고리',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: InputDecoration(
                hintText: '카테고리를 선택하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('선택 안 함'),
                ),
                ..._categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _category = value;
                });
              },
            ),
            const SizedBox(height: 25),
            // 알림 설정
            CheckboxListTile(
              title: const Text('알림 받기'),
              subtitle: const Text(
                '알림이 다음 시간에 발송됩니다:\n'
                '• 일정 동일 시간 하루 전\n'
                '• 일정 1시간 전\n'
                '• 일정 5분 전',
                style: TextStyle(fontSize: 12),
              ),
              value: _hasNotification,
              onChanged: (value) {
                setState(() {
                  _hasNotification = value ?? false;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 32),
            // 저장 버튼
            ElevatedButton(
              onPressed: _isLoading ? null : _saveSchedule,
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
                      '저장',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            // 취소 버튼 (기존 일정 수정 시에만 표시)
            if (widget.schedule != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _isEditing = false;
                          // 원래 값으로 복원
                          _titleController.text = widget.schedule!.title;
                          _descriptionController.text =
                              widget.schedule!.description ?? '';
                          _selectedDate = widget.schedule!.startDate;
                          _selectedTime =
                              TimeOfDay.fromDateTime(widget.schedule!.startDate);
                          _isDeadline = widget.schedule!.isDeadline;
                          _hasNotification = widget.schedule!.hasNotification;
                          _category = widget.schedule!.category;
                        });
                      },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  '취소',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20), // 하단 여백
          ],
        ),
      ),
    );
  }
}

