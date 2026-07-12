import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'attacke.dart';
import 'dart:async';
import 'spieler.dart';
import 'gegner.dart';
import 'item.dart';
import 'gegner_liste.dart';
import 'chat_bot.dart';

class GameLogic extends ChangeNotifier {

  List<dynamic> teilnehmer = [];
  List<Gegner> kampfGegner = [];
  List<String> combatLog = [];
  Spieler spieler;
  GameSettings settings;
  String cleanAnswer;
  bool imKampf = false;
  Completer<void>? _spielerCompleter;
  final chatbot = Chatbot();
  bool isSpielerAmZug = false;

 
  GameLogic({
    required this.spieler,
    required this.settings,
    required this.cleanAnswer
  });


  //Navigations variablen
  Function(Spieler)? onLevelUp;
  VoidCallback? onZurueckZumChatEntkommen;
  VoidCallback? onZurueckZumChatVerloren;
  


  //erstelle Die gegner
   Future<void> gegnerInit() async {

    final gegnerListe = await chatbot.erstelleKampfgegner(spieler.toJson().toString(), cleanAnswer, settings);
    //Übergib die erstellten gegner
    combatStart(
      gegnerListe: gegnerListe,
    );
  }

  /// ✅ Startet den Kampf und erstellt eine Teilnehmerliste
  void combatStart({
    required GegnerListe? gegnerListe,
  }) {

    //Vorherigen Kampf löschen
    teilnehmer.clear();
    kampfGegner.clear();
    combatLog.clear();

    // Spieler hinzufügen
    teilnehmer.add(spieler);

    // Alle Gegner hinzufügen
    if (gegnerListe != null) {
      for (Gegner gegner in gegnerListe.alleGegner) {
        teilnehmer.add(gegner);
        kampfGegner.add(gegner);
      }
      turnSystem();
    } else {
      onZurueckZumChatEntkommen?.call();
    }

  }

  //turnsystem
  Future<void> turnSystem() async{
    if (imKampf) return; // ✅ verhindert mehrfaches Starten
    imKampf = true;

    while (imKampf) {
      for (var t in teilnehmer) {
        // Geschwindigkeit abziehen
        t.bisturn -= t.geschwindigkeit;
        if(t is Gegner && !kampfGegner.contains(t)) continue; //überspring tote gegner
        // Prüfen ob jemand dran ist
        if (t.bisturn <= 0) {
          // bisturn zurücksetzen
          t.bisturn = 200;

          // ✅ Spieler oder Gegner unterscheiden
          if (t is Spieler) {
            t.verteidigt = false;
            t.regenerierAusdauer();
            combatLog.add("===== Spieler =====");
            notifyListeners();
            await spielerTurn();

          } else if (t is Gegner) {
            t.regenerierAusdauer();
            combatLog.add("===== ${t.name} =====");
            notifyListeners();
            await gegnerTurn(t);
          }
        }
      }

    // kleiner delay damit CPU nicht stirbt
    await Future.delayed(Duration(milliseconds: 10));
    }
  }

  
  Future<void> gegnerTurn(Gegner gegner) async{
    Random random = Random();

    // Liste aller möglichen Angriffe (genug Ausdauer)
    var moeglicheAttacken = gegner.attacken.alleAttacken
        .where((a) => a.kosten <= gegner.ausdauer)
        .toList();

    // Variable für gewählten Angriff
    Attacke? gewaehlterAngriff;

    if (moeglicheAttacken.isNotEmpty) {
      // Zufälligen Angriff auswählen
      gewaehlterAngriff =
          moeglicheAttacken[random.nextInt(moeglicheAttacken.length)];
    } else {// Kein Angriff möglich

      //narchicht warum gegner aussetzt
      combatLog.add(await promptKeineAusdauer(gegner));

      notifyListeners();
      return;
    }

    //wenn Spieler angegriffen wird
    if (gewaehlterAngriff.aufgegner) {
      var angriffSchaden = berechneSchaden(gewaehlterAngriff.kraft * gegner.staerke, spieler.verteidigung, spieler.verteidigt);

      //CombatLog massage KI generiert
      combatLog.add(await promptGegnerSchadenAnSpieler(gegner, gewaehlterAngriff, angriffSchaden));
      notifyListeners();

      if(spieler.leben - angriffSchaden <= 0) {
        combatEnde(2);
      } else { //Spieler überlebt
          spieler.leben -= angriffSchaden;
          gegner.ausdauer -= gewaehlterAngriff.kosten;
      }
      notifyListeners();
      return;
    } else {
      //wenn es Alle Gegner betrifft
      if(gewaehlterAngriff.aoe) {
        
        combatLog.add(await promptGegnerHeiltAlleGegner(gegner, gewaehlterAngriff));

        for(Gegner g in kampfGegner) {
          if(g.leben - (gewaehlterAngriff.kraft * gegner.staerke).round() >= g.maxleben) {
            g.leben = g.maxleben;
          } else {
            g.leben -= (gewaehlterAngriff.kraft * gegner.staerke).round();
          }
        }

        gegner.ausdauer -= gewaehlterAngriff.kosten;
        notifyListeners();
        return;

      } else {
          //hilfsvariabel
          Gegner schwaechster = kampfGegner[0];
          //Durchlaufe und finde gegener mit wenigsten leben
          for (var gegner in kampfGegner) {
            if (gegner.leben < schwaechster.leben) {
              schwaechster = gegner;
            }
          }

          combatLog.add(await promptGegnerHeiltGegner(gegner, schwaechster, gewaehlterAngriff));

          //heile schwächsten Gegner
          if(schwaechster.leben - (gewaehlterAngriff.kraft * gegner.staerke).round() >= schwaechster.maxleben) {
            schwaechster.leben = schwaechster.maxleben;
          } else {
            schwaechster.leben -= (gewaehlterAngriff.kraft * gegner.staerke).round();
          }
           gegner.ausdauer -= gewaehlterAngriff.kosten;
          notifyListeners();
          return;
      }
    }
  }
  
