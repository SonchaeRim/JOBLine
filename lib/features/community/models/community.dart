class Community {
  final String id;
  final String name;
  final String description;

  Community({
    required this.id,
    required this.name,
    required this.description,
  });

  factory Community.fromMap(String id, Map<String, dynamic> m) => Community(
    id: id,
    name: m['name'] ?? '',
    description: m['description'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
  };
}
