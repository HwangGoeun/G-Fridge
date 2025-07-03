import 'package:uuid/uuid.dart';

class Fridge {
  final String id;
  final String name;
  final String type;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final String creatorId;
  final List<Map<String, dynamic>>? inviteCodes;
  final int? order;
  final List<String> sharedWith;

  Fridge({
    String? id,
    required this.name,
    required this.type,
    DateTime? createdAt,
    DateTime? lastUpdated,
    required this.creatorId,
    this.inviteCodes,
    this.order,
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
    int? order,
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
      order: order ?? this.order,
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
      if (order != null) 'order': order,
      'sharedWith': sharedWith,
    };
  }

  factory Fridge.fromJson(Map<String, dynamic> json) {
    return Fridge(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
      creatorId: json['creatorId'] ?? '',
      inviteCodes: (json['inviteCodes'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList(),
      order: json['order'],
      sharedWith:
          (json['sharedWith'] as List?)?.map((e) => e.toString()).toList() ??
              [],
    );
  }
}
