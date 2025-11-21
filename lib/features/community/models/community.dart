import 'package:cloud_firestore/cloud_firestore.dart';

class Community {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;

  Community({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
  });

  // 서비스에서 쓰는 팩토리 (id + Map)
  factory Community.fromDoc(String id, Map<String, dynamic>? m) {
    final data = m ?? const {};
    final raw = data['createdAt'];

    // Timestamp 또는 DateTime 모두 안전 처리
    final createdAt = raw is Timestamp
        ? raw.toDate()
        : (raw is DateTime ? raw : DateTime.now());

    return Community(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      createdAt: createdAt,
    );
  }

  // 처음 저장할 때 쓰는 직렬화
  Map<String, dynamic> toMap({bool forCreate = false}) {
    return {
      'name': name,
      'description': description,
      // 새로 만들 때는 서버 시간이 들어가도록
      if (forCreate) 'createdAt': FieldValue.serverTimestamp(),
      // 업데이트 시에는 createdAt을 건드리지 않는 편이 일반적
    };
  }

  // 있던 fromMap도 계속 쓰고 싶다면 이렇게 맞춰둘 수 있음
  factory Community.fromMap(String id, Map<String, dynamic> m) =>
      Community.fromDoc(id, m);
}