  //Spielerturn
  Future<void> spielerTurn() async {
    isSpielerAmZug = true;
    notifyListeners();

    _spielerCompleter = Completer<void>();
    await _spielerCompleter!.future;

    isSpielerAmZug = false;
    notifyListeners();
  }
  
  //Spieler hat aktion ausgewählt
  void beendeSpielerZug() {
    if (_spielerCompleter != null && !_spielerCompleter!.isCompleted) {
      _spielerCompleter!.complete();
    }
  }

  void spielerAttackiertGegner(Gegner gegner, Attacke attacke) async {
    int schaden = berechneSchaden(attacke.kraft*spieler.staerke, gegner.verteidigung, false);

    combatLog.add(await promptSpielerSchadenAnGegner(gegner, attacke, schaden));
    notifyListeners();

    if(gegner.leben - schaden <= 0) { //gegner stierbt
      kampfGegner.remove(gegner);
      combatLog.add(await promptGegnerStirbtDurchAttacke(gegner, attacke, schaden));
      notifyListeners();

      if(kampfGegner.isEmpty) {
        combatEnde(0);
        return;
      }
    } else { //Gegner überlebt
      gegner.leben -= schaden;
    }
    notifyListeners();
    spieler.ausdauer -= attacke.kosten; 
    beendeSpielerZug();
  }

  void spielerAttackiertAlleGegner(Attacke attacke) async{
    
    combatLog.add(await promptSpielerSchadenAnAlleGegner(attacke));
    notifyListeners();

    for (Gegner gegner in List<Gegner>.from(kampfGegner)) {
      int schaden = berechneSchaden(
        attacke.kraft * spieler.staerke,
        gegner.verteidigung,
        false,
      );

      if (gegner.leben - schaden <= 0) {
        kampfGegner.remove(gegner);

        combatLog.add(
          await promptGegnerStirbtDurchAttacke(
            gegner,
            attacke,
            schaden,
          ),
        );

        notifyListeners();

        if (kampfGegner.isEmpty) {
          combatEnde(0);
          return;
        }
      } else {
        gegner.leben -= schaden;
      }
    }

    spieler.ausdauer -= attacke.kosten;
    beendeSpielerZug();
  }

