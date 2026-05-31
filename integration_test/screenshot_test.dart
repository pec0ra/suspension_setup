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

  tester
      .widget<ListTile>(
        find.ancestor(of: find.text('Yeti'), matching: find.byType(ListTile)),
      )
      .onTap!();
  await tester.pumpAndSettle();
  await _screenshot(binding, tester, '${idx(1)}_detail$suffix');

  await Scrollable.ensureVisible(
    tester.element(find.text('History')),
    alignment: 0.0,
    duration: Duration.zero,
  );
  await tester.pumpAndSettle();
  await _screenshot(binding, tester, '${idx(2)}_history$suffix');

  await tester.tap(find.byIcon(Icons.tune));
  await tester.pumpAndSettle();
  await _screenshot(binding, tester, '${idx(3)}_edit$suffix');

  tester
      .state<NavigatorState>(find.byType(Navigator).first)
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
  'schemaVersion': 4,
  'setups': {
    'a5f0c760-7346-11ef-89aa-5137c552c0bc': {
      'id': 'a5f0c760-7346-11ef-89aa-5137c552c0bc',
      'name': 'Hugene',
      'fork': {
        'fields': [
          {
            'id': 'hf-air',
            'name': 'Air Pressure',
            'unit': 'PSI',
            'value': 70,
            'deleted': false
          },
          {
            'id': 'hf-sag',
            'name': 'Sag',
            'unit': '%',
            'value': 20,
            'deleted': false
          },
          {
            'id': 'hf-vol',
            'name': 'Volume',
            'unit': 'Spacers',
            'value': 1,
            'deleted': false
          },
          {
            'id': 'hf-lsc',
            'name': 'Low Speed Compression',
            'unit': 'Clicks',
            'value': 10,
            'deleted': false
          },
          {
            'id': 'hf-hsc',
            'name': 'High Speed Compression',
            'unit': 'Clicks',
            'value': 7,
            'deleted': false
          },
          {
            'id': 'hf-lsr',
            'name': 'Low Speed Rebound',
            'unit': 'Clicks',
            'value': 7,
            'deleted': false
          },
          {
            'id': 'hf-hsr',
            'name': 'High Speed Rebound',
            'unit': 'Clicks',
            'value': 6,
            'deleted': false
          },
        ],
        'layout': [
          ['hf-air', 'hf-sag', 'hf-vol'],
          ['hf-lsc', 'hf-hsc'],
          ['hf-lsr', 'hf-hsr'],
        ],
        'serialNumber': null,
        'infoUrl': null,
      },
      'shock': {
        'fields': [
          {
            'id': 'hs-air',
            'name': 'Air Pressure',
            'unit': 'PSI',
            'value': 168,
            'deleted': false
          },
          {
            'id': 'hs-sag',
            'name': 'Sag',
            'unit': '%',
            'value': 27,
            'deleted': false
          },
          {
            'id': 'hs-vol',
            'name': 'Volume',
            'unit': 'Spacers',
            'value': null,
            'deleted': true
          },
          {
            'id': 'hs-lsc',
            'name': 'Low Speed Compression',
            'unit': 'Clicks',
            'value': 5,
            'deleted': false
          },
          {
            'id': 'hs-hsc',
            'name': 'High Speed Compression',
            'unit': 'Clicks',
            'value': null,
            'deleted': true
          },
          {
            'id': 'hs-lsr',
            'name': 'Low Speed Rebound',
            'unit': 'Clicks',
            'value': 8,
            'deleted': false
          },
          {
            'id': 'hs-hsr',
            'name': 'High Speed Rebound',
            'unit': 'Clicks',
            'value': null,
            'deleted': true
          },
        ],
        'layout': [
          ['hs-air', 'hs-sag'],
          ['hs-lsc'],
          ['hs-lsr'],
        ],
        'serialNumber': null,
        'infoUrl': null,
      },
      'tyres': {
        'fields': [
          {
            'id': 'ht-front',
            'name': 'Front Tyre Pressure',
            'unit': 'PSI',
            'value': null,
            'deleted': true
          },
          {
            'id': 'ht-rear',
            'name': 'Rear Tyre Pressure',
            'unit': 'PSI',
            'value': null,
            'deleted': true
          },
        ],
        'layout': [],
        'serialNumber': null,
        'infoUrl': null,
      },
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
        'fields': [
          {
            'id': 'yf-air',
            'name': 'Air Pressure',
            'unit': 'PSI',
            'value': 73,
            'deleted': false
          },
          {
            'id': 'yf-sag',
            'name': 'Sag',
            'unit': '%',
            'value': 17,
            'deleted': false
          },
          {
            'id': 'yf-vol',
            'name': 'Volume',
            'unit': 'Spacers',
            'value': 2,
            'deleted': false
          },
          {
            'id': 'yf-lsc',
            'name': 'Low Speed Compression',
            'unit': 'Clicks',
            'value': 19,
            'deleted': false
          },
          {
            'id': 'yf-hsc',
            'name': 'High Speed Compression',
            'unit': 'Clicks',
            'value': 6,
            'deleted': false
          },
          {
            'id': 'yf-lsr',
            'name': 'Low Speed Rebound',
            'unit': 'Clicks',
            'value': 7,
            'deleted': false
          },
          {
            'id': 'yf-hsr',
            'name': 'High Speed Rebound',
            'unit': 'Clicks',
            'value': 6,
            'deleted': false
          },
        ],
        'layout': [
          ['yf-air', 'yf-sag', 'yf-vol'],
          ['yf-lsc', 'yf-hsc'],
          ['yf-lsr', 'yf-hsr'],
        ],
        'serialNumber': 'WB220A01234',
        'infoUrl': 'https://tech.ridefox.com/bike/service-procedures/2962/2025',
      },
      'shock': {
        'fields': [
          {
            'id': 'ys-air',
            'name': 'Air Pressure',
            'unit': 'PSI',
            'value': 165,
            'deleted': false
          },
          {
            'id': 'ys-sag',
            'name': 'Sag',
            'unit': '%',
            'value': 27,
            'deleted': false
          },
          {
            'id': 'ys-vol',
            'name': 'Volume',
            'unit': 'Spacers',
            'value': null,
            'deleted': true
          },
          {
            'id': 'ys-lsc',
            'name': 'Low Speed Compression',
            'unit': 'Clicks',
            'value': 8,
            'deleted': false
          },
          {
            'id': 'ys-hsc',
            'name': 'High Speed Compression',
            'unit': 'Clicks',
            'value': null,
            'deleted': true
          },
          {
            'id': 'ys-lsr',
            'name': 'Low Speed Rebound',
            'unit': 'Clicks',
            'value': 8,
            'deleted': false
          },
          {
            'id': 'ys-hsr',
            'name': 'High Speed Rebound',
            'unit': 'Clicks',
            'value': null,
            'deleted': true
          },
        ],
        'layout': [
          ['ys-air', 'ys-sag'],
          ['ys-lsc'],
          ['ys-lsr'],
        ],
        'serialNumber': null,
        'infoUrl': null,
      },
      'tyres': {
        'fields': [
          {
            'id': 'yt-front',
            'name': 'Front Tyre Pressure',
            'unit': 'PSI',
            'value': null,
            'deleted': true
          },
          {
            'id': 'yt-rear',
            'name': 'Rear Tyre Pressure',
            'unit': 'PSI',
            'value': null,
            'deleted': true
          },
        ],
        'layout': [],
        'serialNumber': null,
        'infoUrl': null,
      },
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
              'fieldId': 'ys-air',
              'oldValue': 168,
              'newValue': 165,
              'oldEnabled': null,
              'newEnabled': null,
            },
            {
              'suspensionType': 'shock',
              'fieldId': 'ys-lsc',
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
              'fieldId': 'yf-air',
              'oldValue': 75,
              'newValue': 73,
              'oldEnabled': null,
              'newEnabled': null,
            },
            {
              'suspensionType': 'fork',
              'fieldId': 'yf-vol',
              'oldValue': 1,
              'newValue': 2,
              'oldEnabled': null,
              'newEnabled': null,
            },
            {
              'suspensionType': 'fork',
              'fieldId': 'yf-lsc',
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
