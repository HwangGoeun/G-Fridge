class Wish {
  final String name;
  final String reason;

  Wish({required this.name, required this.reason});

  Map<String, dynamic> toJson() => {
        'name': name,
        'reason': reason,
      };

  factory Wish.fromJson(Map<String, dynamic> json) {
    return Wish(
      name: json['name'],
      reason: json['reason'] ?? '',
    );
  }
}
