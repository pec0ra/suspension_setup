import 'field.dart';

class SectionSettings {
  List<Field> fields;
  List<List<String>> layout;
  String? serialNumber;
  String? infoUrl;

  SectionSettings({
    required this.fields,
    required this.layout,
    this.serialNumber,
    this.infoUrl,
  });

  bool get hasAnyField =>
      fields.any((f) => !f.deleted) || serialNumber != null || infoUrl != null;

  Iterable<Field> get activeFields => fields.where((f) => !f.deleted);

  Field? fieldById(String id) {
    for (final f in fields) {
      if (f.id == id) return f;
    }
    return null;
  }

  factory SectionSettings.fromJson(Map<String, dynamic> json) =>
      SectionSettings(
        fields: (json['fields'] as List<dynamic>)
            .map((e) => Field.fromJson(e as Map<String, dynamic>))
            .toList(),
        layout: (json['layout'] as List<dynamic>)
            .map((row) => (row as List<dynamic>).cast<String>())
            .toList(),
        serialNumber: json['serialNumber'] as String?,
        infoUrl: json['infoUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'fields': fields.map((f) => f.toJson()).toList(),
        'layout': layout,
        'serialNumber': serialNumber,
        'infoUrl': infoUrl,
      };

  /// Default for fork / shock: Air Pressure, Sag, LSC, LSR (no values yet).
  static SectionSettings getDefaultForSuspension() {
    final airPressure = Field(name: 'Air Pressure', unit: 'PSI');
    final sag = Field(name: 'Sag', unit: '%');
    final lsc = Field(name: 'Low Speed Compression', unit: 'Clicks');
    final lsr = Field(name: 'Low Speed Rebound', unit: 'Clicks');
    return SectionSettings(
      fields: [airPressure, sag, lsc, lsr],
      layout: [
        [airPressure.id, sag.id],
        [lsc.id, lsr.id],
      ],
    );
  }

  /// Default for tyres: Front and Rear Tyre Pressure (no values yet).
  static SectionSettings getDefaultForTyres() {
    final front = Field(name: 'Front Tyre Pressure', unit: 'PSI');
    final rear = Field(name: 'Rear Tyre Pressure', unit: 'PSI');
    return SectionSettings(
      fields: [front, rear],
      layout: [
        [front.id, rear.id],
      ],
    );
  }

  SectionSettings clone() => SectionSettings(
        fields: List.from(fields),
        layout: layout.map((row) => List<String>.from(row)).toList(),
        serialNumber: serialNumber,
        infoUrl: infoUrl,
      );
}