  void spielerHeiltSich(Attacke attacke) async{

    combatLog.add(await promptSpielerHeiltSich(attacke));
    notifyListeners();
    if(spieler.leben - (attacke.kraft*spieler.staerke).round() > spieler.maxleben) {
      spieler.leben = spieler.maxleben;
    } else {
      spieler.leben -= (attacke.kraft*spieler.staerke).round();
    }
    spieler.ausdauer -= attacke.kosten;
    beendeSpielerZug();
  }

  void spielerNutztItemAufGegner(Item item, Gegner gegner) async{
    int schaden = berechneSchaden(item.kraft * spieler.staerke, gegner.verteidigung, false);

    combatLog.add(await promptSpielerItemAnGegner(gegner, item, schaden));
    notifyListeners();

    if(gegner.leben - schaden <= 0) { //gegner stierbt
      kampfGegner.remove(gegner);
      combatLog.add(await promptGegnerStirbtDurchItem(gegner, item, schaden));
      notifyListeners();

      if(kampfGegner.isEmpty) {
        combatEnde(0);
        return;
      }
    } else { //Gegner überlebt
      gegner.leben -= schaden;
    }
    notifyListeners();
    spieler.items.entferenItem(item); 
    beendeSpielerZug();
  }

  void spielerNutztItemAufAlleGegner(Item item) async {
    combatLog.add(await promptSpielerItemAnAlleGegner(item));
    notifyListeners();

    for(Gegner gegner in kampfGegner) {
      int schaden = berechneSchaden(item.kraft*spieler.staerke, gegner.verteidigung, false);
      if(gegner.leben - schaden <= 0) { //gegner stierbt
        kampfGegner.remove(gegner);
        combatLog.add(await promptGegnerStirbtDurchItem(gegner, item, schaden));
        notifyListeners();

        if(kampfGegner.isEmpty) {
          combatEnde(0);
          return;
        }
      } else {
        gegner.leben -= schaden;
      } 
    }
    spieler.items.entferenItem(item);
    beendeSpielerZug();
  }

  void spilerNutztItemAufSelbst(Item item) async{
    combatLog.add(await promptSpielerHeiltSichItem(item));
    notifyListeners();
    if(spieler.leben - (item.kraft*spieler.staerke).round() > spieler.maxleben) {
      spieler.leben = spieler.maxleben;
    } else {
      spieler.leben -= (item.kraft*spieler.staerke).round();
    }
    spieler.items.entferenItem(item);
    beendeSpielerZug();
  }

  void spielerVertiedigt() async{
    combatLog.add(await promptSpielerVerteidigt());
    notifyListeners();
    spieler.verteidigt = true;
    beendeSpielerZug();
  }

  void spielerRenntWeg() async{
    int spielergesch  = spieler.geschwindigkeit;
    int gegnergesch = 0;
    
    //zähle alle Gegner geschwindigkeiten zusammen
    for (var gegner in kampfGegner) {
      gegnergesch += gegner.geschwindigkeit;      
    }

    double wegrennen = (spielergesch/gegnergesch) * 100;
    
    final random = Random();
    int zahl = random.nextInt(100) + 1;

    if(zahl >= wegrennen) {
      combatEnde(1);
    } else {
      combatLog.add(await promptSpielerScheitertWegzurennen());
      notifyListeners();
      beendeSpielerZug();
    }

  }

  
  int berechneSchaden(double angriff, int verteidigung, bool amVerteidigen) {
    int schaden = 0;
    
    if (amVerteidigen == false) {
      schaden = (angriff * (100 / (100 + verteidigung))).round();
    } else {
      schaden = (angriff * (100 / (100 + verteidigung * 3))).round();
    }
    return schaden;
  }

  void combatEnde(int gewonnen) {
    imKampf = false;
    beendeSpielerZug();

    if(gewonnen==0) {  
      // LevelUp
      onLevelUp?.call(spieler);
    } else if(gewonnen==2) {
      // Verloren
      onZurueckZumChatVerloren?.call();
    } else if(gewonnen == 1) {
      // Entkommen
      onZurueckZumChatEntkommen?.call();
    }
  }

  //Die KI prompts
  Future<String> promptKeineAusdauer(Gegner gegner) async {
    final Map<String, dynamic> gegnerJson = gegner.toJson();

    final String prompt = """
    Du bist eine KI für ein rundenbasiertes Kampfspiel.
    Der Gegner hat keine Ausdauer mehr.

    Schreib ein creative nachicht wie der Gegner seine Runde aussetzt.

    Antworte nur mit einem kurzen Text.
    """;

    return await chatbot.sendeNachricht(prompt, gegnerJson);
  }

