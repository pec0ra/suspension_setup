import 'package:flutter/widgets.dart';
import 'package:suspension_setup/models/settings.dart';

import 'setup.dart';

class SetupFormController {
  SetupFormController(Setup? setup)
      : name = TextEditingController(text: setup?.name),
        fork = SettingsFormController(setup?.fork),
        shock = SettingsFormController(setup?.shock);

  final TextEditingController name;
  final SettingsFormController fork;
  final SettingsFormController shock;

  void dispose() {
    name.dispose();
    fork.dispose();
    shock.dispose();
  }
}

class SettingsFormController {
  SettingsFormController(Settings? settings)
      : airPressure = TextEditingController(text: settings?.airPressure.toString()),
        volumeSpacer = TextEditingController(text: settings?.volumeSpacer?.toString() ?? ''),
        sag = TextEditingController(text: settings?.sag.toString()),
        lsr = TextEditingController(text: settings?.lsr.toString()),
        hsr = TextEditingController(text: settings?.hsr?.toString() ?? ''),
        lsc = TextEditingController(text: settings?.lsc.toString()),
        hsc = TextEditingController(text: settings?.hsc?.toString() ?? '');

  final TextEditingController airPressure;
  final TextEditingController volumeSpacer;
  final TextEditingController sag;
  final TextEditingController lsr;
  final TextEditingController hsr;
  final TextEditingController lsc;
  final TextEditingController hsc;

  void dispose() {
    airPressure.dispose();
    volumeSpacer.dispose();
    sag.dispose();
    lsr.dispose();
    hsr.dispose();
    lsc.dispose();
    hsc.dispose();
  }
}