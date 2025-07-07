import 'package:cloud_firestore/cloud_firestore.dart';

class Ingredient {
  final String id;
  final String ingredientName;
  final StorageType storageType;
  double quantity;
  final DateTime? expirationDate;

  Ingredient({
    required this.id,
    required this.ingredientName,
    required this.storageType,
    this.expirationDate,
    this.quantity = 1.0,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'ingredientName': ingredientName,
      'quantity': quantity,
      'storageType': storageType.toString().split('.').last,
      'expirationDate':
          expirationDate != null ? Timestamp.fromDate(expirationDate!) : null,
    };
  }

  factory Ingredient.fromFirestore(Map<String, dynamic> firestore, String id) {
    DateTime? expirationDate;
    final exp = firestore['expirationDate'];
    if (exp is Timestamp) {
      expirationDate = exp.toDate();
    } else if (exp is String && exp.isNotEmpty) {
      expirationDate = DateTime.tryParse(exp);
    } else {
      expirationDate = null;
    }
    return Ingredient(
      id: id,
      ingredientName: firestore['ingredientName'],
      quantity: (firestore['quantity'] as num).toDouble(),
      storageType: StorageType.values.firstWhere(
        (e) => e.toString().split('.').last == firestore['storageType'],
        orElse: () => StorageType.refrigerated,
      ),
      expirationDate: expirationDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ingredientName': ingredientName,
      'quantity': quantity,
      'storageType': storageType.toString().split('.').last,
      'expirationDate': expirationDate?.toIso8601String(),
    };
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'],
      ingredientName: json['ingredientName'],
      quantity: (json['quantity'] as num).toDouble(),
      storageType: StorageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['storageType'],
        orElse: () => StorageType.refrigerated,
      ),
      expirationDate:
          json['expirationDate'] != null && json['expirationDate'] != ''
              ? DateTime.parse(json['expirationDate'])
              : null,
    );
  }

  Ingredient copyWith({
    String? id,
    String? ingredientName,
    StorageType? storageType,
    double? quantity,
    DateTime? expirationDate,
  }) {
    return Ingredient(
      id: id ?? this.id,
      ingredientName: ingredientName ?? this.ingredientName,
      storageType: storageType ?? this.storageType,
      quantity: quantity ?? this.quantity,
      expirationDate: expirationDate ?? this.expirationDate,
    );
  }
}

enum StorageType {
  refrigerated,
  frozen,
  roomTemperature,
}
