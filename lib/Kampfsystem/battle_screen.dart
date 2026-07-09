import 'package:flutter/material.dart';
import 'chat_bot.dart';
import 'combat_logic.dart';
import 'attacke.dart';
import 'item.dart';
import 'levelup_screen.dart';
import '../main.dart';

class BattleScreen extends StatefulWidget {
  final GameSettings settings;
  final Map<String, dynamic>? initialSaveData; 
  final String cleanAnswer;
  const BattleScreen({super.key, required this.settings, required this.initialSaveData, required this.cleanAnswer});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  late GameLogic gameLogic;
  late Chatbot chatbot;
  bool showAttackList = false;
  bool showItemList = false;

  // ✅ Turn-System
  bool spielerAmZug = false;

  // ✅ Zielsystem
  Attacke? ausgewaehlteAttacke;
  Item? ausgewaehltesItem;
  bool zielAuswahlAktiv = false;
  bool hilfeAttacke = false;
  bool hilfeItem = false;
  bool warte = true;

  //gegnerInit = async Hielfs methode damit warte erst nach ihr true gesetzt wird
  Future<void> _initKampf() async {
    await gameLogic.gegnerInit();

    setState(() {
      warte = false;
    });
  }

  @override
  void initState() {
    super.initState();
    gameLogic = GameLogic(spieler: widget.settings.spieler, settings: widget.settings, cleanAnswer: widget.cleanAnswer);

    gameLogic.addListener(() {
      setState(() {
        spielerAmZug = gameLogic.isSpielerAmZug;
      });
    });
    //Navigation falls spieler Gewinnt 
    gameLogic.onLevelUp = (spieler) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _goToLevelupScreen(context);
      });
    };
    //Navigation falls spieler entkommt  
    gameLogic.onZurueckZumChatEntkommen = () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _goToChatScreenEntkommen(context);
      });
    };
    //Navigation falls spieler verliert
    gameLogic.onZurueckZumChatVerloren = () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _goToChatScreenVerloren(context);
      });
    };

    _initKampf();
  }

  // ✅ Angriffsauswahl
  Widget _buildAttackSelection() {
    final attackenListe = gameLogic.spieler.attacken.alleAttacken;

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: ListView.builder(
            itemCount: attackenListe.length,
            itemBuilder: (context, index) {
              final attacke = attackenListe[index];
 
              return ListTile(
                title: Text(attacke.name),
                subtitle: Text(
                  "Kraft: ${attacke.kraft} | Ausdauer: ${attacke.kosten} | AOE: ${attacke.aoe} | Ziel: ${attacke.aufgegner ? "Gegner" : "Selbst"}",
                ),
                onTap: !spielerAmZug
                    ? null
                    : () {
                        if (!attacke.aufgegner) {
                          gameLogic.spielerHeiltSich(attacke);
                          _spielerZugBeenden();
                        } else if (attacke.aoe) {
                          gameLogic.spielerAttackiertAlleGegner(attacke);
                          _spielerZugBeenden();
                        } else {
                          setState(() {
                            ausgewaehlteAttacke = attacke;
                            zielAuswahlAktiv = true;
                            hilfeAttacke = true;
                            showAttackList = false;
                          });
                        }
                      },
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        ElevatedButton(
          onPressed: () {
            setState(() {
              showAttackList = false;
            });
          },
          child: const Text("Zurück"),
        ),
      ],
    );
  }

  Widget _buildItemSelection() {
    final itemListe = gameLogic.spieler.items.alleItems;

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: ListView.builder(
            itemCount: itemListe.length,
            itemBuilder: (context, index) {
              final item = itemListe[index];

              return ListTile(
                title: Text(item.name),
                subtitle: 
                Text("Kraft: ${item.kraft} | AOE: ${item.aoe} | Ziel: ${item.aufgegner ? "Gegner" : "Selbst"}"),
                onTap: !spielerAmZug
                    ? null
                    : () {
                        if (!item.aufgegner) {
                          gameLogic.spielerNutztItemAufAlleGegner(item);
                          _spielerZugBeenden();
                        } else if (item.aoe) {
                          gameLogic.spilerNutztItemAufSelbst(item);
                          _spielerZugBeenden();
                        } else {
                          setState(() {
                            ausgewaehltesItem = item;
                            zielAuswahlAktiv = true;
                            hilfeItem = true;
                            showItemList = false;
                          });
                        }
                      },
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        ElevatedButton(
          onPressed: () {
            setState(() {
              showItemList = false;
            });
          },
          child: const Text("Zurück"),
        ),
      ],
    );
  }

  void _spielerZugBeenden() {
    setState(() {
      showAttackList = false;
      showItemList = false;
      zielAuswahlAktiv = false;
      hilfeAttacke = false;
      hilfeItem = false;
      ausgewaehlteAttacke = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    //Wenn am Warten Ladekreis anzeigen
    if (warte) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  //Wenn nicht am laden kein lade Kreis anzeigen
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // 🔴 Gegnerliste
          SizedBox(
            height: 140,
            child: ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemCount: gameLogic.kampfGegner.length,
              itemBuilder: (context, index) {
                final g = gameLogic.kampfGegner[index];

                return GestureDetector(
                  onTap: (zielAuswahlAktiv && spielerAmZug)
                      ? () {
                          if (ausgewaehlteAttacke != null) {
                            gameLogic.spielerAttackiertGegner(g,ausgewaehlteAttacke!,);
                            _spielerZugBeenden();
                          }
                          if (ausgewaehltesItem != null) {
                            gameLogic.spielerNutztItemAufGegner(ausgewaehltesItem!, g);
                            _spielerZugBeenden();
                          }
                        }
                      : null,
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: zielAuswahlAktiv
                          ? Border.all(color: Colors.red, width: 4)
                          : null,
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 60,
                          color: Colors.green,
                          alignment: Alignment.center,
                          child: Text(
                            g.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 5),
                        LinearProgressIndicator(
                          value: g.leben / g.maxleben,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: g.ausdauer / g.maxausdauer,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(),

          // 📜 Log
          Expanded(
            child: ListView.builder(
              itemCount: gameLogic.combatLog.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(gameLogic.combatLog[index]),
                );
              },
            ),
          ),

          const Divider(),

          // 🧍 Spieler + Aktionen
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value:
                      gameLogic.spieler.leben / gameLogic.spieler.maxleben,
                  color: Colors.red,
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: gameLogic.spieler.ausdauer /
                      gameLogic.spieler.maxausdauer,
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),

                _buildActionArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }


// 🔧 Haupt-UI Bereich
  Widget _buildActionArea() {
    // 🎯 Zielauswahl (Attacke)
    if (zielAuswahlAktiv && hilfeAttacke) {
      return const Text(
        "🎯 Wähle einen Gegner",
        style: TextStyle(fontWeight: FontWeight.bold),
      );
    }

    // 🎯 Zielauswahl (Item)
    if (zielAuswahlAktiv && hilfeItem) {
      return const Text(
        "🎯 Wähle ein Ziel für das Item",
        style: TextStyle(fontWeight: FontWeight.bold),
      );
    }

    // ⚔️ Attackenliste
    if (showAttackList) {
      return _buildAttackSelection();
    }

    // 🎒 Itemliste
    if (showItemList) {
      return _buildItemSelection();
    }

    // 🧍 Standard Menü
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      childAspectRatio: 3,
      children: [
        ElevatedButton(
          onPressed: spielerAmZug
              ? () {
                  setState(() {
                    showAttackList = true;
                    showItemList = false;
                    zielAuswahlAktiv = false;
                  });
                }
              : null,
          child: const Text("Attackieren"),
        ),
        ElevatedButton(
          onPressed: spielerAmZug
              ? () {
                  setState(() {
                    showItemList = true;
                    showAttackList = false;
                    zielAuswahlAktiv = false;
                  });
                }
              : null,
          child: const Text("Item"),
        ),
        ElevatedButton(
          onPressed: spielerAmZug
              ? () {
                  gameLogic.spielerVertiedigt();
                  _spielerZugBeenden();
                }
              : null,
          child: const Text("Verteidigen"),
        ),
        ElevatedButton(
          onPressed: spielerAmZug
              ? () {
                  gameLogic.spielerRenntWeg();
                  _spielerZugBeenden();
                }
              : null,
          child: const Text("Wegrennen"),
        ),
      ],
    );
  }

  void _goToLevelupScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LevelUpScreen(
          settings: widget.settings,
          initialSaveData: widget.initialSaveData,
        ),
      ),
    );
  }

  void _goToChatScreenEntkommen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(settings: widget.settings,initialSaveData: widget.initialSaveData, kampfAusgang: 1),
      ),
    );
  }

  void _goToChatScreenVerloren(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(settings: widget.settings,initialSaveData: widget.initialSaveData, kampfAusgang: 2),
      ),
    );
  }
}
