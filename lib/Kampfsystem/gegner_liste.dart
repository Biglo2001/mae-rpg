import 'gegner.dart';

// ✅ Klasse für die Gegner-Liste
class GegnerListe {
  final List<Gegner> _gegner = [];

  //Konstructor
  GegnerListe();

  // ✅ Getter für alle Gegner
  List<Gegner> get alleGegner => _gegner;

  // ✅ Einzelnen Gegner holen
  Gegner getGegner(int index) {
    return _gegner[index];
  }

  // ✅ Neuen Gegner hinzufügen
  void addGegner(Gegner gegner) {
    _gegner.add(gegner);
  }

  // ✅ toJson
  Map<String, dynamic> toJson() {
    return {
      'gegner': _gegner.map((g) => g.toJson()).toList(),
    };
  }

  // ✅ fromJson
  factory GegnerListe.fromJson(Map<String, dynamic> json) {
    final liste = GegnerListe();

    if (json['gegner'] != null) {
      for (final gegnerJson in json['gegner']) {
        liste.addGegner(
          Gegner.fromJson(
            Map<String, dynamic>.from(gegnerJson),
          ),
        );
      }
    }

    return liste;
  }
}