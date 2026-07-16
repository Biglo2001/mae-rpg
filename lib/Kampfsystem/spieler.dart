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

  String map;
  String playerlocation;

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

    // TODO: make dynamic and not hardcoded map
    this.map = 
    '''GRIDX 20 GRIDY 30
. . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . .
. . . O O O O O O O O O O O O O O . . .
. . O O P P P O O O O O O O O O O O . .
. . O P P P P P O O P F F O O F F O . .
. . P P P P P P P O F F F F F F F P . .
. . F F F P P P P F F F F F F F F P . .
. . O O P P P P F F F F F F F P P P . .
. . O M M P . . . F F F F F F P O O . .
. . F M P P P P F F F F F F F P O O . .
. . F F F M P P P F P F F F F F O O . .
. . F F M M M F P P O O O O O O O O . .
. . F F M M P P P P P O O O O O O O . .
. . F F P P P O P P P O O O O O O O . .
. . F P P P O O P O O O P O O O O O . .
. . P P P O O O P P P P . O O O O O . .
. . O O P O O O O P P M M O O O O O . .
. . O O O O O O O P P P M P O O O O . .
. . O O O O O O O P P P P P P O O O . .
. . O O O O O O O O P F P P M O O P . .
. . O O O O O O O O P P P P M O O O . .
. . O O O O O O O O O P P P O O O O . .
. . P P O O O O O O O P P M O O O O . .
. . P P P P P O O O O O O P O O O O . .
. . P P P P O O O O O O O O O O O O . .
. . P P M M M O O O O O O O O O O O . .
. . O O O O O O O O O O O O O O O O . .
. . . O O O O O O O O O O O O O O . . .
. . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . .
Legend:
P: plains
F: Forest
O: Ocean
M: Mountains''',
    this.playerlocation = '''GRIDX 20 GRIDY 30
. . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . .
. . . O O O O O O O O O O O O O O . . .
. . O O P P P O O O O O O O O O O O . .
. . O P P P P P O O P F F O O F F O . .
. . P P P P P P P O F F F F F F F P . .
. . F F F P P P P F F F F F F F F P . .
. . O O P P P P F F F F F F F P P P . .
. . O M M P . . . F F F F F F P O O . .
. . F M P P P P F F F F F F F P O O . .
. . F F F M P P P F P F F F F F O O . .
. . F F M M M F P P O O O O O O O O . .
. . F F M M P P X P P O O O O O O O . .
. . F F P P P O P P P O O O O O O O . .
. . F P P P O O P O O O P O O O O O . .
. . P P P O O O P P P P . O O O O O . .
. . O O P O O O O P P M M O O O O O . .
. . O O O O O O O P P P M P O O O O . .
. . O O O O O O O P P P P P P O O O . .
. . O O O O O O O O P F P P M O O P . .
. . O O O O O O O O P P P P M O O O . .
. . O O O O O O O O O P P P O O O O . .
. . P P O O O O O O O P P M O O O O . .
. . P P P P P O O O O O O P O O O O . .
. . P P P P O O O O O O O O O O O O . .
. . P P M M M O O O O O O O O O O O . .
. . O O O O O O O O O O O O O O O O . .
. . . O O O O O O O O O O O O O O . . .
. . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . .
Legend:
'X': player'''
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
      'map': map,
      'playerlocation': playerlocation,

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
      map: json['map'],
      playerlocation: json['playerlocation'],

    );
  }
}