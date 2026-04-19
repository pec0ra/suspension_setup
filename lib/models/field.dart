class Field {
  final int value;
  final String unit;

  const Field({required this.value, required this.unit});

  factory Field.fromJson(Map<String, dynamic> json) {
    return Field(value: json['value'] as int, unit: json['unit'] as String);
  }

  Map<String, dynamic> toJson() => {'value': value, 'unit': unit};
}
