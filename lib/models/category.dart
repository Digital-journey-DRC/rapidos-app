class Category {
  final int id;
  final String name;
  final String description;

  Category({required this.id, required this.name, required this.description});

  factory Category.fromJson(Map<String, dynamic> json) {
    // Helper function pour parser les valeurs de manière sécurisée
    int parseToInt(dynamic value, int fallback) {
      if (value == null) return fallback;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ?? fallback;
      }
      if (value is num) return value.toInt();
      return fallback;
    }

    return Category(
      id: parseToInt(json['id'], 0),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
} 