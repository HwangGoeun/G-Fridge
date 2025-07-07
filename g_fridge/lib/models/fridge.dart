import 'package:uuid/uuid.dart';

class Fridge {
  final String id;
  final String name;
  final String type;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final String creatorId;
  final List<Map<String, dynamic>>? inviteCodes;
  final List<String> sharedWith;

  Fridge({
    String? id,
    required this.name,
    required this.type,
    DateTime? createdAt,
    DateTime? lastUpdated,
    required this.creatorId,
    this.inviteCodes,
    List<String>? sharedWith,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        lastUpdated = lastUpdated ?? DateTime.now(),
        sharedWith = sharedWith ?? const [];

  Fridge copyWith({
    String? id,
    String? name,
    String? type,
    DateTime? createdAt,
    DateTime? lastUpdated,
    String? creatorId,
    List<Map<String, dynamic>>? inviteCodes,
    List<String>? sharedWith,
  }) {
    return Fridge(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      creatorId: creatorId ?? this.creatorId,
      inviteCodes: inviteCodes ?? this.inviteCodes,
      sharedWith: sharedWith ?? this.sharedWith,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'creatorId': creatorId,
      if (inviteCodes != null) 'inviteCodes': inviteCodes,
      'sharedWith': sharedWith,
    };
  }

  factory Fridge.fromJson(Map<String, dynamic> json) {
    return Fridge(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '개인용',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
      creatorId: json['creatorId']?.toString() ?? '',
      inviteCodes: (json['inviteCodes'] as List?)
          ?.where((e) => e != null && e is Map)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      sharedWith: (json['sharedWith'] as List?)
              ?.where((e) => e != null)
              .map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
