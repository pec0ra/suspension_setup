import 'package:suspension_setup/models/settings.dart';
import 'package:suspension_setup/models/tyres.dart';
import 'package:uuid/uuid.dart';

import 'setting_change.dart';

class Setup {
  final String id;
  String name;
  final Settings fork;
  final Settings shock;
  final Tyres tyres;
  final List<SettingChanges> history;

  Setup({
    required this.id,
    required this.name,
    required this.fork,
    required this.shock,
    required this.tyres,
    required this.history,
  });

  factory Setup.fromJson(Map<String, dynamic> json) {
    return Setup(
      id: json['id'],
      name: json['name'],
      fork: Settings.fromJson(json['fork']),
      shock: Settings.fromJson(json['shock']),
      tyres: Tyres.fromJson(json['tyres'] as Map<String, dynamic>?),
      history: List<SettingChanges>.from(
          json['history'].map((e) => SettingChanges.fromJson(e))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'fork': fork.toJson(),
      'shock': shock.toJson(),
      'tyres': tyres.toJson(),
      'history': history.map((e) => e.toJson()).toList()
    };
  }

  factory Setup.getDefault() {
    return Setup(
      id: const Uuid().v1(),
      name: '',
      fork: Settings.getDefault(),
      shock: Settings.getDefault(),
      tyres: Tyres(),
      history: [],
    );
  }

  Setup clone(bool includeHistory) {
    return Setup(
      id: const Uuid().v1(),
      name: name,
      fork: fork.clone(),
      shock: shock.clone(),
      tyres: tyres.clone(),
      history: includeHistory ? history.map((e) => e.clone()).toList() : [],
    );
  }
}
