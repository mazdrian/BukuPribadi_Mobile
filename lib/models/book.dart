class Book {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String icon;
  final String color;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Book({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.icon,
    required this.color,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String,
      color: json['color'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Book copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? icon,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Book(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
