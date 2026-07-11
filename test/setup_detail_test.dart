import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:suspension_setup/models/field.dart';
import 'package:suspension_setup/models/setting_change.dart';
import 'package:suspension_setup/models/settings.dart';
import 'package:suspension_setup/models/setup.dart';
import 'package:suspension_setup/setup_detail.dart';
import 'package:suspension_setup/setup_storage_model.dart';

class _FakeStorageModel extends SetupStorageModel {
  _FakeStorageModel(this._setup);
  final Setup _setup;

  @override
  Future<void> initSetups() async {}

  @override
  Setup? getSetup(String id) => id == _setup.id ? _setup : null;
}

Widget _harness(Setup setup) {
  return ChangeNotifierProvider<SetupStorageModel>(
    create: (_) => _FakeStorageModel(setup),
    child: MaterialApp(home: SetupDetail(setupId: setup.id)),
  );
}

/// Fake that keeps the setup in memory (no disk I/O) so that `upsertSetup`
/// updates the rendered state and records the last write.
class _MutableFakeStorageModel extends SetupStorageModel {
  _MutableFakeStorageModel(this._setup);
  Setup _setup;
  Setup? lastUpserted;

  @override
  Future<void> initSetups() async {}

  @override
  Setup? getSetup(String id) => id == _setup.id ? _setup : null;

  @override
  Future<void> upsertSetup(Setup setup) async {
    lastUpserted = setup;
    _setup = setup;
    notifyListeners();
  }
}

Widget _mutableHarness(Setup setup, SetupStorageModel model) {
  return ChangeNotifierProvider<SetupStorageModel>.value(
    value: model,
    child: MaterialApp(home: SetupDetail(setupId: setup.id)),
  );
}

Setup _makeSetup({String? serialNumber, String? infoUrl}) {
  final airField = Field(name: 'Air Pressure', unit: 'PSI', value: 70);
  return Setup(
    id: 'test-id',
    name: 'Trail Setup',
    fork: SectionSettings(
      fields: [airField],
      layout: [
        [airField.id]
      ],
      serialNumber: serialNumber,
      infoUrl: infoUrl,
    ),
    shock: SectionSettings(fields: [], layout: []),
    tyres: SectionSettings(fields: [], layout: []),
    history: [],
  );
}

