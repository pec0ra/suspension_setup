// v1 structure: { setupId: { id, name, fork: { airPressure: int?, ... }, shock: ..., history } }
// v2 structure: { schemaVersion: 2, setups: { setupId: { ..., fork: { airPressure: {value, unit}?, ... } } } }

const _defaultUnits = {
  'airPressure': 'PSI',
  'sag': '%',
  'volumeSpacer': 'Spacers',
  'lsc': 'Clicks',
  'hsc': 'Clicks',
  'lsr': 'Clicks',
  'hsr': 'Clicks',
};

Map<String, dynamic> migrateV1ToV2(Map<String, dynamic> v1Data) {
  final migratedSetups = v1Data.map(
    (id, value) => MapEntry(id, _migrateSetup(value as Map<String, dynamic>)),
  );
  return {'schemaVersion': 2, 'setups': migratedSetups};
}

Map<String, dynamic> _migrateSetup(Map<String, dynamic> setup) {
  return {
    ...setup,
    'fork': _migrateSettings(setup['fork'] as Map<String, dynamic>),
    'shock': _migrateSettings(setup['shock'] as Map<String, dynamic>),
  };
}

Map<String, dynamic> _migrateSettings(Map<String, dynamic> settings) {
  return settings.map((key, rawValue) {
    if (rawValue == null) return MapEntry(key, null);
    final unit = _defaultUnits[key] ?? '';
    return MapEntry(key, {'value': rawValue, 'unit': unit});
  });
}
