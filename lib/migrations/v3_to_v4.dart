import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Maps old settingType JSON key → display label.
const _labels = {
  'airPressure': 'Air Pressure',
  'sag': 'Sag',
  'volumeSpacer': 'Volume',
  'lsc': 'Low Speed Compression',
  'hsc': 'High Speed Compression',
  'lsr': 'Low Speed Rebound',
  'hsr': 'High Speed Rebound',
  'frontTyrePressure': 'Front Tyre Pressure',
  'rearTyrePressure': 'Rear Tyre Pressure',
};

const _defaultUnits = {
  'airPressure': 'PSI',
  'sag': '%',
  'volumeSpacer': 'Spacers',
  'lsc': 'Clicks',
  'hsc': 'Clicks',
  'lsr': 'Clicks',
  'hsr': 'Clicks',
  'frontTyrePressure': 'PSI',
  'rearTyrePressure': 'PSI',
};

/// Row groupings that mirror the old SettingTiles layout.
const _suspensionGroups = [
  ['airPressure', 'sag', 'volumeSpacer'],
  ['lsc', 'hsc'],
  ['lsr', 'hsr'],
];

Map<String, dynamic> migrateV3ToV4(Map<String, dynamic> v3Data) {
  final setups = Map<String, dynamic>.from(v3Data['setups'] as Map);
  final migratedSetups = setups.map(
    (id, value) => MapEntry(id, _migrateSetup(value as Map<String, dynamic>)),
  );
  return {'schemaVersion': 4, 'setups': migratedSetups};
}

Map<String, dynamic> _migrateSetup(Map<String, dynamic> setup) {
  // Assign a UUID per field per section (per-setup, not shared).
  final forkIds = _newSuspensionIds();
  final shockIds = _newSuspensionIds();
  final tyreIds = _newTyreIds();

  // Build (suspensionType, settingType) → fieldId lookup for history.
  final fieldIdMap = <(String, String), String>{};
  for (final key in forkIds.keys) {
    fieldIdMap[('fork', key)] = forkIds[key]!;
  }
  for (final key in shockIds.keys) {
    fieldIdMap[('shock', key)] = shockIds[key]!;
  }
  fieldIdMap[('tyre', 'frontTyrePressure')] = tyreIds['frontTyrePressure']!;
  fieldIdMap[('tyre', 'rearTyrePressure')] = tyreIds['rearTyrePressure']!;

  final forkJson = setup['fork'] as Map<String, dynamic>? ?? {};
  final shockJson = setup['shock'] as Map<String, dynamic>? ?? {};
  final tyresJson = setup['tyres'] as Map<String, dynamic>?;

  return {
    ...setup,
    'fork': _migrateSuspensionSection(forkJson, forkIds),
    'shock': _migrateSuspensionSection(shockJson, shockIds),
    'tyres': _migrateTyresSection(tyresJson, tyreIds),
    'history': _migrateHistory(
      setup['history'] as List<dynamic>? ?? [],
      fieldIdMap,
    ),
  };
}

Map<String, String> _newSuspensionIds() => {
      for (final key in [
        'airPressure',
        'sag',
        'volumeSpacer',
        'lsc',
        'hsc',
        'lsr',
        'hsr',
      ])
        key: _uuid.v4(),
    };

Map<String, String> _newTyreIds() => {
      'frontTyrePressure': _uuid.v4(),
      'rearTyrePressure': _uuid.v4(),
    };

Map<String, dynamic> _migrateSuspensionSection(
  Map<String, dynamic> oldSection,
  Map<String, String> ids,
) {
  final fields = <Map<String, dynamic>>[];
  for (final key in ids.keys) {
    final raw = oldSection[key] as Map<String, dynamic>?;
    fields.add({
      'id': ids[key]!,
      'name': _labels[key]!,
      'unit': raw?['unit'] as String? ?? _defaultUnits[key]!,
      'value': raw?['value'],
      'deleted': raw == null,
    });
  }

  final layout = <List<String>>[];
  for (final group in _suspensionGroups) {
    final row = group
        .where((key) => oldSection[key] != null)
        .map((key) => ids[key]!)
        .toList();
    if (row.isNotEmpty) layout.add(row);
  }

  return {
    'fields': fields,
    'layout': layout,
    'serialNumber': oldSection['serialNumber'],
    'infoUrl': oldSection['infoUrl'],
  };
}

Map<String, dynamic> _migrateTyresSection(
  Map<String, dynamic>? tyres,
  Map<String, String> ids,
) {
  final frontRaw = tyres?['front'] as Map<String, dynamic>?;
  final rearRaw = tyres?['rear'] as Map<String, dynamic>?;
  final frontId = ids['frontTyrePressure']!;
  final rearId = ids['rearTyrePressure']!;

  final fields = [
    {
      'id': frontId,
      'name': _labels['frontTyrePressure']!,
      'unit': frontRaw?['unit'] as String? ?? 'PSI',
      'value': frontRaw?['value'],
      'deleted': frontRaw == null,
    },
    {
      'id': rearId,
      'name': _labels['rearTyrePressure']!,
      'unit': rearRaw?['unit'] as String? ?? 'PSI',
      'value': rearRaw?['value'],
      'deleted': rearRaw == null,
    },
  ];

  final row = <String>[
    if (frontRaw != null) frontId,
    if (rearRaw != null) rearId,
  ];

  return {
    'fields': fields,
    'layout': row.isEmpty ? [] : [row],
    'serialNumber': null,
    'infoUrl': null,
  };
}

List<dynamic> _migrateHistory(
  List<dynamic> history,
  Map<(String, String), String> fieldIdMap,
) {
  return history.map((entry) {
    final entryMap = Map<String, dynamic>.from(entry as Map);
    final changes = (entryMap['changes'] as List<dynamic>).map((change) {
      final c = Map<String, dynamic>.from(change as Map);
      final suspensionType = c['suspensionType'] as String;
      final settingType = c['settingType'] as String?;
      if (settingType == null) return c; // already migrated
      final fieldId = fieldIdMap[(suspensionType, settingType)];
      if (fieldId == null) return c;
      return {
        'suspensionType': suspensionType,
        'fieldId': fieldId,
        'oldValue': c['oldValue'],
        'newValue': c['newValue'],
        'oldEnabled': c['oldEnabled'],
        'newEnabled': c['newEnabled'],
      };
    }).toList();
    return {...entryMap, 'changes': changes};
  }).toList();
}