void main() {
  group('History', () {
    testWidgets('shows value change with field name and unit', (tester) async {
      final airField = Field(name: 'Air Pressure', unit: 'PSI', value: 110);
      final setup = Setup(
        id: 'test-id',
        name: 'Trail Setup',
        fork: SectionSettings(fields: [
          airField
        ], layout: [
          [airField.id]
        ]),
        shock: SectionSettings(fields: [], layout: []),
        tyres: SectionSettings(fields: [], layout: []),
        history: [
          SettingChanges(
            changes: [
              SettingChange(
                suspensionType: SuspensionType.fork,
                fieldId: airField.id,
                oldValue: 100,
                newValue: 110,
              ),
            ],
            date: DateTime.now(),
          ),
        ],
      );

      await tester.pumpWidget(_harness(setup));
      await tester.pump();

      expect(find.text('Air Pressure: 100 → 110 PSI'), findsOneWidget);
    });

    testWidgets('shows correct name and unit for deleted field in history',
        (tester) async {
      final sagField = Field(name: 'Sag', unit: '%', deleted: true);
      final setup = Setup(
        id: 'test-id',
        name: 'Trail Setup',
        fork: SectionSettings(fields: [sagField], layout: []),
        shock: SectionSettings(fields: [], layout: []),
        tyres: SectionSettings(fields: [], layout: []),
        history: [
          SettingChanges(
            changes: [
              SettingChange(
                suspensionType: SuspensionType.fork,
                fieldId: sagField.id,
                oldValue: 25,
                newValue: null,
                oldEnabled: true,
                newEnabled: false,
              ),
            ],
            date: DateTime.now(),
          ),
        ],
      );

      await tester.pumpWidget(_harness(setup));
      await tester.pump();

      expect(find.text('Sag: disabled (was 25 %)'), findsOneWidget);
    });
  });

  group('Add note', () {
    Setup makeSetupWithHistory() {
      final airField = Field(name: 'Air Pressure', unit: 'PSI', value: 70);
      return Setup(
        id: 'test-id',
        name: 'Trail Setup',
        fork: SectionSettings(fields: [
          airField
        ], layout: [
          [airField.id]
        ]),
        shock: SectionSettings(fields: [], layout: []),
        tyres: SectionSettings(fields: [], layout: []),
        history: [
          SettingChanges(
            changes: [],
            date: DateTime.now(),
            comment: 'Setup creation',
            isCreationEntry: true,
          ),
        ],
      );
    }

    testWidgets('appends a comment-only entry and blocks an empty note',
        (tester) async {
      final setup = makeSetupWithHistory();
      final model = _MutableFakeStorageModel(setup);

      await tester.pumpWidget(_mutableHarness(setup, model));
      await tester.pump();

      await tester.tap(find.byTooltip('Add note'));
      await tester.pumpAndSettle();

      // Save stays disabled while the field is empty.
      final saveButton = find.widgetWithText(TextButton, 'Save');
      expect(tester.widget<TextButton>(saveButton).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'Felt harsh today');
      await tester.pump();
      expect(tester.widget<TextButton>(saveButton).onPressed, isNotNull);

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Persisted as a comment-only, non-creation entry.
      final history = model.lastUpserted!.history;
      expect(history.length, 2);
      expect(history.last.comment, 'Felt harsh today');
      expect(history.last.changes, isEmpty);
      expect(history.last.isCreationEntry, isFalse);

      // Rendered in the timeline.
      expect(find.text('Felt harsh today'), findsOneWidget);

      // Let the confirmation snackbar's auto-dismiss timer expire.
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('does not offer Undo for a comment-only note', (tester) async {
      final airField = Field(name: 'Air Pressure', unit: 'PSI', value: 70);
      final setup = Setup(
        id: 'test-id',
        name: 'Trail Setup',
        fork: SectionSettings(fields: [
          airField
        ], layout: [
          [airField.id]
        ]),
        shock: SectionSettings(fields: [], layout: []),
        tyres: SectionSettings(fields: [], layout: []),
        history: [
          SettingChanges(
            changes: [],
            date: DateTime.now(),
            comment: 'Felt harsh today',
          ),
        ],
      );

      await tester.pumpWidget(_harness(setup));
      await tester.pump();

      await tester.tap(find.text('Felt harsh today'));
      await tester.pumpAndSettle();

      expect(find.text('Edit comment'), findsOneWidget);
      expect(find.text('Undo this change'), findsNothing);
    });
  });

  group('_ComponentInfo', () {
    testWidgets('renders nothing when serialNumber and infoUrl are both null',
        (tester) async {
      await tester.pumpWidget(_harness(_makeSetup()));
      await tester.pump();

      expect(find.text('Product Information'), findsNothing);
      expect(find.text('Manufacturer Page'), findsNothing);
    });

    testWidgets('renders card with serialNumber when set', (tester) async {
      await tester.pumpWidget(_harness(_makeSetup(serialNumber: 'SN-ABC-123')));
      await tester.pump();

      expect(find.text('Product Information'), findsOneWidget);
      expect(find.text('Serial Number'), findsOneWidget);
      expect(find.text('SN-ABC-123'), findsOneWidget);
      expect(find.text('Manufacturer Page'), findsNothing);
    });

    testWidgets('renders Manufacturer Page button when infoUrl is set',
        (tester) async {
      await tester
          .pumpWidget(_harness(_makeSetup(infoUrl: 'https://example.com')));
      await tester.pump();

      expect(find.text('Product Information'), findsOneWidget);
      expect(find.text('Manufacturer Page'), findsOneWidget);
      expect(find.text('Serial Number'), findsNothing);
    });

    testWidgets('renders both serialNumber and button when both are set',
        (tester) async {
      await tester.pumpWidget(_harness(
          _makeSetup(serialNumber: 'SN-XYZ', infoUrl: 'https://example.com')));
      await tester.pump();

      expect(find.text('Product Information'), findsOneWidget);
      expect(find.text('SN-XYZ'), findsOneWidget);
      expect(find.text('Manufacturer Page'), findsOneWidget);
    });
  });
}
