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

  Map<String, dynamic> toMap({bool forCreate = false}) {
    return {
      'name': name,
      'description': description,
      if (forCreate) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Community.fromMap(String id, Map<String, dynamic> m) =>
      Community.fromDoc(id, m);
}
