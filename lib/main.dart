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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff13a2dc), secondary: const Color(0xffff6600), tertiary: const Color(0xff13a2dc),),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(brightness: Brightness.dark, seedColor: const Color(0xff13a2dc), secondary: const Color(0xffff6600), background: const Color(0xff111111), tertiary: const Color(0xff13a2dc).withOpacity(0.4)),
        useMaterial3: true,
      ),
      home: const HomePage(
        title: 'Suspension Setup',
      ),
    );
  }
}
