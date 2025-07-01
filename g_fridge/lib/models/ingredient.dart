class Ingredient {
  final String id;
  final String name;
  final StorageType storageType; // Add storageType
  double quantity; // 수량 (0.5 단위)
  final DateTime? expirationDate; // 유통기한을 nullable로 변경

  Ingredient({
    required this.id,
    required this.name,
    required this.storageType, // Use storageType
    this.expirationDate, // required 제거
    this.quantity = 1.0, // 기본값 1.0
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'storageType': storageType.toString().split('.').last,
      'expirationDate': expirationDate?.toIso8601String(),
    };
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'],
      name: json['name'],
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
    String? name,
    StorageType? storageType,
    double? quantity,
    DateTime? expirationDate,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      storageType: storageType ?? this.storageType,
      quantity: quantity ?? this.quantity,
      expirationDate: expirationDate ?? this.expirationDate,
    );
  }
}

enum StorageType {
  // Define StorageType enum
  refrigerated, // 냉장
  frozen, // 냉동
  roomTemperature, // 실온
}
