import 'package:uuid/uuid.dart';

class Fridge {
  final String id;
  final String name;
  final String type;
  final String location;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final String creatorId;
  final List<Map<String, String>> members;

  Fridge({
    String? id,
    required this.name,
    required this.type,
    required this.location,
    DateTime? createdAt,
    DateTime? lastUpdated,
    required this.creatorId,
    List<Map<String, String>>? members,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        lastUpdated = lastUpdated ?? DateTime.now(),
        members = members ??
            [
              {'nickname': '생성자', 'tag': '0001', 'deviceId': creatorId},
            ];

  Fridge copyWith({
    String? id,
    String? name,
    String? type,
    String? location,
    DateTime? createdAt,
    DateTime? lastUpdated,
    String? creatorId,
    List<Map<String, String>>? members,
  }) {
    return Fridge(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      creatorId: creatorId ?? this.creatorId,
      members: members ?? this.members,
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
      'creatorId': creatorId,
      'members': members.map((m) => memberToJson(m)).toList(),
    };
  }

  factory Fridge.fromJson(Map<String, dynamic> json) {
    return Fridge(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      location: json['location'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
      creatorId: json['creatorId'] ?? '',
      members: (json['members'] as List<dynamic>?)
              ?.map((e) => memberFromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  // 멤버를 Firestore 서브컬렉션용으로 변환
  static Map<String, dynamic> memberToJson(Map<String, String> member) {
    return {
      'nickname': member['nickname'] ?? '',
      'tag': member['tag'] ?? '',
      'uid': member['uid'] ?? '',
    };
  }

  static Map<String, String> memberFromJson(Map<String, dynamic> json) {
    return {
      'nickname': json['nickname'] ?? '',
      'tag': json['tag'] ?? '',
      'uid': json['uid'] ?? '',
    };
  }
}