  Future<String> promptGegnerSchadenAnSpieler(Gegner gegner, Attacke attacke, int schaden) async { 
    
    // Spieler JSON
    final spielerJson = spieler.toJson();
    // Gegner JSON
    final gegnerJson = gegner.toJson();
    // Attacke JSON
    final attackeJson = attacke.toJson();

    // Alles in ein gemeinsames JSON packen
    final Map<String, dynamic> daten = {
      "spieler": spielerJson,
      "gegner": gegnerJson,
      "attacke": attackeJson,
    };

    String prompt = """
    Du bist eine KI für ein rundenbasiertes Kampfspiel.
    Der gegner greift den spieler an.

    Schreib creativ wie der Angriff des Gegners auf den Spieler aussieht und sag das er $schaden genommen hat.

    Schreib nur ein kurze Narchicht.
    """;

    // Anfrage senden
    final antwort = await chatbot.sendeNachricht(prompt, daten);
    return antwort;
  }

  Future<String> promptGegnerHeiltGegner(Gegner gegner1,Gegner gegner2, Attacke attacke) async {
    
    // Spieler JSON
    final gegner1Json = gegner1.toJson();
    // Gegner JSON
    final gegner2Json = gegner2.toJson();
    // Attacke JSON
    final attackeJson = attacke.toJson();

    // Alles in ein gemeinsames JSON packen
    final Map<String, dynamic> daten = {
      "gegner_1": gegner1Json,
      "gegner_2": gegner2Json,
      "attacke": attackeJson,
    };

    String prompt = """
    Du bist eine KI für ein rundenbasiertes Kampfspiel.
    Der ${gegner1.name} heilt ${gegner2.name} mit der attacke.

    Schreib creativ wie der Angriff von ${gegner1.name} den ${gegner2.name} heilt und merke an das ${(attacke.kraft*gegner1.staerke).round().abs()} Leben geheilt werden.

    Schreib nur ein kurze Narchicht.
    """;

    // Anfrage senden
    final antwort = await chatbot.sendeNachricht(prompt, daten);
    return antwort;
  }

  Future<String> promptGegnerHeiltAlleGegner(Gegner gegner, Attacke attacke) async {
    
    // Spieler JSON
    final gegnerJson = gegner.toJson();
    // Gegner JSON
    final List<Map<String, dynamic>> alleGegnerJson = [];
    for (Gegner g in kampfGegner) {
      alleGegnerJson.add(g.toJson());
    }
    // Attacke JSON
    final attackeJson = attacke.toJson();

    // Alles in ein gemeinsames JSON packen
    final Map<String, dynamic> daten = {
      "gegner": gegnerJson,
      "alle_gegner": alleGegnerJson,
      "attacke": attackeJson,
    };

    String prompt = """
    Du bist eine KI für ein rundenbasiertes Kampfspiel.
    Der ${gegner.name} heilt alle gegner mit der attacke.

    Schreib creativ wie der Angriff des ${gegner.name} alle gegner heilt und merke an das ${(attacke.kraft*gegner.staerke).round().abs()} Leben bei allen_gegner geheilt werden.

    Schreib nur ein kurze Narchicht.
    """;

    // Anfrage senden
    final antwort = await chatbot.sendeNachricht(prompt, daten);
    return antwort;
  }

  Future<String> promptSpielerSchadenAnGegner(Gegner gegner, Attacke attacke, int schaden) async {
    
    // Spieler JSON
    final spielerJson = spieler.toJson();
    // Gegner JSON
    final gegnerJson = gegner.toJson();
    // Attacke JSON
    final attackeJson = attacke.toJson();

    // Alles in ein gemeinsames JSON packen
    final Map<String, dynamic> daten = {
      "spieler": spielerJson,
      "gegner": gegnerJson,
      "attacke": attackeJson,
    };

    String prompt = """
    Du bist eine KI für ein rundenbasiertes Kampfspiel.
    Der spieler greift den ${gegner.name} an.
    
    Schreib kreativ wie der Angriff des spieler auf den ${gegner.name} aussieht und sag das er $schaden genommen hat.

    Schreib nur ein kurze Narchicht.
    """;

    // Anfrage senden
    final antwort = await chatbot.sendeNachricht(prompt, daten);
    return antwort;
  }

