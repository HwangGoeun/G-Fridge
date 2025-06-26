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
}

enum StorageType {
  // Define StorageType enum
  refrigerated, // 냉장
  frozen, // 냉동
  roomTemperature, // 실온
}
