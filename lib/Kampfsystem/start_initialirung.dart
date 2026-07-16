import 'attacke.dart';
import 'attacken_liste.dart';
import 'item.dart';
import 'item_liste.dart';
import 'spieler.dart';

class StartInitialisierung {
  // ✅ Spieler erstellen
  static Spieler erstelleSpieler(String spielerName, String setting) {
    AttackenListe attacken = AttackenListe();
    ItemListe items = ItemListe();

    String beschreibung;

    switch (setting) {
      case "Mittelalter":
        beschreibung = "Ein mutiger Ritter auf der Suche nach Ruhm";

        // Attacken
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
          beschreibung: "Ein heilender Zauber",
          kraft: -0.7,
          kosten: 4,
          aufgegner: false,
          aoe: false,
        ));

        // Items
        items.addItem(Item(
          name: "Heiltrank",
          beschreibung: "Stellt Leben wieder her",
          kraft: 2,
          aufgegner: false,
          aoe: false,
        ));
        items.addItem(Item(
          name: "Bombe",
          beschreibung: "Eine explosive Alchemistenbombe",
          kraft: 3,
          aufgegner: true,
          aoe: true,
        ));
        items.addItem(Item(
          name: "Dolch",
          beschreibung: "Ein schneller Stich mit einem Dolch",
          kraft: 5,
          aufgegner: true,
          aoe: false,
        ));
        break;

      case "Sci-Fi":
        beschreibung = "Ein Elite-Soldat aus einer fernen Zukunft";

        // Attacken
        attacken.addAttacke(Attacke(
          name: "Laserschuss",
          beschreibung: "Ein präziser Schuss aus einer Energiewaffe",
          kraft: 1.0,
          kosten: 0,
          aufgegner: true,
          aoe: false,
        ));
        attacken.addAttacke(Attacke(
          name: "Plasmaexplosion",
          beschreibung: "Ein Energieangriff auf mehrere Gegner",
          kraft: 0.7,
          kosten: 5,
          aufgegner: true,
          aoe: true,
        ));
        attacken.addAttacke(Attacke(
          name: "Nanoreparatur",
          beschreibung: "Nanobots stellen Gesundheit wieder her",
          kraft: -0.7,
          kosten: 4,
          aufgegner: false,
          aoe: false,
        ));

        // Items
        items.addItem(Item(
          name: "Med-Kit",
          beschreibung: "Moderner medizinischer Notfallkoffer",
          kraft: 2,
          aufgegner: false,
          aoe: false,
        ));
        items.addItem(Item(
          name: "Plasmagranate",
          beschreibung: "Verursacht Schaden an allen Gegnern",
          kraft: 3,
          aufgegner: true,
          aoe: true,
        ));
        items.addItem(Item(
          name: "Energieklinge",
          beschreibung: "Eine kompakte Klinge aus reinem Plasma",
          kraft: 5,
          aufgegner: true,
          aoe: false,
        ));
        break;

      case "Piraten":
        beschreibung = "Ein gefürchteter Pirat der sieben Weltmeere";

        // Attacken
        attacken.addAttacke(Attacke(
          name: "Säbelhieb",
          beschreibung: "Ein schneller Angriff mit dem Säbel",
          kraft: 1.0,
          kosten: 0,
          aufgegner: true,
          aoe: false,
        ));
        attacken.addAttacke(Attacke(
          name: "Kanonensalve",
          beschreibung: "Eine Salve trifft mehrere Gegner",
          kraft: 0.7,
          kosten: 5,
          aufgegner: true,
          aoe: true,
        ));
        attacken.addAttacke(Attacke(
          name: "Rum-Pause",
          beschreibung: "Ein kräftiger Schluck Rum heilt Wunden",
          kraft: -0.7,
          kosten: 4,
          aufgegner: false,
          aoe: false,
        ));

        // Items
        items.addItem(Item(
          name: "Rumflasche",
          beschreibung: "Stellt Leben wieder her",
          kraft: 2,
          aufgegner: false,
          aoe: false,
        ));
        items.addItem(Item(
          name: "Schwarzpulverbombe",
          beschreibung: "Verursacht Schaden an allen Gegnern",
          kraft: 3,
          aufgegner: true,
          aoe: true,
        ));
        items.addItem(Item(
          name: "Enterhaken",
          beschreibung: "Ein harter Treffer aus kurzer Distanz",
          kraft: 5,
          aufgegner: true,
          aoe: false,
        ));
        break;

      default:
        beschreibung = "Ein mutiger Abenteurer";

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
    }

    // Immer vorhanden
    attacken.addAttacke(Attacke(
      name: "OP Developer Beam",
      beschreibung: "Die Kraft der Entwickler",
      kraft: 100.0,
      kosten: 0,
      aufgegner: true,
      aoe: true,
    ));

    return Spieler(
      name: spielerName,
      beschreibung: beschreibung,
      attacken: attacken,
      items: items,
      maxleben: 30,
      leben: 30,
      maxausdauer: 20,
      ausdauer: 20,
      ausdauerregeneration: 3,
      verteidigung: 5,
      geschwindigkeit: 5,
      staerke: 5,
    );
  }
}