  Future<String> promptSpielerSchadenAnAlleGegner(Attacke attacke) async {
    // Spieler JSON
    final spielerJson = spieler.toJson();
    // Gegner JSON
    final List<Map<String, dynamic>> alleGegnerJson = [];
    for (Gegner g in kampfGegner) {
      alleGegnerJson.add(g.toJson());
    }
    // Attacke JSON
    final attackeJson = attacke.toJson();

    // Alles in ein gemeinsames JSON packen
    final Map<String, dynamic> daten = {
      "spieler": spielerJson,
      "alle_gegner": alleGegnerJson,
      "attacke": attackeJson,
    };

    String prompt = """
    Der spieler Attackiert alle gegner mit der attacke.

    Beschreib creativ wie der Angriff des Spielers alle gegner schaden verursacht. Erwähne das der Spieler jedem Gegner ${(attacke.kraft * spieler.staerke).round()} Schaden zufügt.

    Schreib nur ein kurze Narchicht.
    """;

    // Anfrage senden
    final antwort = await chatbot.sendeNachricht(prompt, daten);
    return antwort;
  }

  Future<String> promptSpielerHeiltSich(Attacke attacke) async {
    
    // Spieler JSON
    final spielerJson = spieler.toJson();
    // Attacke JSON
    final attackeJson = attacke.toJson();

    // Alles in ein gemeinsames JSON packen
    final Map<String, dynamic> daten = {
      "spieler": spielerJson,
      "attacke": attackeJson,
    };

    String prompt = """
    Du bist eine KI für ein rundenbasiertes Kampfspiel.
    Der spieler heilt sich mit der attacke.

    Schreib creativ wie der Angriff des spieler ihn heilt und merke an das ${(attacke.kraft*spieler.staerke).round().abs()} Leben geheilt werden.

    Schreib nur ein kurze Narchicht.
    """;

    // Anfrage senden
    final antwort = await chatbot.sendeNachricht(prompt, daten);
    return antwort;
  }

  Future<String> promptGegnerStirbtDurchAttacke(Gegner gegner, Attacke attacke, int schaden) async {
  
    // Spieler JSON
    final spielerJson = spieler.toJson();
    // Gegner JSON
    final gegnerJson = gegner.toJson();
    // Attacke JSON
    final attackeJson = attacke.toJson();

    // Alles in ein gemeinsames JSON packen
    final Map<String, dynamic> daten = {
      "spieler": spielerJson,
      "gegner": gegnerJson,
      "attacke": attackeJson,
    };

    String prompt = """
    Du bist eine KI für ein rundenbasiertes Kampfspiel.
    Der spieler hat durch den ${attacke.name} ${gegner.name} getötet.

    Schreib kreativ wie der gegner durch die attacke stirbt.

    Schreib nur ein kurze Narchicht.
    """;

    // Anfrage senden
    final antwort = await chatbot.sendeNachricht(prompt, daten);
    return antwort;
}

  Future<String> promptGegnerStirbtDurchItem(Gegner gegner, Item item, int schaden) async {
  
    // Spieler JSON
    final spielerJson = spieler.toJson();
    // Gegner JSON
    final gegnerJson = gegner.toJson();
    // Attacke JSON
    final itemJson = item.toJson();

    // Alles in ein gemeinsames JSON packen
    final Map<String, dynamic> daten = {
      "spieler": spielerJson,
      "gegner": gegnerJson,
      "item": itemJson,
    };

    String prompt = """
    Du bist eine KI für ein rundenbasiertes Kampfspiel.
    Der spieler hat durch den ${item.name} ${gegner.name} getötet.

    Schreib kreativ wie der gegner durch die attacke stirbt.

    Schreib nur ein kurze Narchicht.
    """;

    // Anfrage senden
    final antwort = await chatbot.sendeNachricht(prompt, daten);
    return antwort;
}

