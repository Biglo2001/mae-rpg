import 'attacken_liste.dart';
import 'item_liste.dart';

class Spieler {
  String name;
  String beschreibung;
  AttackenListe attacken;
  ItemListe items;

  int maxleben;
  int leben;

  int maxausdauer;
  int ausdauer;

  int ausdauerregeneration;
  int verteidigung;
  int geschwindigkeit;
  int staerke;
  int bisturn;
  bool verteidigt;

  Spieler({
    required this.name,
    required this.beschreibung,
    required this.attacken,
    required this.items,
    required this.maxleben,
    required this.leben,
    required this.maxausdauer,
    required this.ausdauer,
    required this.ausdauerregeneration,
    required this.verteidigung,
    required this.geschwindigkeit,
    required this.staerke,
    this.bisturn = 200,
    this.verteidigt = false,
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
      'bisturn': bisturn,
  
      'attacken': attacken.toJson()['attacken'],
      'items': items.toJson(),

      /*
      // Attacken
      'attacken': attacken.alleAttacken.map((a) => {
            'name': a.name,
            'kosten': a.kosten,
            'kraft': a.kraft,
            'aufgegner': a.aufgegner,
            'aoe': a.aoe,
          }).toList(),

      // Items
      'items': items.alleItems.map((i) => {
            'name': i.name,
            'beschreibung': i.beschreibung,
            'kraft': i.kraft,
            'aufgegner': i.aufgegner,
            'aoe': i.aoe,
          }).toList(),
          */
    };
  }
  //FromJson
  factory Spieler.fromJson(Map<String, dynamic> json) {
    return Spieler(
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
      bisturn: json['bisturn'],

      attacken: AttackenListe.fromJson(json['attacken']),
      items: ItemListe.fromJson(json['items']),

    );
  }
}