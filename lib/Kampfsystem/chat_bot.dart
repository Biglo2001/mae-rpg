import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/main.dart';
import 'package:http/http.dart' as http;
import 'gegner_liste.dart';
import 'attacken_liste.dart';
import 'item.dart';

class Chatbot {
  final String _apiKey = ""; //TODO API key eingeben

  final String apiUrl ="https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent";

    // ✅ Nachricht senden und Antwort bekommen


  Future<String> sendeNachricht(
    String prompt,
    Map<String, dynamic> json,
  ) async {
    int retryDelay = 1;
    int retries = 0;
    const int maxRetries = 3;

    while (retries < maxRetries) {
      try {
        final response = await http.post(
          Uri.parse("$apiUrl?key=${_apiKey.trim()}"),
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "contents": [
              {
                "role": "user",
                "parts": [
                  {
                    "text": "$prompt Daten: ${jsonEncode(json)}"
                  }
                ]
              }
            ]
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data["candidates"][0]["content"]["parts"][0]["text"];
        }

        if (response.statusCode == 429 || response.statusCode == 503) {
          retries++;

          if (retries >= maxRetries) {
            debugPrint("Maximale Anzahl an Retries erreicht.");
            return "Die MAGiE(Token) verschwand";
          }

          debugPrint(
            "Retry $retries/$maxRetries in $retryDelay Sekunde(n) wegen ${response.statusCode}",
          );

          await Future.delayed(Duration(seconds: retryDelay));
          retryDelay = (retryDelay * 2).clamp(1, 30);

          continue;
        }

        debugPrint("Fehler Status: ${response.statusCode}");
        debugPrint("Fehler Body: ${response.body}");
        return "Die MAGiE(Token) verschwand";
      } catch (e) {
        retries++;

        if (retries >= maxRetries) {
          debugPrint("Maximale Anzahl an Retries erreicht. Exception: $e");
          return "Die MAGiE(Token) verschwand";
        }

        debugPrint(
          "Exception -> Retry $retries/$maxRetries in $retryDelay Sekunde(n)",
        );

        await Future.delayed(Duration(seconds: retryDelay));
        retryDelay = (retryDelay * 2).clamp(1, 30);
      }
    }

    return "Die MAGiE(Token) verschwand";
  }
  //erstelle die Gegner für den Combatscreen
  Future<GegnerListe?> erstelleKampfgegner(String spielerJson, String cleanAnswer, GameSettings settings) async {
    String prompt = '''
  Erstelle wischen 1 und 3 ${settings.setting}-Gegner.

  WICHTIG:
  - Antworte ausschließlich mit gültigem JSON.
  - Keine Erklärungen.
  - Kein Markdown.
  - Keine Codeblöcke.

  Format:

  {
    "gegner": [
      {
        "name": "",
        "beschreibung": "",
        "maxleben": 100,
        "leben": 100,
        "maxausdauer": 50,
        "ausdauer": 50,
        "ausdauerregeneration": 5,
        "verteidigung": 10,
        "geschwindigkeit": 10,
        "stärke": 3,
        "attacken": [
          {
            "name": "",
            "beschreibung": "",
            "kraft": 0.5,
            "kosten": 5,
            "aufgegner": true,
            "aoe": false
          }
        ]
      }
    ]
  }

  Bedingung: 

  - Beachte das die Attribute der Gegner kleiner oder maximal gleich dennen von dem Spieler sind: "$spielerJson"
  - Der kampf sollte ${settings.difficulty} sein.
  - Der Gegner soll mit denn genannten Gegner aus folgenden text übereinstimmen: "$cleanAnswer"
  ''';

    try {
      final response = await http.post(
        Uri.parse("$apiUrl?key=${_apiKey.trim()}"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ],
          "generationConfig": {
            "responseMimeType": "application/json"
          }
        }),
      );

      if (response.statusCode != 200) {
        debugPrint("Fehler: ${response.statusCode}");
        debugPrint(response.body);
        return null;
      }

      final responseData = jsonDecode(response.body);

      final jsonText =
          responseData["candidates"][0]["content"]["parts"][0]["text"];

      final Map<String, dynamic> jsonData = jsonDecode(jsonText);

