import 'package:flutter_test/flutter_test.dart';
import 'package:suspension_setup/models/field.dart';
import 'package:suspension_setup/models/setting_change.dart';
import 'package:suspension_setup/models/settings.dart';
import 'package:suspension_setup/models/setup.dart';
import 'package:suspension_setup/models/tyres.dart';

Settings _makeSettings({bool allEnabled = true}) {
  if (allEnabled) {
    return Settings(
      airPressure: const Field(value: 120, unit: 'PSI'),
      sag: const Field(value: 30, unit: '%'),
      volumeSpacer: const Field(value: 3, unit: 'Spacers'),
      lsc: const Field(value: 10, unit: 'Clicks'),
      hsc: const Field(value: 5, unit: 'Clicks'),
      lsr: const Field(value: 8, unit: 'Clicks'),
      hsr: const Field(value: 4, unit: 'Clicks'),
    );
  }
  return Settings(
    airPressure: const Field(value: 100, unit: 'PSI'),
    sag: const Field(value: 25, unit: '%'),
    lsc: const Field(value: 6, unit: 'Clicks'),
    lsr: const Field(value: 4, unit: 'Clicks'),
  );
}

void main() {
  group('Settings', () {
    test('roundtrips through JSON with all fields enabled', () {
      final settings = _makeSettings(allEnabled: true);
      final restored = Settings.fromJson(settings.toJson());
      expect(restored.airPressure?.value, 120);
      expect(restored.airPressure?.unit, 'PSI');
      expect(restored.sag?.value, 30);
      expect(restored.volumeSpacer?.value, 3);
      expect(restored.lsc?.value, 10);
      expect(restored.hsc?.value, 5);
      expect(restored.lsr?.value, 8);
      expect(restored.hsr?.value, 4);
    });

    test('roundtrips through JSON with optional fields disabled (null)', () {
      final settings = _makeSettings(allEnabled: false);
      final restored = Settings.fromJson(settings.toJson());
      expect(restored.airPressure?.value, 100);
      expect(restored.volumeSpacer, isNull);
      expect(restored.hsc, isNull);
      expect(restored.hsr, isNull);
    });

    test('serialNumber and infoUrl roundtrip through JSON', () {
      final settings = Settings(
        airPressure: const Field(value: 100, unit: 'PSI'),
        serialNumber: 'SN-ABC-123',
        infoUrl: 'https://example.com/product',
      );
      final restored = Settings.fromJson(settings.toJson());
      expect(restored.serialNumber, 'SN-ABC-123');
      expect(restored.infoUrl, 'https://example.com/product');
    });

    test('hasAnyField true when only serialNumber set', () {
      expect(Settings(serialNumber: 'SN-123').hasAnyField, isTrue);
    });

    test('hasAnyField true when only infoUrl set', () {
      expect(Settings(infoUrl: 'https://example.com').hasAnyField, isTrue);
    });

    test('hasAnyField false when no fields set', () {
      expect(Settings().hasAnyField, isFalse);
    });

    test('clone copies serialNumber and infoUrl', () {
      final original = Settings(
        airPressure: const Field(value: 80, unit: 'PSI'),
        serialNumber: 'SN-ORIG',
        infoUrl: 'https://orig.example.com',
      );
      final clone = original.clone();
      expect(clone.serialNumber, 'SN-ORIG');
      expect(clone.infoUrl, 'https://orig.example.com');
    });

    test('deserializes JSON without serialNumber/infoUrl keys (backwards compat)', () {
      final json = {
        'airPressure': {'value': 100, 'unit': 'PSI'},
        'sag': null,
        'volumeSpacer': null,
        'lsc': null,
        'hsc': null,
        'lsr': null,
        'hsr': null,
      };
      final settings = Settings.fromJson(json);
      expect(settings.serialNumber, isNull);
      expect(settings.infoUrl, isNull);
      expect(settings.airPressure?.value, 100);
    });

    test('clone produces equal but independent copy', () {
      final original = Settings(
        airPressure: const Field(value: 80, unit: 'PSI'),
        sag: const Field(value: 20, unit: '%'),
        lsc: const Field(value: 4, unit: 'Clicks'),
        lsr: const Field(value: 3, unit: 'Clicks'),
        hsc: const Field(value: 2, unit: 'Clicks'),
        hsr: const Field(value: 1, unit: 'Clicks'),
      );
      final clone = original.clone();
      clone.airPressure = const Field(value: 999, unit: 'PSI');
      expect(original.airPressure?.value, 80);
    });
  });

  group('Field', () {
    test('roundtrips a decimal value through JSON', () {
      const original = Field(value: 28.5, unit: 'PSI');
      final restored = Field.fromJson(original.toJson());
      expect(restored.value, 28.5);
      expect(restored.unit, 'PSI');
    });

    test('legacy integer JSON parses as int (no coercion to double)', () {
      final restored = Field.fromJson({'value': 100, 'unit': 'PSI'});
      expect(restored.value, 100);
      expect(restored.value, isA<int>());
    });
  });

  group('SettingChange', () {
    test('roundtrips through JSON', () {
      final change = SettingChange(
        suspensionType: SuspensionType.fork,
        settingType: SettingType.airPressure,
        oldValue: 100,
        newValue: 120,
      );
      final restored = SettingChange.fromJson(change.toJson());
      expect(restored.suspensionType, SuspensionType.fork);
      expect(restored.settingType, SettingType.airPressure);
      expect(restored.oldValue, 100);
      expect(restored.newValue, 120);
    });

    test('roundtrips decimal old/new values through JSON', () {
      final change = SettingChange(
        suspensionType: SuspensionType.tyre,
        settingType: SettingType.frontTyrePressure,
        oldValue: 27.5,
        newValue: 28.25,
      );
      final restored = SettingChange.fromJson(change.toJson());
      expect(restored.oldValue, 27.5);
      expect(restored.newValue, 28.25);
    });

    test('roundtrips with null values (new setup, no prior value)', () {
      final change = SettingChange(
        suspensionType: SuspensionType.shock,
        settingType: SettingType.hsc,
        oldValue: null,
        newValue: null,
      );
      final restored = SettingChange.fromJson(change.toJson());
      expect(restored.oldValue, isNull);
      expect(restored.newValue, isNull);
    });

    test('roundtrips with enabled/disabled toggle', () {
      final change = SettingChange(
        suspensionType: SuspensionType.fork,
        settingType: SettingType.hsc,
        oldValue: null,
        newValue: 5,
        oldEnabled: false,
        newEnabled: true,
      );
      final restored = SettingChange.fromJson(change.toJson());
      expect(restored.oldEnabled, false);
      expect(restored.newEnabled, true);
      expect(restored.newValue, 5);
    });
  });

  group('SettingChanges', () {
    test('roundtrips through JSON preserving date and comment', () {
      final date = DateTime.utc(2024, 6, 15, 10, 30);
      final changes = SettingChanges(
        changes: [
          SettingChange(
            suspensionType: SuspensionType.fork,
            settingType: SettingType.sag,
            oldValue: 25,
            newValue: 28,
          ),
        ],
        date: date,
        comment: 'Trail ride tuning',
      );
      final restored = SettingChanges.fromJson(changes.toJson());
      expect(restored.date, date);
      expect(restored.comment, 'Trail ride tuning');
      expect(restored.changes, hasLength(1));
      expect(restored.changes.first.newValue, 28);
    });

    test('roundtrips with null comment', () {
      final changes = SettingChanges(
        changes: [],
        date: DateTime.now(),
        comment: null,
      );
      final restored = SettingChanges.fromJson(changes.toJson());
      expect(restored.comment, isNull);
    });
  });

  group('Setup', () {
    test('roundtrips through JSON preserving all fields', () {
      final original = Setup(
        id: 'test-id-123',
        name: 'Enduro race',
        fork: Settings(
          airPressure: const Field(value: 110, unit: 'PSI'),
          sag: const Field(value: 25, unit: '%'),
          lsc: const Field(value: 8, unit: 'Clicks'),
          lsr: const Field(value: 6, unit: 'Clicks'),
          hsc: const Field(value: 3, unit: 'Clicks'),
        ),
        shock: Settings(
          airPressure: const Field(value: 200, unit: 'PSI'),
          sag: const Field(value: 30, unit: '%'),
          lsc: const Field(value: 5, unit: 'Clicks'),
          lsr: const Field(value: 4, unit: 'Clicks'),
        ),
        tyres: Tyres(
          front: const Field(value: 28, unit: 'PSI'),
          rear: const Field(value: 26, unit: 'PSI'),
        ),
        history: [
          SettingChanges(
            changes: [],
            date: DateTime.utc(2024, 1, 1),
            comment: 'Setup creation',
            isCreationEntry: true,
          ),
        ],
      );
      final restored = Setup.fromJson(original.toJson());
      expect(restored.id, 'test-id-123');
      expect(restored.name, 'Enduro race');
      expect(restored.fork.airPressure?.value, 110);
      expect(restored.fork.hsc?.value, 3);
      expect(restored.fork.hsr, isNull);
      expect(restored.shock.sag?.value, 30);
      expect(restored.history, hasLength(1));
      expect(restored.history.first.comment, 'Setup creation');
      expect(restored.history.first.isCreationEntry, isTrue);
    });

    test('clone with history produces independent copy with new id', () {
      final original = Setup(
        id: 'original-id',
        name: 'Base setup',
        fork: Settings(
          airPressure: const Field(value: 100, unit: 'PSI'),
          sag: const Field(value: 20, unit: '%'),
          lsc: const Field(value: 5, unit: 'Clicks'),
          lsr: const Field(value: 4, unit: 'Clicks'),
        ),
        shock: Settings(
          airPressure: const Field(value: 150, unit: 'PSI'),
          sag: const Field(value: 25, unit: '%'),
          lsc: const Field(value: 3, unit: 'Clicks'),
          lsr: const Field(value: 2, unit: 'Clicks'),
        ),
        tyres: Tyres(),
        history: [
          SettingChanges(changes: [], date: DateTime.now(), comment: 'initial'),
        ],
      );
      final clone = original.clone(true);
      expect(clone.id, isNot('original-id'));
      expect(clone.name, 'Base setup');
      expect(clone.history, hasLength(1));
    });

    test('deserializes legacy JSON without tyres key as empty tyres', () {
      final json = {
        'id': 'legacy-id',
        'name': 'Legacy setup',
        'fork': {
          'airPressure': {'value': 100, 'unit': 'PSI'},
          'sag': {'value': 25, 'unit': '%'},
          'volumeSpacer': null,
          'lsc': {'value': 8, 'unit': 'Clicks'},
          'hsc': null,
          'lsr': {'value': 6, 'unit': 'Clicks'},
          'hsr': null,
        },
        'shock': {
          'airPressure': {'value': 180, 'unit': 'PSI'},
          'sag': {'value': 30, 'unit': '%'},
          'volumeSpacer': null,
          'lsc': {'value': 5, 'unit': 'Clicks'},
          'hsc': null,
          'lsr': {'value': 4, 'unit': 'Clicks'},
          'hsr': null,
        },
        // no 'tyres' key — simulates a pre-tyre config
        'history': [],
      };
      final setup = Setup.fromJson(json);
      expect(setup.tyres.front, isNull);
      expect(setup.tyres.rear, isNull);
    });

    test('roundtrips a setup containing decimal field values', () {
      final original = Setup(
        id: 'decimal-id',
        name: 'Decimal setup',
        fork: Settings(
          airPressure: const Field(value: 73.5, unit: 'PSI'),
          sag: const Field(value: 17, unit: '%'),
          lsc: const Field(value: 8, unit: 'Clicks'),
          lsr: const Field(value: 6, unit: 'Clicks'),
        ),
        shock: Settings(
          airPressure: const Field(value: 165, unit: 'PSI'),
          sag: const Field(value: 27, unit: '%'),
          lsc: const Field(value: 8, unit: 'Clicks'),
          lsr: const Field(value: 8, unit: 'Clicks'),
        ),
        tyres: Tyres(
          front: const Field(value: 22.5, unit: 'PSI'),
          rear: const Field(value: 24.75, unit: 'PSI'),
        ),
        history: [],
      );
      final restored = Setup.fromJson(original.toJson());
      expect(restored.fork.airPressure?.value, 73.5);
      expect(restored.tyres.front?.value, 22.5);
      expect(restored.tyres.rear?.value, 24.75);
      expect(restored.fork.sag?.value, isA<int>());
    });

    test('clone without history produces empty history', () {
      final original = Setup(
        id: 'original-id',
        name: 'Base setup',
        fork: Settings(
          airPressure: const Field(value: 100, unit: 'PSI'),
          sag: const Field(value: 20, unit: '%'),
          lsc: const Field(value: 5, unit: 'Clicks'),
          lsr: const Field(value: 4, unit: 'Clicks'),
        ),
        shock: Settings(
          airPressure: const Field(value: 150, unit: 'PSI'),
          sag: const Field(value: 25, unit: '%'),
          lsc: const Field(value: 3, unit: 'Clicks'),
          lsr: const Field(value: 2, unit: 'Clicks'),
        ),
        tyres: Tyres(),
        history: [
          SettingChanges(changes: [], date: DateTime.now()),
        ],
      );
      final clone = original.clone(false);
      expect(clone.history, isEmpty);
    });
  });
}