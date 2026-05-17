import 'package:uuid/uuid.dart';

class Field {
  final String id;
  final String name;
  final String unit;
  final num? value;
  final bool deleted;

  Field({
    String? id,
    required this.name,
    required this.unit,
    this.value,
    this.deleted = false,
  }) : id = id ?? const Uuid().v4();

  Field copyWith({
    String? name,
    String? unit,
    num? value,
    bool? deleted,
    bool clearValue = false,
  }) =>
      Field(
        id: id,
        name: name ?? this.name,
        unit: unit ?? this.unit,
        value: clearValue ? null : (value ?? this.value),
        deleted: deleted ?? this.deleted,
      );

  factory Field.fromJson(Map<String, dynamic> json) => Field(
        id: json['id'] as String,
        name: json['name'] as String,
        unit: json['unit'] as String,
        value: json['value'] as num?,
        deleted: json['deleted'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'unit': unit,
        'value': value,
        'deleted': deleted,
      };
}
