import 'field.dart';

class Tyres {
  Field? front;
  Field? rear;

  Tyres({this.front, this.rear});

  factory Tyres.fromJson(Map<String, dynamic>? json) {
    if (json == null) return Tyres();
    Field? parse(String key) {
      final raw = json[key];
      if (raw == null) return null;
      return Field.fromJson(raw as Map<String, dynamic>);
    }

    return Tyres(
      front: parse('front'),
      rear: parse('rear'),
    );
  }

  Map<String, dynamic> toJson() => {
        'front': front?.toJson(),
        'rear': rear?.toJson(),
      };

  Tyres clone() => Tyres(front: front, rear: rear);
}