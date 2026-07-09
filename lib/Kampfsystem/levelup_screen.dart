import 'package:flutter/material.dart';
import 'chat_bot.dart';

import 'attacke.dart';
import 'attacken_liste.dart';
import '../main.dart';

class LevelUpScreen extends StatefulWidget {
  final GameSettings settings;
  final Map<String, dynamic>? initialSaveData; 
  const LevelUpScreen({
    super.key,
    required this.settings,
    required this.initialSaveData,
  });

  @override
  State<LevelUpScreen> createState() => _LevelUpScreenState();
}

class _LevelUpScreenState extends State<LevelUpScreen> {
  String? selectedAttribute;
  int? selectedBox;

  final Chatbot chatbot = Chatbot();

  AttackenListe? attacken;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _ladeAttacken();
  }

  Future<void> _ladeAttacken() async {
    attacken = await chatbot.erstelleAttacken(
      widget.settings.spieler.toJson().toString(),
      widget.settings
    );

    setState(() {
      isLoading = false;
    });
  }

  bool get canFinish =>
      selectedAttribute != null && selectedBox != null;

  void _attributeVergeben() {
    switch (selectedAttribute) {
      case "Maxleben":
        widget.settings.spieler.maxleben += 3;
        widget.settings.spieler.leben += 3;
        break;

      case "Maxausdauer":
        widget.settings.spieler.maxausdauer += 3;
        widget.settings.spieler.ausdauer += 3;
        break;

      case "Ausdauerregeneration":
        widget.settings.spieler.ausdauerregeneration += 1;
        break;

      case "Verteidigung":
        widget.settings.spieler.verteidigung += 1;
        break;

      case "Geschwindigkeit":
        widget.settings.spieler.geschwindigkeit += 1;
        break;
      
      case "Stärke":
        widget.settings.spieler.staerke += 1;
        break;
    }

    if (selectedBox != null && attacken != null) {
      widget.settings.spieler.attacken.addAttacke(
        attacken!.alleAttacken[selectedBox! - 1],
      );
    }
  }

  void _finishLevelUp() {
    if (!canFinish) return;

    _attributeVergeben();

    debugPrint(widget.settings.spieler.toJson().toString());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(settings: widget.settings,initialSaveData: widget.initialSaveData, kampfAusgang: 0),
      )
    );
  }

  Widget _statButton(String stat) {
    final selected = selectedAttribute == stat;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                selected ? Colors.green : Colors.grey.shade700,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 55),
          ),
          onPressed: () {
            setState(() {
              selectedAttribute = stat;
            });
          },
          child: Text(
            (stat == "Maxleben" || stat == "Maxausdauer")
                ? "+3 $stat"
                : "+1 $stat",
          ),
        ),
      ),
    );
  }

  Widget _rewardBox(int nummer, Attacke attacke) {
    final selected = selectedBox == nummer;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedBox = nummer;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: selected
                ? Colors.amber.shade400
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Colors.orange : Colors.grey,
              width: 3,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  attacke.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: !attacke.aoe && !attacke.aufgegner
                        ? Colors.green
                        : attacke.aoe && attacke.aufgegner
                            ? Colors.purple
                            : !attacke.aoe && attacke.aufgegner
                                ? Colors.red
                                : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 8),
                Text(
                  "Kraft: ${attacke.kraft}",
                  style: TextStyle(color: Colors.black),
                ),
                Text(
                  "Kosten: ${attacke.kosten}",
                  style: TextStyle(color: Colors.black),
                ),
                Text(
                  "AOE: ${attacke.aoe}",
                  style: TextStyle(color: Colors.black),
                ),
                Text(
                  attacke.aufgegner ? "Ziel: Gegner" : "Ziel: Selbst",
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (attacken == null ||
        attacken!.alleAttacken.length < 3) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Fehler beim Laden der Attacken",
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Level Up"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Verteile deinen Attributspunkt",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            _statButton("Maxleben"),
            _statButton("Maxausdauer"),
            _statButton("Ausdauerregeneration"),
            _statButton("Verteidigung"),
            _statButton("Geschwindigkeit"),
            _statButton("Stärke"),

            const SizedBox(height: 25),

            const Text(
              "Wähle eine neue Fähigkeit",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Expanded(
              child: Row(
                children: [
                  _rewardBox(
                    1,
                    attacken!.alleAttacken[0],
                  ),
                  _rewardBox(
                    2,
                    attacken!.alleAttacken[1],
                  ),
                  _rewardBox(
                    3,
                    attacken!.alleAttacken[2],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: canFinish ? _finishLevelUp : null,
                child: const Text(
                  "Fertig",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}