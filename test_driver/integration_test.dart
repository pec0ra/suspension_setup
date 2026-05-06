import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
      responseDataCallback: (Map<String, dynamic>? data) async {
        if (data == null) return;
        final screenshots = data['screenshots'] as List<dynamic>?;
        if (screenshots == null) return;
        final dir = Directory('screenshots');
        await dir.create(recursive: true);
        for (final screenshot in screenshots) {
          final map = screenshot as Map<String, dynamic>;
          final name = map['screenshotName'] as String;
          final bytes = base64Decode(map['bytes'] as String);
          final file = File('screenshots/$name.png');
          await file.writeAsBytes(bytes);
          print('Saved: ${file.path}');
        }
      },
    );