  Future<String> promptSpielerItemAnGegner(Gegner gegner, Item item, int schaden) async {
    
    // Spieler JSON
    final spielerJson = spieler.toJson();
    // Gegner JSON
    final gegnerJson = gegner.toJson();
    // Attacke JSON
    final itemJson = item.toJson();

    // Alles in ein gemeinsames JSON packen
    final Map<String, dynamic> daten = {
      "spieler": spielerJson,
      "gegner": gegnerJson,
      "item": itemJson,
    };

    String prompt = """
    Du bist eine KI für ein rundenbasiertes Kampfspiel.
    Der spieler benutzt das Item ${item.name} und fügt dadurch ${gegner.name} schaden zu.
    
    Schreib kreativ wie das Item den ${gegner.name} schaden zufügt und sag das er $schaden genommen hat.

    Schreib nur ein kurze Narchicht.
    """;

    // Anfrage senden
    final antwort = await chatbot.sendeNachricht(prompt, daten);
    return antwort;
  }

  Future<String> promptSpielerItemAnAlleGegner(Item item) async {
    // Spieler JSON
    final spielerJson = spieler.toJson();
    // Gegner JSON
    final List<Map<String, dynamic>> alleGegnerJson = [];
    for (Gegner g in kampfGegner) {
      alleGegnerJson.add(g.toJson());
    }
    // Attacke JSON
    final itemJson = item.toJson();

    // Alles in ein gemeinsames JSON packen
    final Map<String, dynamic> daten = {
      "spieler": spielerJson,
      "alle_gegner": alleGegnerJson,
      "item": itemJson,
    };

    String prompt = """
    Du bist eine KI für ein rundenbasiertes Kampfspiel.
    Der spieler benutzt das Item ${item.name} und fügt dadurch allen Gegner schaden zu.

    Beschreib creativ wie der Angriff des Spielers alle gegner schaden verursacht. Erwähne das der Spieler jedem Gegner ${(item.kraft * spieler.staerke).round()} Schaden zufügt.

    Schreib nur ein kurze Narchicht.
    """;

    // Anfrage senden
    final antwort = await chatbot.sendeNachricht(prompt, daten);
    return antwort;
  }

  Future<String> promptSpielerHeiltSichItem(Item item) async {
    
    // Spieler JSON
    final spielerJson = spieler.toJson();
    // Attacke JSON
    final itemJson = item.toJson();

    // Alles in ein gemeinsames JSON packen
    final Map<String, dynamic> daten = {
      "spieler": spielerJson,
      "item": itemJson,
    };

    String prompt = """
    Du bist eine KI für ein rundenbasiertes Kampfspiel.
    Der spieler heilt sich mit ${item.name}.

    Schreib creativ wie das Item des spieler ihn heilt und merke an das ${(item.kraft*spieler.staerke).round().abs()} Leben geheilt werden.

    Schreib nur ein kurze Narchicht.
    """;

    // Anfrage senden
    final antwort = await chatbot.sendeNachricht(prompt, daten);
    return antwort;
  }

  Future<String> promptSpielerVerteidigt () async {
    
    // Spieler JSON
    final spielerJson = spieler.toJson();

    String prompt = """
    Du bist eine KI für ein rundenbasiertes Kampfspiel.
    Der Spieler geht in die Verteidigungsstellung.

    Schreib kurz das der Spieler in eine Verteidigungsstellung geht.
    """;

    // Anfrage senden
    final antwort = await chatbot.sendeNachricht(prompt, spielerJson);
    return antwort;
  }

  Future<String> promptSpielerScheitertWegzurennen () async {
    
    // Spieler JSON
    final spielerJson = spieler.toJson();

    // Gegner JSON
    final List<Map<String, dynamic>> alleGegnerJson = [];
    for (Gegner g in kampfGegner) {
      alleGegnerJson.add(g.toJson());
    }

    // Alles in ein gemeinsames JSON packen
    final Map<String, dynamic> daten = {
      "spieler": spielerJson,
      "alle_gegner": alleGegnerJson,
    };

    String prompt = """
    Du bist eine KI für ein rundenbasiertes Kampfspiel.
    Der Spieler versucht wegzurennen.

    Schreib Creativ wie er daran scheitert.

    Schreib nur eine kurze narchicht.
    """;

    // Anfrage senden
    final antwort = await chatbot.sendeNachricht(prompt, daten);
    return antwort;
  }
}
