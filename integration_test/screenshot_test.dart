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

    await _screenshot(binding, tester, '01_home');

    await tester.tap(find.text('Yeti'));
    await tester.pumpAndSettle();
    await _screenshot(binding, tester, '02_detail');

    await Scrollable.ensureVisible(
      tester.element(find.text('History')),
      alignment: 0.0,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();
    await _screenshot(binding, tester, '03_history');

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    await _screenshot(binding, tester, '04_edit');
  });
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

// demo.json data migrated to schema v2
const _fixture = {
  'schemaVersion': 2,
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
          'changes': [],
          'date': '2024-09-15T11:41:14.071433',
          'comment': 'Setup creation',
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
          'changes': [],
          'date': '2024-09-15T14:13:48.447488',
          'comment': 'Setup creation',
        },
        {
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
