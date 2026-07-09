class Attacke {
  final String name;
  final String beschreibung;
  final double kraft;
  final int kosten;
  final bool aufgegner;
  final bool aoe;

  Attacke({
    required this.name,
    required this.beschreibung,
    required this.kraft,
    required this.kosten,
    required this.aufgegner,
    required this.aoe
  });

  // ✅ toJson Funktion
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'beschriebung': beschreibung,
      'kraft': kraft,
      'kosten': kosten,
      'aufgegner': aufgegner,
      'aoe': aoe
    };
  }
  //From Json
  factory Attacke.fromJson(Map<String, dynamic> json) {
    return Attacke(
      name: json['name'],
      beschreibung: json['beschreibung'] ?? '',
      kraft: json['kraft'],
      kosten: json['kosten'],
      aufgegner: json['aufgegner'],
      aoe: json['aoe'],
    );
  }
}
