import 'package:cloud_firestore/cloud_firestore.dart';

class Wish {
  final String id;
  final String name;
  final String reason;

  Wish({required this.id, required this.name, required this.reason});

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'reason': reason,
      };

  factory Wish.fromFirestore(Map<String, dynamic> firestore, String id) {
    return Wish(
      id: id,
      name: firestore['name'],
      reason: firestore['reason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'reason': reason,
      };

  factory Wish.fromJson(Map<String, dynamic> json) {
    return Wish(
      id: json['id'] ?? '', // Assuming id might not be in old JSON
      name: json['name'],
      reason: json['reason'] ?? '',
    );
  }
}
