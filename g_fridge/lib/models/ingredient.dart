class Ingredient {
  final String name;
  final StorageType storageType; // Add storageType
  double quantity; // 수량 (0.5 단위)
  final DateTime? expirationDate; // 유통기한을 nullable로 변경

  Ingredient({
    required this.name,
    required this.storageType, // Use storageType
    this.expirationDate, // required 제거
    this.quantity = 1.0, // 기본값 1.0
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'storageType': storageType.name,
        'quantity': quantity,
        'expirationDate': expirationDate?.toIso8601String(),
      };

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'],
      storageType: StorageType.values.byName(json['storageType']),
      quantity: json['quantity'],
      expirationDate: json['expirationDate'] != null
          ? DateTime.parse(json['expirationDate'])
          : null,
    );
  }
}

enum StorageType {
  // Define StorageType enum
  refrigerated, // 냉장
  frozen, // 냉동
  roomTemperature, // 실온
}
