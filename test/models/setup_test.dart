import 'package:flutter_test/flutter_test.dart';
import 'package:suspension_setup/models/setting_change.dart';
import 'package:suspension_setup/models/settings.dart';
import 'package:suspension_setup/models/setup.dart';

void main() {
  group('Settings', () {
    test('roundtrips through JSON with all fields', () {
      final settings = Settings(
        airPressure: 120,
        sag: 30,
        volumeSpacer: 3,
        lsc: 10,
        hsc: 5,
        lsr: 8,
        hsr: 4,
      );
      final restored = Settings.fromJson(settings.toJson());
      expect(restored.airPressure, 120);
      expect(restored.sag, 30);
      expect(restored.volumeSpacer, 3);
      expect(restored.lsc, 10);
      expect(restored.hsc, 5);
      expect(restored.lsr, 8);
      expect(restored.hsr, 4);
    });

    test('roundtrips through JSON with nullable fields absent', () {
      final settings = Settings(
        airPressure: 100,
        sag: 25,
        lsc: 6,
        lsr: 4,
      );
      final restored = Settings.fromJson(settings.toJson());
      expect(restored.volumeSpacer, isNull);
      expect(restored.hsc, isNull);
      expect(restored.hsr, isNull);
    });

    test('clone produces equal but independent copy', () {
      final original = Settings(
          airPressure: 80, sag: 20, lsc: 4, lsr: 3, hsc: 2, hsr: 1);
      final clone = original.clone();
      clone.airPressure = 999;
      expect(original.airPressure, 80);
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
        fork: Settings(airPressure: 110, sag: 25, lsc: 8, lsr: 6, hsc: 3),
        shock: Settings(airPressure: 200, sag: 30, lsc: 5, lsr: 4),
        history: [
          SettingChanges(
            changes: [],
            date: DateTime.utc(2024, 1, 1),
            comment: SettingChanges.defaultComment,
          ),
        ],
      );
      final restored = Setup.fromJson(original.toJson());
      expect(restored.id, 'test-id-123');
      expect(restored.name, 'Enduro race');
      expect(restored.fork.airPressure, 110);
      expect(restored.shock.sag, 30);
      expect(restored.history, hasLength(1));
      expect(restored.history.first.comment, SettingChanges.defaultComment);
    });

    test('clone with history produces independent copy with new id', () {
      final original = Setup(
        id: 'original-id',
        name: 'Base setup',
        fork: Settings(airPressure: 100, sag: 20, lsc: 5, lsr: 4),
        shock: Settings(airPressure: 150, sag: 25, lsc: 3, lsr: 2),
        history: [
          SettingChanges(changes: [], date: DateTime.now(), comment: 'initial'),
        ],
      );
      final clone = original.clone(true);
      expect(clone.id, isNot('original-id'));
      expect(clone.name, 'Base setup');
      expect(clone.history, hasLength(1));
    });

    test('clone without history produces empty history', () {
      final original = Setup(
        id: 'original-id',
        name: 'Base setup',
        fork: Settings(airPressure: 100, sag: 20, lsc: 5, lsr: 4),
        shock: Settings(airPressure: 150, sag: 25, lsc: 3, lsr: 2),
        history: [
          SettingChanges(changes: [], date: DateTime.now()),
        ],
      );
      final clone = original.clone(false);
      expect(clone.history, isEmpty);
    });
  });
}