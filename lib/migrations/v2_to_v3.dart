/// v2 structure: { schemaVersion: 2, setups: { setupId: { ..., history: [...] } } }
/// v3 structure: { schemaVersion: 3, setups: { setupId: { ..., history: [{ isCreationEntry: true, ... }, ...] } } }
Map<String, dynamic> migrateV2ToV3(Map<String, dynamic> v2Data) {
  final setups = Map<String, dynamic>.from(v2Data['setups'] as Map);
  final migratedSetups = setups.map(
    (id, value) => MapEntry(id, _migrateSetup(value as Map<String, dynamic>)),
  );
  return {'schemaVersion': 3, 'setups': migratedSetups};
}

Map<String, dynamic> _migrateSetup(Map<String, dynamic> setup) {
  final history = setup['history'] as List<dynamic>;
  if (history.isEmpty) return Map<String, dynamic>.from(setup);
  final migratedHistory = [
    {...history[0] as Map<String, dynamic>, 'isCreationEntry': true},
    ...history.skip(1),
  ];
  return {...setup, 'history': migratedHistory};
}