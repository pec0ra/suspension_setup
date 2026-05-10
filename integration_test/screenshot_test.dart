import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:suspension_setup/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Take App Store screenshots', (tester) async {
    final dir = await getApplicationDocumentsDirectory();
    await File('${dir.path}/setups.json').writeAsString(jsonEncode(_fixture));

    app.main();
    await tester.pumpAndSettle();

    if (Platform.isAndroid) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
    }

    await _takeScreenshots(binding, tester, '_light');

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();

    await _takeScreenshots(binding, tester, '_dark', baseIndex: 5);
  });
}

Future<void> _takeScreenshots(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String suffix, {
  int baseIndex = 1,
}) async {
  String idx(int offset) => (baseIndex + offset).toString().padLeft(2, '0');

  await _screenshot(binding, tester, '${idx(0)}_home$suffix');

  tester.widget<ListTile>(
    find.ancestor(of: find.text('Yeti'), matching: find.byType(ListTile)),
  ).onTap!();
  await tester.pumpAndSettle();
  await _screenshot(binding, tester, '${idx(1)}_detail$suffix');

  await Scrollable.ensureVisible(
    tester.element(find.text('History')),
    alignment: 0.0,
    duration: Duration.zero,
  );
  await tester.pumpAndSettle();
  await _screenshot(binding, tester, '${idx(2)}_history$suffix');

  tester.widget<IconButton>(
    find.ancestor(of: find.byIcon(Icons.edit), matching: find.byType(IconButton)),
  ).onPressed!();
  await tester.pumpAndSettle();
  await _screenshot(binding, tester, '${idx(3)}_edit$suffix');

  tester.state<NavigatorState>(find.byType(Navigator).first)
      .popUntil((route) => route.isFirst);
  await tester.pumpAndSettle();
}

Future<void> _screenshot(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  if (!Platform.isIOS && !Platform.isAndroid) return;
  if (Platform.isIOS) {
    await binding.convertFlutterSurfaceToImage();
  }
  await tester.pumpAndSettle();
  await binding.takeScreenshot(name);
}

const _fixture = {
  'schemaVersion': 3,
  'setups': {
    'a5f0c760-7346-11ef-89aa-5137c552c0bc': {
      'id': 'a5f0c760-7346-11ef-89aa-5137c552c0bc',
      'name': 'Hugene',
      'fork': {
        'airPressure': {'value': 70, 'unit': 'PSI'},
        'volumeSpacer': {'value': 1, 'unit': 'Spacers'},
        'sag': {'value': 20, 'unit': '%'},
        'lsr': {'value': 7, 'unit': 'Clicks'},
        'hsr': {'value': 6, 'unit': 'Clicks'},
        'lsc': {'value': 10, 'unit': 'Clicks'},
        'hsc': {'value': 7, 'unit': 'Clicks'},
      },
      'shock': {
        'airPressure': {'value': 168, 'unit': 'PSI'},
        'volumeSpacer': null,
        'sag': {'value': 27, 'unit': '%'},
        'lsr': {'value': 8, 'unit': 'Clicks'},
        'hsr': null,
        'lsc': {'value': 5, 'unit': 'Clicks'},
        'hsc': null,
      },
      'tyres': {'front': null, 'rear': null},
      'history': [
        {
          'id': 'a5f0c760-7346-11ef-89aa-000000000001',
          'changes': [],
          'date': '2024-09-15T11:41:14.071433',
          'comment': 'Setup creation',
          'isCreationEntry': true,
        },
      ],
    },
    'f65fdaf0-735b-11ef-8bca-39bc253932cf': {
      'id': 'f65fdaf0-735b-11ef-8bca-39bc253932cf',
      'name': 'Yeti',
      'fork': {
        'airPressure': {'value': 73, 'unit': 'PSI'},
        'volumeSpacer': {'value': 2, 'unit': 'Spacers'},
        'sag': {'value': 17, 'unit': '%'},
        'lsr': {'value': 7, 'unit': 'Clicks'},
        'hsr': {'value': 6, 'unit': 'Clicks'},
        'lsc': {'value': 19, 'unit': 'Clicks'},
        'hsc': {'value': 6, 'unit': 'Clicks'},
        'serialNumber': 'WB220A01234',
        'infoUrl': 'https://tech.ridefox.com/bike/service-procedures/2962/2025',
      },
      'shock': {
        'airPressure': {'value': 165, 'unit': 'PSI'},
        'volumeSpacer': null,
        'sag': {'value': 27, 'unit': '%'},
        'lsr': {'value': 8, 'unit': 'Clicks'},
        'hsr': null,
        'lsc': {'value': 8, 'unit': 'Clicks'},
        'hsc': null,
      },
      'tyres': {'front': null, 'rear': null},
      'history': [
        {
          'id': 'f65fdaf0-735b-11ef-8bca-000000000001',
          'changes': [],
          'date': '2024-09-15T14:13:48.447488',
          'comment': 'Setup creation',
          'isCreationEntry': true,
        },
        {
          'id': 'f65fdaf0-735b-11ef-8bca-000000000002',
          'changes': [
            {
              'suspensionType': 'shock',
              'settingType': 'airPressure',
              'oldValue': 168,
              'newValue': 165,
              'oldEnabled': null,
              'newEnabled': null,
            },
            {
              'suspensionType': 'shock',
              'settingType': 'lsc',
              'oldValue': 6,
              'newValue': 8,
              'oldEnabled': null,
              'newEnabled': null,
            },
          ],
          'date': '2024-09-15T14:14:19.148301',
          'comment': 'Less pressure, more compression',
        },
        {
          'id': 'f65fdaf0-735b-11ef-8bca-000000000003',
          'changes': [
            {
              'suspensionType': 'fork',
              'settingType': 'airPressure',
              'oldValue': 75,
              'newValue': 73,
              'oldEnabled': null,
              'newEnabled': null,
            },
            {
              'suspensionType': 'fork',
              'settingType': 'volumeSpacer',
              'oldValue': 1,
              'newValue': 2,
              'oldEnabled': null,
              'newEnabled': null,
            },
            {
              'suspensionType': 'fork',
              'settingType': 'lsc',
              'oldValue': 10,
              'newValue': 19,
              'oldEnabled': null,
              'newEnabled': null,
            },
          ],
          'date': '2024-09-15T14:15:02.565668',
          'comment': 'Results of bike park sessions in Verbier',
        },
      ],
    },
  },
};
