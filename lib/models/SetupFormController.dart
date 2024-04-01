import 'package:flutter/widgets.dart';
import 'package:suspension_setup/models/settings.dart';

import 'setup.dart';

class SetupFormController {

  SetupFormController(Setup? setup) {
    name = TextEditingController(text: setup?.name);
    fork = SettingsFormController(setup?.fork);
    shock = SettingsFormController(setup?.shock);
  }

  late TextEditingController name;
  late SettingsFormController fork;
  late SettingsFormController shock;

  void dispose() {
    name.dispose();
    fork.dispose();
    shock.dispose();
  }
}

class SettingsFormController {
  late TextEditingController airPressure;
  late TextEditingController volumeSpacer;
  late TextEditingController sag;
  late TextEditingController lsr;
  late TextEditingController hsr;
  late TextEditingController lsc;
  late TextEditingController hsc;

  SettingsFormController(Settings? settings) {
    airPressure = TextEditingController(text: settings?.airPressure.toString());
    volumeSpacer = TextEditingController(text: settings?.volumeSpacer?.toString() ?? '');
    sag = TextEditingController(text: settings?.sag.toString());
    lsr = TextEditingController(text: settings?.lsr.toString());
    hsr = TextEditingController(text: settings?.hsr?.toString() ?? '');
    lsc = TextEditingController(text: settings?.lsc.toString());
    hsc = TextEditingController(text: settings?.hsc?.toString() ?? '');
  }

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