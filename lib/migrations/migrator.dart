import 'v1_to_v2.dart';
import 'v2_to_v3.dart';
import 'v3_to_v4.dart';

const int currentSchemaVersion = 5;

Map<String, dynamic> migrateIfNeeded(Map<String, dynamic> json) {
  final version = json['schemaVersion'] as int? ?? 1;
  var data = json;
  if (version < 2) {
    final setupsOnly = Map<String, dynamic>.from(data)..remove('schemaVersion');
    data = migrateV1ToV2(setupsOnly);
  }
  if (version < 3) {
    data = migrateV2ToV3(data);
  }
  if (version < 4) {
    data = migrateV3ToV4(data);
  }
  // v4 → v5 needs no data transform.
  return data;
}
