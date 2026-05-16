import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:suspension_setup/models/field.dart';
import 'package:suspension_setup/models/settings.dart';
import 'package:suspension_setup/models/setup.dart';
import 'package:suspension_setup/models/tyres.dart';
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

Setup _makeSetup({String? serialNumber, String? infoUrl}) {
  return Setup(
    id: 'test-id',
    name: 'Trail Setup',
    fork: Settings(
      airPressure: const Field(value: 70, unit: 'PSI'),
      serialNumber: serialNumber,
      infoUrl: infoUrl,
    ),
    shock: Settings(),
    tyres: Tyres(),
    history: [],
  );
}

void main() {
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
