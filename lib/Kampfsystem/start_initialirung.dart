import 'attacke.dart';
import 'attacken_liste.dart';
import 'item.dart';
import 'item_liste.dart';
import 'spieler.dart';

class StartInitialisierung {

  // ✅ Spieler erstellen
  static Spieler erstelleSpieler(String spielerName) {
    // Attacken
    AttackenListe attacken = AttackenListe();
    attacken.addAttacke(Attacke(
      name: "Schwertangriff",
      beschreibung: "Ein schneller Nahkampfangriff",
      kraft: 1.0,
      kosten: 0,
      aufgegner: true,
      aoe: false,
    ));
    attacken.addAttacke(Attacke(
      name: "Feuerball",
      beschreibung: "Magischer Angriff auf mehrere Gegner",
      kraft: 0.7,
      kosten: 5,
      aufgegner: true,
      aoe: true,
    ));
    attacken.addAttacke(Attacke(
      name: "Heilung",
      beschreibung: "Heilt Lebenspunkte",
      kraft: -0.7,
      kosten: 4,
      aufgegner: false,
      aoe: false,
    ));
    attacken.addAttacke(Attacke(
      name: "OP Developer Beam",
      beschreibung: "Die Kraft der Entwickler",
      kraft: 100.0,
      kosten: 0,
      aufgegner: true,
      aoe: true,
    ));

    // Items
    ItemListe items = ItemListe();
    items.addItem(Item(
      name: "Heiltrank",
      beschreibung: "Stellt Leben wieder her",
      kraft: 2,
      aufgegner: false,
      aoe: false,
    ));
    items.addItem(Item(
      name: "Bombe",
      beschreibung: "Verursacht Schaden an allen Gegnern",
      kraft: 3,
      aufgegner: true,
      aoe: true,
    ));
    items.addItem(Item(
      name: "Dolch",
      beschreibung: "Ein schneller Stich",
      kraft: 5,
      aufgegner: true,
      aoe: false,
    ));

    // Spieler
    return Spieler(
      name: spielerName,
      beschreibung: "Ein mutiger Abenteurer",
      attacken: attacken,
      items: items,
      maxleben: 30,
      leben: 30,
      maxausdauer: 20,
      ausdauer: 20,
      ausdauerregeneration: 3,
      verteidigung: 5,
      geschwindigkeit: 5,
      staerke: 5
    );
  }
}