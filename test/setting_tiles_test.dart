import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suspension_setup/models/SetupFormController.dart';
import 'package:suspension_setup/setting_tiles.dart';

Widget _harness(GlobalKey<FormState> key, FieldFormController controller) {
  return MaterialApp(
    home: Scaffold(
      body: Form(
        key: key,
        child: FieldEditCard(name: 'Air Pressure', controller: controller),
      ),
    ),
  );
}

void main() {
  group('FieldEditCard decimal input', () {
    testWidgets('accepts a decimal value and parses it via num.parse',
        (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller =
          FieldFormController(enabled: true, value: null, unit: 'PSI');
      addTearDown(controller.dispose);

      await tester.pumpWidget(_harness(formKey, controller));
      await tester.enterText(find.byType(TextFormField), '28.5');
      await tester.pump();

      expect(formKey.currentState!.validate(), isTrue);
      expect(num.parse(controller.value.text), 28.5);
    });

    testWidgets('validator rejects malformed numbers', (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller =
          FieldFormController(enabled: true, value: null, unit: 'PSI');
      addTearDown(controller.dispose);

      await tester.pumpWidget(_harness(formKey, controller));

      await tester.enterText(find.byType(TextFormField), '1.2.3');
      await tester.pump();
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Invalid number'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '.');
      await tester.pump();
      expect(formKey.currentState!.validate(), isFalse);
    });
  });
}