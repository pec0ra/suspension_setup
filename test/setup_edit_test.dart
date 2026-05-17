import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:suspension_setup/models/field.dart';
import 'package:suspension_setup/models/settings.dart';
import 'package:suspension_setup/models/setup.dart';
import 'package:suspension_setup/setting_tiles.dart';
import 'package:suspension_setup/setup_edit.dart';
import 'package:suspension_setup/setup_storage_model.dart';
import 'package:suspension_setup/value_edit.dart';

class _FakeStorageModel extends SetupStorageModel {
  Setup? lastUpserted;

  @override
  Future<void> initSetups() async {}

  @override
  Setup? getSetup(String id) => null;

  @override
  Future<void> upsertSetup(Setup setup) async {
    lastUpserted = setup;
    notifyListeners();
  }
}

Widget _setupEditHarness(_FakeStorageModel model, Setup? setup) {
  return ChangeNotifierProvider<SetupStorageModel>.value(
    value: model,
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => Navigator.push<void>(
              ctx,
              MaterialPageRoute(builder: (_) => SetupEdit(setup: setup)),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

Widget _valueEditHarness(_FakeStorageModel model, Setup setup) {
  return ChangeNotifierProvider<SetupStorageModel>.value(
    value: model,
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => Navigator.push<void>(
              ctx,
              MaterialPageRoute(builder: (_) => ValueEdit(setup: setup)),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

Setup _makeSetup({List<Field> forkFields = const []}) {
  final ids = forkFields.map((f) => f.id).toList();
  return Setup(
    id: 'test',
    name: 'Trail Setup',
    fork: SectionSettings(
      fields: List.from(forkFields),
      layout: ids.isEmpty ? [] : [ids],
    ),
    shock: SectionSettings(fields: [], layout: []),
    tyres: SectionSettings(fields: [], layout: []),
    history: [],
  );
}

void main() {
  group('validateInfoUrl', () {
    test('accepts null', () {
      expect(validateInfoUrl(null), isNull);
    });

    test('accepts empty string', () {
      expect(validateInfoUrl(''), isNull);
    });

    test('accepts whitespace-only string', () {
      expect(validateInfoUrl('   '), isNull);
    });

    test('accepts valid https URL', () {
      expect(validateInfoUrl('https://example.com/product'), isNull);
    });

    test('accepts valid http URL', () {
      expect(validateInfoUrl('http://example.com'), isNull);
    });

    test('rejects string with no scheme', () {
      expect(validateInfoUrl('example.com/product'), isNotNull);
    });

    test('rejects plain text', () {
      expect(validateInfoUrl('not a url at all'), isNotNull);
    });
  });

  group('SetupEdit FAB state', () {
    testWidgets('shows Save tooltip when no new fields', (tester) async {
      final model = _FakeStorageModel();
      final airField = Field(name: 'Air Pressure', unit: 'PSI', value: 73);
      final setup = _makeSetup(forkFields: [airField]);

      await tester.pumpWidget(_setupEditHarness(model, setup));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Save setup'), findsOneWidget);
    });

    testWidgets('FAB switches to Edit values after adding a field',
        (tester) async {
      final model = _FakeStorageModel();

      await tester.pumpWidget(_setupEditHarness(model, null));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Tap the first "Add field" button (Fork section)
      await tester.tap(find.text('Add field').first);
      await tester.pumpAndSettle();

      // Fill in the dialog
      await tester.enterText(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(TextField),
            )
            .first,
        'Air Pressure',
      );
      await tester.pump();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Edit values'), findsOneWidget);
    });
  });

  group('SetupEdit → ValueEdit cancel', () {
    testWidgets('cancelling ValueEdit restores shared controller field values',
        (tester) async {
      final model = _FakeStorageModel();
      final airField = Field(name: 'Air Pressure', unit: 'PSI', value: 73);
      final setup = _makeSetup(forkFields: [airField]);

      await tester.pumpWidget(_setupEditHarness(model, setup));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Add a field to make FAB show "Edit values"
      await tester.tap(find.text('Add field').first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(TextField),
            )
            .first,
        'Sag',
      );
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Navigate to ValueEdit
      await tester.tap(find.byTooltip('Edit values'));
      await tester.pumpAndSettle();

      // Change the existing air-pressure value from 73 → 80
      await tester.enterText(
        find.descendant(
          of: find.byType(FieldValueCard).first,
          matching: find.byType(TextFormField),
        ),
        '80',
      );
      await tester.pump();

      // Cancel ValueEdit without saving
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Navigate to ValueEdit again — the air pressure value must be restored
      await tester.tap(find.byTooltip('Edit values'));
      await tester.pumpAndSettle();

      final restoredField = tester.widget<TextFormField>(
        find.descendant(
          of: find.byType(FieldValueCard).first,
          matching: find.byType(TextFormField),
        ),
      );
      expect(restoredField.controller!.text, '73');
    });
  });

  group('SetupEdit direct save', () {
    testWidgets('saving with no new fields calls upsert directly',
        (tester) async {
      final model = _FakeStorageModel();
      final airField = Field(name: 'Air Pressure', unit: 'PSI', value: 73);
      final setup = _makeSetup(forkFields: [airField]);

      await tester.pumpWidget(_setupEditHarness(model, setup));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Save setup'), findsOneWidget);

      await tester.tap(find.byTooltip('Save setup'));
      await tester.pumpAndSettle();

      // No changes → no comment dialog → saved directly
      expect(model.lastUpserted, isNotNull);
      expect(model.lastUpserted!.name, 'Trail Setup');
    });
  });

  group('ValueEdit standalone', () {
    testWidgets('editing a value and saving persists the change',
        (tester) async {
      final model = _FakeStorageModel();
      final airField = Field(name: 'Air Pressure', unit: 'PSI', value: 73);
      final setup = _makeSetup(forkFields: [airField]);

      await tester.pumpWidget(_valueEditHarness(model, setup));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Change air pressure from 73 to 80
      await tester.enterText(
        find.descendant(
          of: find.byType(FieldValueCard).first,
          matching: find.byType(TextFormField),
        ),
        '80',
      );
      await tester.pump();

      // Tap Save FAB → comment dialog appears
      await tester.tap(find.byTooltip('Save values'));
      await tester.pumpAndSettle();

      // Dismiss the comment dialog
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(model.lastUpserted, isNotNull);
      expect(
        model.lastUpserted!.fork.activeFields
            .firstWhere((f) => f.name == 'Air Pressure')
            .value,
        80,
      );
      expect(find.text('Setup saved successfully'), findsOneWidget);
    });

    testWidgets('owns and disposes its own controller', (tester) async {
      final model = _FakeStorageModel();
      final airField = Field(name: 'Air Pressure', unit: 'PSI', value: 73);
      final setup = _makeSetup(forkFields: [airField]);

      await tester.pumpWidget(_valueEditHarness(model, setup));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Replacing the widget tree disposes ValueEdit — no assertion errors
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump();
      // No exception thrown = controller was disposed exactly once
    });
  });
}
