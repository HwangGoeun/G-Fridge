import 'package:uuid/uuid.dart';

class Fridge {
  final String id;
  final String name;
  final String type;
  final String location;
  final DateTime createdAt;
  final DateTime lastUpdated;

  Fridge({
    String? id,
    required this.name,
    required this.type,
    required this.location,
    DateTime? createdAt,
    DateTime? lastUpdated,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        lastUpdated = lastUpdated ?? DateTime.now();

  Fridge copyWith({
    String? id,
    String? name,
    String? type,
    String? location,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return Fridge(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory Fridge.fromJson(Map<String, dynamic> json) {
    return Fridge(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      location: json['location'],
      createdAt: DateTime.parse(json['createdAt']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}
