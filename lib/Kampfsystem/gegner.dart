import 'attacken_liste.dart';

class Gegner {
  String name;
  String beschreibung;
  AttackenListe attacken;

  int maxleben;
  int leben;

  int maxausdauer;
  int ausdauer;

  int ausdauerregeneration;
  int verteidigung;
  int geschwindigkeit;
  int staerke;
  int bisturn;

  Gegner({
    required this.name,
    required this.beschreibung,
    required this.attacken,
    required this.maxleben,
    required this.leben,
    required this.maxausdauer,
    required this.ausdauer,
    required this.ausdauerregeneration,
    required this.verteidigung,
    required this.geschwindigkeit,
    required this.staerke,
    this.bisturn = 200
  });

  void regenerierAusdauer() {
    if(ausdauer + ausdauerregeneration > maxausdauer) {
      ausdauer = maxausdauer;
    } else {
      ausdauer += ausdauerregeneration;
    }
  }

  // ✅ Objekt in JSON umwandeln
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'beschreibung': beschreibung,
      'maxleben': maxleben,
      'leben': leben,
      'maxausdauer': maxausdauer,
      'ausdauer': ausdauer,
      'ausdauerregeneration': ausdauerregeneration,
      'verteidigung': verteidigung,
      'geschwindigkeit': geschwindigkeit,
      'stärke': staerke,
      'attacken': attacken.alleAttacken.map((a) => {
            'name': a.name,
            'kosten': a.kosten,
            'kraft': a.kraft,
            'aufgegner': a.aufgegner,
            'aoe': a.aoe,
          }).toList(),
    };
  }

  

factory Gegner.fromJson(Map<String, dynamic> json) {
  return Gegner(
    name: json['name'],
    beschreibung: json['beschreibung'],
    maxleben: json['maxleben'],
    leben: json['leben'],
    maxausdauer: json['maxausdauer'],
    ausdauer: json['ausdauer'],
    ausdauerregeneration: json['ausdauerregeneration'],
    verteidigung: json['verteidigung'],
    geschwindigkeit: json['geschwindigkeit'],
    staerke: json['stärke'],
    attacken: AttackenListe.fromJson(
      json['attacken'] as List<dynamic>,
    ),

  );
}


}