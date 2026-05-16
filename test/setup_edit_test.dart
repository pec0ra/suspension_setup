import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:suspension_setup/models/field.dart';
import 'package:suspension_setup/models/settings.dart';
import 'package:suspension_setup/models/setup.dart';
import 'package:suspension_setup/models/tyres.dart';
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

// Push SetupEdit onto a parent Scaffold so the snackbar has somewhere to land
// after SetupEdit pops.
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

// Push ValueEdit onto a parent Scaffold for the same reason.
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

  group('SetupEdit → ValueEdit cancel', () {
    testWidgets('cancelling ValueEdit restores shared controller field values',
        (tester) async {
      final model = _FakeStorageModel();
      final setup = Setup(
        id: 'test',
        name: 'Trail Setup',
        fork: Settings(airPressure: const Field(value: 73, unit: 'PSI')),
        shock: Settings(),
        tyres: Tyres(),
        history: [],
      );

      await tester.pumpWidget(_setupEditHarness(model, setup));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Enable Sag — _hasNewlyEnabled becomes true, FAB switches to arrow.
      await tester.tap(find.text('Sag').first);
      await tester.pump();

      // Navigate to ValueEdit.
      await tester.tap(find.byTooltip('Edit values'));
      await tester.pumpAndSettle();

      // In ValueEdit: change the existing air-pressure value from 73 → 80.
      await tester.enterText(
        find.descendant(
          of: find.byType(FieldValueCard).first,
          matching: find.byType(TextFormField),
        ),
        '80',
      );
      await tester.pump();

      // Cancel ValueEdit without saving.
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Navigate to ValueEdit again — the value must be restored to 73.
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

  group('SetupEdit → ValueEdit save (happy path)', () {
    testWidgets(
        'saving in ValueEdit persists the setup with the newly enabled field',
        (tester) async {
      final model = _FakeStorageModel();
      final setup = Setup(
        id: 'test',
        name: 'Trail Setup',
        fork: Settings(airPressure: const Field(value: 73, unit: 'PSI')),
        shock: Settings(),
        tyres: Tyres(),
        history: [],
      );

      await tester.pumpWidget(_setupEditHarness(model, setup));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Enable Sag → FAB becomes arrow.
      await tester.tap(find.text('Sag').first);
      await tester.pump();

      // Navigate to ValueEdit.
      await tester.tap(find.byTooltip('Edit values'));
      await tester.pumpAndSettle();

      // Enter a value for the newly-enabled Sag field (second FieldValueCard).
      await tester.enterText(
        find.descendant(
          of: find.byType(FieldValueCard).at(1),
          matching: find.byType(TextFormField),
        ),
        '25',
      );
      await tester.pump();

      // Tap Save FAB → comment dialog appears.
      await tester.tap(find.byTooltip('Save values'));
      await tester.pumpAndSettle();

      // Dismiss the comment dialog without adding a comment.
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(model.lastUpserted, isNotNull);
      expect(model.lastUpserted!.fork.airPressure?.value, 73);
      expect(model.lastUpserted!.fork.sag?.value, 25);
      expect(find.text('Setup saved successfully'), findsOneWidget);
    });
  });

  group('ValueEdit standalone', () {
    testWidgets('editing a value and saving persists the change',
        (tester) async {
      final model = _FakeStorageModel();
      final setup = Setup(
        id: 'test',
        name: 'Trail Setup',
        fork: Settings(airPressure: const Field(value: 73, unit: 'PSI')),
        shock: Settings(),
        tyres: Tyres(),
        history: [],
      );

      await tester.pumpWidget(_valueEditHarness(model, setup));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Change air pressure from 73 to 80.
      await tester.enterText(
        find.descendant(
          of: find.byType(FieldValueCard).first,
          matching: find.byType(TextFormField),
        ),
        '80',
      );
      await tester.pump();

      // Tap Save FAB → comment dialog appears.
      await tester.tap(find.byTooltip('Save values'));
      await tester.pumpAndSettle();

      // Dismiss the comment dialog.
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(model.lastUpserted, isNotNull);
      expect(model.lastUpserted!.fork.airPressure?.value, 80);
      expect(find.text('Setup saved successfully'), findsOneWidget);
    });

    testWidgets('owns and disposes its own controller', (tester) async {
      final model = _FakeStorageModel();
      final setup = Setup(
        id: 'test',
        name: 'Trail Setup',
        fork: Settings(airPressure: const Field(value: 73, unit: 'PSI')),
        shock: Settings(),
        tyres: Tyres(),
        history: [],
      );

      await tester.pumpWidget(_valueEditHarness(model, setup));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Replacing the widget tree disposes ValueEdit — no assertion errors from
      // double-dispose if _ownsController is handled correctly.
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump();
      // No exception thrown = controller was disposed exactly once.
    });
  });

  group('SetupEdit direct save (no new fields)', () {
    testWidgets('disabling a field saves without navigating to ValueEdit',
        (tester) async {
      final model = _FakeStorageModel();
      final setup = Setup(
        id: 'test',
        name: 'Trail Setup',
        fork: Settings(
          airPressure: const Field(value: 73, unit: 'PSI'),
          sag: const Field(value: 25, unit: '%'),
        ),
        shock: Settings(),
        tyres: Tyres(),
        history: [],
      );

      await tester.pumpWidget(_setupEditHarness(model, setup));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Disable Sag — no new fields enabled, FAB stays on 'Save setup'.
      await tester.tap(find.text('Sag').first);
      await tester.pump();

      // No ValueEdit navigation expected: FAB has 'Save setup' tooltip.
      expect(find.byTooltip('Save setup'), findsOneWidget);

      // Tap Save FAB → comment dialog (disabling is a change).
      await tester.tap(find.byTooltip('Save setup'));
      await tester.pumpAndSettle();

      // Dismiss the comment dialog.
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(model.lastUpserted, isNotNull);
      expect(model.lastUpserted!.fork.sag, isNull);
      expect(model.lastUpserted!.fork.airPressure?.value, 73);
      expect(find.text('Setup saved successfully'), findsOneWidget);
    });
  });
}
