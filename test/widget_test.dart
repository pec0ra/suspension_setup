import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:suspension_setup/home_page.dart';
import 'package:suspension_setup/setup_storage_model.dart';

class _FakeSetupStorageModel extends SetupStorageModel {
  @override
  Future<void> initSetups() async {}
}

void main() {
  testWidgets('HomePage renders without crashing and shows empty state',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<SetupStorageModel>(
        create: (_) => _FakeSetupStorageModel(),
        child: const MaterialApp(home: HomePage(title: 'Suspension Setup')),
      ),
    );
    await tester.pump();
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('You have no setup yet'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}