import 'v1_to_v2.dart';
import 'v2_to_v3.dart';

const int currentSchemaVersion = 3;

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
  return data;
}
