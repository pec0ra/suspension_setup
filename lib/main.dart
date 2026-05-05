import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suspension_setup/setup_storage_model.dart';

import 'home_page.dart';

void main() {
  runApp(ChangeNotifierProvider(
    create: (context) => SetupStorageModel(),
    child: const SuspensionSetupApp(),
  ));
}

class SuspensionSetupApp extends StatelessWidget {
  const SuspensionSetupApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff88a6c3), secondary: const Color(0xffff954f), primaryContainer: const Color(0xffc8d8e8), onPrimaryContainer: const Color(0xff1c2e3c)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(brightness: Brightness.dark, seedColor: const Color(0xff88a6c3), secondary: const Color(0xffff6600), surface: const Color(0xff111111), primaryContainer: const Color(0xff4c5b6a), onPrimaryContainer: const Color(0xffe8eef4)),
        useMaterial3: true,
      ),
      home: const HomePage(
        title: 'Suspension Setup',
      ),
    );
  }
}