      return GegnerListe.fromJson(jsonData);
    } catch (e) {
      debugPrint("Fehler beim Erstellen der Gegner: $e");
      return null;
    }
  }

  //Erstelle AttackenListe für den LevelupScreen
  Future<AttackenListe?> erstelleAttacken(String spielerJson, GameSettings settings) async {
    String prompt = '''
  Erstelle genau 3 Attacken.

  WICHTIG:
  - Antworte ausschließlich mit gültigem JSON.
  - Keine Erklärungen.
  - Kein Markdown.
  - Keine Codeblöcke.

  Format:

  {
    "attacken": [
      {
        "name": "",
        "beschreibung": "",
        "kraft": 0.5,
        "kosten": 5,
        "aufgegner": true,
        "aoe": false
      }
    ]
  }

  Bedingungen:
  - Genau 3 Attacken erzeugen.
  - ${settings.setting} Stil.
  - Es solle jeweils eine Einzelziel-, Flächen- und Heilfähigkeiten erstellt werden.
  - Bei Heilfähigkeiten:
    - aufgegner = false
    - schaden beschreibt die Heilmenge
    - aoe = false
    - kraft soll zwischen 0.7 und 3 liegen
  - Bie Flächenfähigkeiten:
    - aoe = true
    - aufgegener = true
    - kraft soll zwischen 0.5 und 2 liegen
  - Bei Einzelzielfähigkeit
    - aoe = false
    - aufgegner = true
    - kraft soll zwisch 1 und 5 liegen
  - die Kosten sollen dem Spieler angepasst werden: $spielerJson
  - die Kraft soll niedrig gehalten werden und nur mit einer geringen warscheinlichkeit höher ausfallen.
  - die erstellte fähigkeiten durfen nicht den geleichen namen und beschreibung wie eine bereites forhandene attacke besitzen: ${settings.spieler.attacken.toJson()}
  ''';

    try {
      final response = await http.post(
        Uri.parse("$apiUrl?key=${_apiKey.trim()}"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ],
          "generationConfig": {
            "responseMimeType": "application/json"
          }
        }),
      );

      if (response.statusCode != 200) {
        debugPrint("Fehler: ${response.statusCode}");
        debugPrint(response.body);
        return null;
      }

      final responseData = jsonDecode(response.body);

      final jsonText =
          responseData["candidates"][0]["content"]["parts"][0]["text"];

      final Map<String, dynamic> jsonData = jsonDecode(jsonText);
 
      return AttackenListe.fromJson(jsonData['attacken'] as List<dynamic>,);

    } catch (e) {
      debugPrint("Fehler beim Erstellen der Attacken: $e");
      return null;
    }
  }


Future<Item> erstelleItem(String name, String desc, GameSettings settings) async {
  // itemTyp kann z.B. "Heilung", "Flächenschaden" oder "Einzelziel" sein, um der KI mitzuteilen, was gewünscht ist.
  
  String prompt = '''
  Erstelle genau 1 Item basierend auf dem Namen und der Beschreibung.
  Name des Gegenstands: $name
  Beschreibung/Kontext: $desc

  WICHTIG:
  - Antworte ausschließlich mit gültigem JSON.
  - Keine Erklärungen.
  - Kein Markdown.
  - Keine Codeblöcke.

  Format:
  {
    "name": "Name des Items",
    "beschreibung": "Eine atmosphärische Beschreibung im ${settings.setting}-Stil.",
    "kraft": 1.5,
    "aufgegner": true,
    "aoe": false
  }
  
  Falls es ein Heilgegenstand/Heilfähigkeit ist:
    - aufgegner = false
    - kraft beschreibt die Heilmenge und soll zwischen 0.7 und 3 liegen
    - aoe = false
    
  Falls es eine Flächenfähigkeit/Flächenschaden-Gegenstand ist:
    - aoe = true
    - aufgegner = true
    - kraft soll zwischen 0.5 und 2 liegen
    
  Falls es eine Einzelzielfähigkeit/Waffe ist:
    - aoe = false
    - aufgegner = true
    - kraft soll zwischen 1.0 und 5.0 liegen
    
  Allgemein:
  - Die Kraft soll tendenziell niedrig gehalten werden und nur mit einer geringen Wahrscheinlichkeit höher ausfallen.
  - Datentyp-Hinweis für "kraft": Muss eine Fließkommazahl (double) sein.
  ''';

  try {
    final response = await http.post(
      Uri.parse("$apiUrl?key=${_apiKey.trim()}"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ],
        "generationConfig": {
          "responseMimeType": "application/json"
        }
      }),
    );

    if (response.statusCode != 200) {
      debugPrint("Fehler: ${response.statusCode}");
      debugPrint(response.body);
      return Item(
      name: "Platzhalter",
      beschreibung: "",
      kraft: 0,
      aufgegner: false,
      aoe: false,
    );
    }

    final responseData = jsonDecode(response.body);

    final jsonText = responseData["candidates"][0]["content"]["parts"][0]["text"];

    final Map<String, dynamic> jsonData = jsonDecode(jsonText);

    // Hier mappen wir das JSON direkt in dein Datenmodell "Item"
    return Item.fromJson(jsonData);

  } catch (e) {
    debugPrint("Fehler beim Erstellen des Items: $e");
    return Item(
      name: "Platzhalter",
      beschreibung: "",
      kraft: 0,
      aufgegner: false,
      aoe: false,
    );
  }
}


}