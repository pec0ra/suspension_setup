
class Settings {
  int airPressure;
  int? volumeSpacer;
  int sag;
  int lsr;
  int? hsr;
  int lsc;
  int? hsc;

  Settings({
    required this.airPressure,
    this.volumeSpacer,
    required this.sag,
    required this.lsr,
    this.hsr,
    required this.lsc,
    this.hsc,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      airPressure: json['airPressure'],
      volumeSpacer: json['volumeSpacer'],
      sag: json['sag'],
      lsr: json['lsr'],
      hsr: json['hsr'],
      lsc: json['lsc'],
      hsc: json['hsc'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'airPressure': airPressure,
      'volumeSpacer': volumeSpacer,
      'sag': sag,
      'lsr': lsr,
      'hsr': hsr,
      'lsc': lsc,
      'hsc': hsc,
    };
  }

  factory Settings.getDefault() {
    return Settings(
      airPressure: 0,
      sag: 0,
      volumeSpacer: null,
      lsc: 0,
      hsc: null,
      lsr: 0,
      hsr: null,
    );
  }

  Settings clone() {
    return Settings(
      airPressure: airPressure,
      sag: sag,
      volumeSpacer: volumeSpacer,
      lsc: lsc,
      hsc: hsc,
      lsr: lsr,
      hsr: hsr,
    );
  }
}
