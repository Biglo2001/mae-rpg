import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Für das Kopieren in die Zwischenablage
import 'package:flutter_application_1/Kampfsystem/battle_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/map_screen.dart';
import 'Kampfsystem/spieler.dart';
import 'Kampfsystem/start_initialirung.dart';


void main() {
  runApp(const ChatBotApp());
}

class ChatBotApp extends StatelessWidget {
  const ChatBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chroniken der Schattenwelt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E140A),
        primaryColor: const Color(0xFFC5A059),
      ),

      home: const StartScreen(),
    );
  }
}

// --- DATEN MODELLE ---

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class GameSettings {
  final String id; 
  final String charName;
  final String gender;
  final String difficulty;
  final String setting;
  final bool usePredefinedAdventure;
  Spieler spieler;

  GameSettings({
    required this.id,
    required this.charName,
    required this.gender,
    required this.difficulty,
    required this.setting,
    required this.spieler,
    this.usePredefinedAdventure = false,
  });

  Map<String, dynamic> toJson() => {
        "id": id,
        "char_name": charName,
        "gender": gender,
        "difficulty": difficulty,
        "setting": setting,
        "spieler": spieler.toJson(),
        "adventure_type": usePredefinedAdventure ? "Vorgegeben" : "Prozedural",
      };

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      charName: json['char_name'] ?? "Wanderer",
      gender: json['gender'] ?? "Divers",
      difficulty: json['difficulty'] ?? "Mittel",
      setting: json['setting'] ?? "Mittelalter",
      spieler: Spieler.fromJson(json['spieler']),
      usePredefinedAdventure: json['adventure_type'] == "Vorgegeben",
    );
  }
}

class InventoryItem { //TODO inventar muss auf Spieler angepasst werden
  final String name;
  final String description;
  int quantity; 
  final IconData icon;
  final Color iconColor;

  InventoryItem({
    required this.name,
    required this.description,
    required this.quantity,
    required this.icon,
    required this.iconColor,
  });
}

// --- STARTBILDSCHIRM ---

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/hintergrund_pergament.jpg', fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.black)),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.4),),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Chroniken der\nSchattenwelt",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFC5A059),
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black, blurRadius: 8, offset: Offset(2, 2))],
                  ),
                ),
                const SizedBox(height: 60),
                _buildMenuButton(
                  text: "Spiel Laden / Teilen",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SaveGameListScreen()),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildMenuButton(
                  text: "Spiel Erstellen",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SetupScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({required String text, required VoidCallback onTap}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8A6421).withValues(alpha: 0.9),
        foregroundColor: const Color(0xFFF4EAD4),
        minimumSize: const Size(270, 55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFC5A059), width: 2),
        ),
        elevation: 8,
      ),
      onPressed: onTap,
      child: Text(text, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }
}

// --- SPIELSTÄNDE AUSWAHL & IMPORT SCREEN ---

class SaveGameListScreen extends StatefulWidget {
  const SaveGameListScreen({super.key});

  @override
  State<SaveGameListScreen> createState() => _SaveGameListScreenState();
}

class _SaveGameListScreenState extends State<SaveGameListScreen> {
  List<Map<String, dynamic>> _saveGames = [];
  bool _loading = true;
  final TextEditingController _importController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSaveGameList();
  }

  Future<void> _loadSaveGameList() async {
    final prefs = await SharedPreferences.getInstance();
    //await prefs.clear(); //TODO Alte Speicherdaten Stimmen nicht mit der Neuen version überein. Bei auftretenden fehlern einmal Zeile entkommentieren --> App starten und Spiele Laden --> App schließen --> zeile zum Kommentar machen
    final keys = prefs.getKeys().where((key) => key.startsWith('savegame_'));
    
    List<Map<String, dynamic>> loadedSaves = [];
    for (String key in keys) {
      try {
        final data = jsonDecode(prefs.getString(key) ?? '');
        loadedSaves.add(data);
      } catch (e) {
        debugPrint("Fehler beim Parsen von Speicherstand $key: $e");
      }
    }

    loadedSaves.sort((a, b) {
      final idA = (a['settings']?['id'] ?? '').toString();
      final idB = (b['settings']?['id'] ?? '').toString();
      return idB.compareTo(idA);
    });

    setState(() {
      _saveGames = loadedSaves;
      _loading = false;
    });
  }

  Future<void> _deleteSaveGame(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('savegame_$id');
    _loadSaveGameList();
  }

  String _generateAdventureCode(Map<String, dynamic> save) {
    try {
      final settings = save['settings'];
      final chatList = save['chat'] as List;
      final firstMsg = chatList.isNotEmpty ? chatList.first['text'] : "";

      final Map<String, dynamic> shareMap = {
        'settings': settings,
        'intro': firstMsg,
      };

      String jsonStr = jsonEncode(shareMap);
      return base64Encode(utf8.encode(jsonStr));
    } catch (e) {
      return "Fehler beim Generieren";
    }
  }

  void _importAdventureCode(String code) {
    try {
      String decodedStr = utf8.decode(base64Decode(code.trim()));
      Map<String, dynamic> importedData = jsonDecode(decodedStr);

      final oldSettings = GameSettings.fromJson(importedData['settings']);
      final newSettings = GameSettings(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        charName: oldSettings.charName,
        gender: oldSettings.gender,
        difficulty: oldSettings.difficulty,
        setting: oldSettings.setting,
        spieler: oldSettings.spieler,
        usePredefinedAdventure: oldSettings.usePredefinedAdventure,
      );

      final String introText = importedData['intro'] ?? "Abenteuer beginnt...";

      final Map<String, dynamic> newSaveStructure = {
        'settings': newSettings.toJson(),
        'chat': [{'text': introText, 'isUser': false}],
        'inventory': [], 
      };

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ChatScreen(settings: newSettings, initialSaveData: newSaveStructure)),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ungültiger Abenteuer-Code!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/hintergrund_pergament.jpg', fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.black))),
          Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.5))),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFFC5A059), size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 10),
                  const Text("ABENTEUER IMPORTIEREN",
                      style: TextStyle(color: Color(0xFFC5A059), fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _importController,
                          decoration: const InputDecoration(
                            hintText: 'Code hier einfügen...',
                            filled: true,
                            fillColor: Color(0xFFF4EAD4),
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                          style: const TextStyle(color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8A6421)),
                        onPressed: () => _importAdventureCode(_importController.text),
                        child: const Text("Starten"),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFC5A059), height: 40, thickness: 2),
                  const Text("GESPEICHERTE CHRONIKEN",
                      style: TextStyle(color: Color(0xFFC5A059), fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFC5A059)))
                        : _saveGames.isEmpty
                            ? const Center(child: Text("Keine Abenteuer gefunden.", style: TextStyle(color: Color(0xFFF4EAD4), fontSize: 18, fontStyle: FontStyle.italic)))
                            : ListView.builder(
                                itemCount: _saveGames.length,
                                itemBuilder: (context, index) {
                                  final save = _saveGames[index];
                                  final settings = GameSettings.fromJson(save['settings']);
                                  final lastMsg = (save['chat'] as List).isNotEmpty ? save['chat'].last['text'] : "Gerade begonnen...";

                                  return Container(
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF4EAD4),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFF8A6421), width: 2),
                                    ),
                                    child: ListTile(
                                      title: Text("${settings.charName} (${settings.setting})", style: const TextStyle(color: Color(0xFF2D1E10), fontWeight: FontWeight.bold, fontSize: 18)),
                                      subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF5C4018), fontStyle: FontStyle.italic)),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.share, color: Colors.blueAccent),
                                            tooltip: 'Code kopieren',
                                            onPressed: () {
                                              String code = _generateAdventureCode(save);
                                              Clipboard.setData(ClipboardData(text: code));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Abenteuer-Code in Zwischenablage kopiert!")),
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                                            onPressed: () => _deleteSaveGame(settings.id),
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(builder: (context) => ChatScreen(settings: settings, initialSaveData: save)),
                                          (route) => false,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- SETUP SCREEN (CHARAKTERERSTELLUNG) ---

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedGender = 'Männlich';
  String _selectedDifficulty = 'Mittel';
  String _selectedSetting = 'Mittelalter';
  bool _isPredefined = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/hintergrund_pergament.jpg', fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.black))),
          Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.5))),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFFC5A059), size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 10),
                  const Text("CHARAKTER-SCHMIEDE",
                      style: TextStyle(color: Color(0xFFC5A059), fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 30),
                  _buildLabel("Wie heißt dein Charakter?"),
                  _buildTextField(_nameController, "Euer Name..."),
                  const SizedBox(height: 20),
                  _buildLabel("Geschlecht"),
                  _buildDropdown(['Männlich', 'Weiblich', 'Divers'], _selectedGender, (v) => setState(() => _selectedGender = v!)),
                  const SizedBox(height: 20),
                  _buildLabel("Schwierigkeit"),
                  _buildDropdown(['Leicht', 'Mittel', 'Schwer'], _selectedDifficulty, (v) => setState(() => _selectedDifficulty = v!)),
                  const SizedBox(height: 20),
                  _buildLabel("Welt-Setting"),
                  _buildDropdown(['Mittelalter', 'Sci-Fi', 'Piraten'], _selectedSetting, (v) => setState(() => _selectedSetting = v!)),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Checkbox(value: _isPredefined, onChanged: (v) => setState(() => _isPredefined = v!), activeColor: const Color(0xFF8A6421)),
                      const Expanded(child: Text("Ein vorgegebenes Abenteuer spielen?", style: TextStyle(color: Color(0xFFF4EAD4), fontSize: 16))),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8A6421),
                        foregroundColor: const Color(0xFFF4EAD4),
                        minimumSize: const Size(200, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFC5A059), width: 2),
                        ),
                      ),
                      onPressed: () {
                        final settings = GameSettings(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          charName: _nameController.text.isEmpty ? "Namenloser" : _nameController.text,
                          gender: _selectedGender,
                          difficulty: _selectedDifficulty,
                          setting: _selectedSetting,
                          usePredefinedAdventure: _isPredefined,
                          spieler: StartInitialisierung.erstelleSpieler(_nameController.text.isEmpty ? "Namenloser" : _nameController.text),
                        );
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ChatScreen(settings: settings)));
                      },
                      child: const Text("Abenteuer Beginnen", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(color: Color(0xFFC5A059), fontSize: 18, fontWeight: FontWeight.w600)));
  Widget _buildTextField(TextEditingController controller, String hint) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: const Color(0xFFF4EAD4), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF8A6421), width: 2)),
        child: TextField(controller: controller, decoration: InputDecoration(hintText: hint, border: InputBorder.none), style: const TextStyle(color: Color(0xFF2D1E10), fontSize: 18)),
      );
  Widget _buildDropdown(List<String> items, String current, Function(String?) onChanged) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: const Color(0xFFF4EAD4), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF8A6421), width: 2)),
        child: DropdownButton<String>(
          value: current,
          isExpanded: true,
          dropdownColor: const Color(0xFFF4EAD4),
          iconEnabledColor: const Color(0xFF8A6421),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Color(0xFF2D1E10), fontSize: 18)))).toList(),
          onChanged: onChanged,
          underline: const SizedBox(),
        ),
      );
}

// --- HAUPT CHAT SCREEN ---

class ChatScreen extends StatefulWidget {
  final GameSettings settings;
  final Map<String, dynamic>? initialSaveData; 
  final int? kampfAusgang;

  const ChatScreen({super.key, required this.settings, this.initialSaveData, this.kampfAusgang});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // BITTE HIER DEINEN EIGENEN API KEY EINSETZEN
  final String _apiKey = ""; //TODO API key eingeben
  
  late List<ChatMessage> _messages;
  late List<InventoryItem> _inventory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSaveData != null) {
      _loadFromInitialData();
    } else {
      _messages = [ChatMessage(text: "Seid gegrüßt, ${widget.settings.charName}. Euer Abenteuer im Setting '${widget.settings.setting}' beginnt nun. Was wollt ihr tun?", isUser: false)];
      _initInventory();
      _saveGame(); 
    }
    //TODO muss überarbeitet werden sodass nur die antwort angezeigt wird (Neu funktion erstellen die aufgerufen wird)
    if(widget.kampfAusgang != null) {
      if(widget.kampfAusgang == 0) {
        _sendMessage("Der Spieler hat den Kampf gewonnen. Schreib eine Siegesnarchicht.");
      } else if(widget.kampfAusgang == 1) {
        _sendMessage("Der Spieler ist aus dem Kampf entkommen. Schreib eine Narchicht wie er entkommen ist.");
      } else if(widget.kampfAusgang == 2) {
        _sendMessage("Der Spieler hat den Kampf verloren. Schreib eine Narchicht wie er Überlebt."); //TODO bei niederlage Spiel vorbei
      }
    }
  }

  void _loadFromInitialData() {
    final save = widget.initialSaveData!;
    
    final List<dynamic> savedChat = save['chat'];
    _messages = savedChat.map((msg) => ChatMessage(text: msg['text'], isUser: msg['isUser'])).toList();

    final List<dynamic> savedInv = save['inventory'] ?? [];
    _inventory = savedInv.map((item) {
      IconData icon = Icons.backpack; 
      if (item['name'].toString().contains("Schwert") || item['name'].toString().contains("Säbel") || item['name'].toString().contains("Dolch")) icon = Icons.gavel;
      if (item['name'].toString().contains("Trank") || item['name'].toString().contains("Kit") || item['name'].toString().contains("Rum")) icon = Icons.science;
      if (item['name'].toString().contains("Münzen") || item['name'].toString().contains("Gold") || item['name'].toString().contains("Credit")) icon = Icons.monetization_on;

      return InventoryItem(
        name: item['name'],
        description: item['description'],
        quantity: item['quantity'],
        icon: icon,
        iconColor: Colors.amber,
      );
    }).toList();

    _scrollToBottom();
  }

  void _initInventory() {
    if (widget.settings.setting == 'Sci-Fi') {
      _inventory = [
        InventoryItem(name: "Blaster-Pistole", description: "Modell 'Nova-7'.", quantity: 1, icon: Icons.bolt, iconColor: Colors.blue),
        InventoryItem(name: "Nanomed-Kit", description: "Heilt 30 HP.", quantity: 2, icon: Icons.science, iconColor: Colors.green),
        InventoryItem(name: "Credit-Chips", description: "Digitale Währung.", quantity: 250, icon: Icons.monetization_on, iconColor: Colors.amber),
      ];
    } else if (widget.settings.setting == 'Piraten') {
      _inventory = [
        InventoryItem(name: "Rostiger Säbel", description: "Erfüllt seinen Zweck im Nahkampf.", quantity: 1, icon: Icons.gavel, iconColor: Colors.blueGrey),
        InventoryItem(name: "Buddel edler Rum", description: "Heilt 30 HP.", quantity: 3, icon: Icons.science, iconColor: Colors.deepOrange),
        InventoryItem(name: "Golddublonen", description: "Glänzendes Beutegut.", quantity: 60, icon: Icons.monetization_on, iconColor: Colors.amber),
      ];
    } else {
      _inventory = [
        InventoryItem(name: "Eisenschwert", description: "Ein treuer Gefährte.", quantity: 1, icon: Icons.gavel, iconColor: Colors.grey),
        InventoryItem(name: "Heiltrank", description: "Heilt 30 HP.", quantity: 2, icon: Icons.science, iconColor: Colors.red),
        InventoryItem(name: "Goldmünzen", description: "Klingende Währung.", quantity: 120, icon: Icons.monetization_on, iconColor: Colors.amber),
      ];
    }
  }

  Future<void> _saveGame() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> chatJson = _messages.map((msg) => {'text': msg.text, 'isUser': msg.isUser}).toList();
    List<Map<String, dynamic>> inventoryJson = _inventory.map((item) => {'name': item.name, 'description': item.description, 'quantity': item.quantity}).toList();

    Map<String, dynamic> gameState = {
      'settings': widget.settings.toJson(),
      'chat': chatJson,
      'inventory': inventoryJson,
    };

    await prefs.setString('savegame_${widget.settings.id}', jsonEncode(gameState));
  }

  // --- LOKALES ITEM BENUTZEN ---
  bool _handleItemUsage(String text) {
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains("nutze") || lowerText.contains("trinke") || lowerText.contains("heile")) {
      String targetName = "";
      if (widget.settings.setting == 'Sci-Fi') {
        targetName = "nanomed-kit";
      } else if (widget.settings.setting == 'Piraten') {
        targetName = "rum";
      }
      else {
        targetName = "heiltrank";
      }

      try {
        final item = _inventory.firstWhere((element) => element.name.toLowerCase().contains(targetName));
        if (item.quantity > 0) {
          setState(() {
            item.quantity--;
            widget.settings.spieler.leben = (widget.settings.spieler.leben + 30).clamp(0, widget.settings.spieler.maxleben);
            _messages.add(ChatMessage(text: "Du benutzt ${item.name}. Deine Wunden schließen sich (+30 HP).", isUser: false));
            
            // WICHTIG: Wenn die Menge auf 0 fällt, löschen wir das Item komplett!
            if (item.quantity <= 0) {
              _inventory.remove(item);
            }
          });
          _saveGame();
          _scrollToBottom();
          return true;
        }
      } catch (_) {}
      
      setState(() {
        _messages.add(ChatMessage(text: "Du suchst in deinen Taschen, aber du hast keinen solchen Gegenstand mehr!", isUser: false));
      });
      _scrollToBottom();
      return true;
    }
    return false;
  }

  Future<String> _fetchRealAIResponse(String userMessage) async {
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${_apiKey.trim()}');
    
    final invList = _inventory.map((e) => "${e.name} (x${e.quantity})").join(", ");
    final chatHistory = _messages.length > 10 
        ? _messages.sublist(_messages.length - 10).map((m) => "${m.isUser ? 'Spieler' : 'Game Master'}: ${m.text}").join("\n")
        : _messages.map((m) => "${m.isUser ? 'Spieler' : 'Game Master'}: ${m.text}").join("\n");

    final systemInstruction = """
Du bist der Game Master eines interaktiven RPGs. Welt-Setting: ${widget.settings.setting}.
Aktuelles Inventar des Spielers: [$invList]. Aktuelle HP: ${widget.settings.spieler.leben}/${widget.settings.spieler.maxleben}.

Deine Aufgaben:
1. Erschaffe eine Kampagne mit einem roten Faden (3-5 Orte).
2. Halte deine Antworten atmosphärisch, aber kurz (max. 3-4 Sätze).

WICHTIGE REGELN FÜR DYNAMISCHE WERTE & ITEMS:
- ANTI-CHEAT AUFHEBEN: Wenn der Spieler versucht etwas aufzuheben, prüfe streng ob es existiert. Wenn JA, antworte normal und hänge in einer NEUEN ZEILE an: [ADD_ITEM:{"name": "Item", "desc": "Beschreibung"}]
- ITEMS VERLIEREN: Wenn der Spieler einen Gegenstand ablegt, wegwirft, ihm etwas gestohlen wird oder er einen Gegenstand abgibt, hänge an: [REMOVE_ITEM:{"name": "Name aus Inventar", "qty": 1}]
- SCHADEN / HEILUNG: Wenn der Spieler durch Fallen, Angriffe, Feuer o.ä. Schaden nimmt oder regeneriert (ohne dass er ein lokales Item auslöst), hänge an: [UPDATE_HP:-15] (für 15 Schaden) oder [UPDATE_HP:20] (für Heilung).
- KAMPF: Wenn ein Kampf startet, ende mit: [START_COMBAT:{"enemy": "Name", "hp": 50}]

Achtung: Gib immer nur die reinen Tags in neuen Zeilen am Ende an, keinen weiteren Text danach.
""";

    final requestBody = {
      "contents": [
        {
          "parts": [
            {"text": "Bisheriger Verlauf:\n$chatHistory\n\nAktuelle Aktion des Spielers: $userMessage"}
          ]
        }
      ],
      "systemInstruction": {
        "parts": [{"text": systemInstruction}]
      }
    };

    try {
      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(requestBody));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return data['candidates'][0]['content']['parts'][0]['text'];
      return "Die Magie schwand: ${data['error']['message']}";
    } catch (e) {
      return "Der Pfad ist blockiert: $e";
    }
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;
    
    setState(() {
      _isLoading = true;
      _messages.add(ChatMessage(text: text, isUser: true));
    });
    _messageController.clear();
    _scrollToBottom();
    
    if (_handleItemUsage(text)) {
      setState(() => _isLoading = false);
      return;
    }
    
    int loadingIndex = _messages.length;
    setState(() => _messages.add(ChatMessage(text: "Die Tinte schreibt...", isUser: false)));
    _scrollToBottom();
    
    String aiAnswer = await _fetchRealAIResponse(text);
    String cleanAnswer = aiAnswer;

    // --- 1. HP Updates verarbeiten --- //TODO inventar muss auf Spieler inventar angepasst werden
    final hpRegex = RegExp(r'\[UPDATE_HP:([+-]?\d+)\]');
    Iterable<RegExpMatch> hpMatches = hpRegex.allMatches(cleanAnswer);
    for (final match in hpMatches) {
      int hpChange = int.tryParse(match.group(1) ?? '0') ?? 0;
      setState(() {
        widget.settings.spieler.leben = (widget.settings.spieler.leben + hpChange).clamp(0, widget.settings.spieler.maxleben);
      });
    }
    cleanAnswer = cleanAnswer.replaceAll(hpRegex, '').trim();

    // --- 2. Items entfernen / fallen lassen ---
    final removeRegex = RegExp(r'\[REMOVE_ITEM:(\{.*?\})\]');
    Iterable<RegExpMatch> removeMatches = removeRegex.allMatches(cleanAnswer);
    for (final match in removeMatches) {
      try {
        final data = jsonDecode(match.group(1)!);
        String name = data['name'];
        int qty = data['qty'] ?? 1;
        
        setState(() {
          int idx = _inventory.indexWhere((i) => i.name.toLowerCase() == name.toLowerCase());
          if (idx != -1) {
            _inventory[idx].quantity -= qty;
            cleanAnswer += "\n\n❌ [Gegenstand verloren: $name]";
            if (_inventory[idx].quantity <= 0) {
              _inventory.removeAt(idx);
            }
          }
        });
      } catch (_) {}
    }
    cleanAnswer = cleanAnswer.replaceAll(removeRegex, '').trim();

    // --- 3. Items aufheben --- //TODO inventar muss auf Spieler inventar angepasst werden
    final addRegex = RegExp(r'\[ADD_ITEM:(\{.*?\})\]');
    Iterable<RegExpMatch> addMatches = addRegex.allMatches(cleanAnswer);
    for (final match in addMatches) {
      try {
        final data = jsonDecode(match.group(1)!);
        String name = data['name'];
        String desc = data['desc'] ?? "";
        
        setState(() {
          int existingIndex = _inventory.indexWhere((e) => e.name.toLowerCase() == name.toLowerCase());
          if (existingIndex != -1) {
            _inventory[existingIndex].quantity++;
          } else {
            _inventory.add(InventoryItem(name: name, description: desc, quantity: 1, icon: Icons.star, iconColor: Colors.amber));
          }
          cleanAnswer += "\n\n✨ [Gegenstand aufgehoben: $name]";
        });
      } catch (_) {}
    }
    cleanAnswer = cleanAnswer.replaceAll(addRegex, '').trim();

    // --- 4. Kampf auslesen ---
    final combatRegex = RegExp(r'\[START_COMBAT:(\{.*?\})\]');
    Map<String, dynamic>? combatData;
    if (combatRegex.hasMatch(cleanAnswer)) {
      try {
        combatData = jsonDecode(combatRegex.firstMatch(cleanAnswer)!.group(1)!);
      } catch (_) {}
    }
    cleanAnswer = cleanAnswer.replaceAll(combatRegex, '').trim();

    // Text aktualisieren & Lade-Zustand beenden
    setState(() {
      _messages[loadingIndex] = ChatMessage(text: cleanAnswer, isUser: false);
      _isLoading = false;
    });
    
    _scrollToBottom();
    await _saveGame(); 

    // Gegebenenfalls Kampf starten
    if (combatData != null) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BattleScreen(settings: widget.settings, initialSaveData: widget.initialSaveData, cleanAnswer: cleanAnswer),
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) { if (_scrollController.hasClients) _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildFantasyDrawer(),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/hintergrund_landschaft.jpg', fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: const Color(0xFF1E140A)))),
          Positioned.fill(child: Container(color: const Color(0xFF1E140A).withValues(alpha: 0.35))),
          SafeArea(
            child: Column(
              children: [
                // --- OBERE LEISTE MIT DYNAMISCHER HP-ANZEIGE ---
                Padding(
                  padding: const EdgeInsets.only(left: 12.0, right: 16.0, top: 12.0, bottom: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.home, color: Color(0xFFC5A059), size: 30), 
                        onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const StartScreen()), (r) => false)
                      ),
                      GestureDetector(
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
                          decoration: BoxDecoration(
                            color: const Color(0xFF8A6421).withValues(alpha: 0.85), 
                            borderRadius: BorderRadius.circular(8), 
                            border: Border.all(color: const Color(0xFFC5A059), width: 2)
                          ), 
                          child: Row(
                            children: [
                              const Icon(Icons.favorite, color: Colors.redAccent, size: 22),
                              const SizedBox(width: 6),
                              // Diese Zahl aktualisiert sich jetzt durch setState sofort!
                              Text("${widget.settings.spieler.leben}", style: const TextStyle(color: Color(0xFFF4EAD4), fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 12),
                              const Icon(Icons.menu, color: Color(0xFFF4EAD4), size: 26),
                            ],
                          )
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: ListView.builder(controller: _scrollController, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), itemCount: _messages.length, itemBuilder: (context, index) => _buildHorizontalScrollBubble(_messages[index]))),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2E3C6).withValues(alpha: _isLoading ? 0.5 : 0.9), 
                            borderRadius: BorderRadius.circular(6), 
                            border: Border.all(color: const Color(0xFF7A5821), width: 2)
                          ), 
                          child: TextField(
                            controller: _messageController, 
                            enabled: !_isLoading,
                            style: const TextStyle(color: Color(0xFF2D1E10), fontWeight: FontWeight.bold), 
                            decoration: const InputDecoration(hintText: 'Was tut ihr?', contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: InputBorder.none), 
                            onSubmitted: _sendMessage
                          )
                        )
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _isLoading ? null : () => _sendMessage(_messageController.text), 
                        child: Container(
                          width: 50, 
                          height: 50, 
                          decoration: BoxDecoration(
                            color: _isLoading ? Colors.grey : const Color(0xFF7A5821), 
                            shape: BoxShape.circle, 
                            border: Border.all(color: const Color(0xFFC5A059), width: 2)
                          ), 
                          child: const Icon(Icons.draw, color: Color(0xFFF2E3C6), size: 24)
                        )
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFantasyDrawer() {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(color: Color(0xFFF4EAD4), border: Border(right: BorderSide(color: Color(0xFF8A6421), width: 5))),
        child: Column(
          children: [
            const DrawerHeader(child: Center(child: Text("MENÜ", style: TextStyle(color: Color(0xFF2D1E10), fontSize: 36, fontWeight: FontWeight.bold)))),
            _buildDrawerItem(Icons.map, "Karte"),
            _buildDrawerItem(Icons.backpack, "Inventar", isInventory: true),
            _buildDrawerItem(Icons.person, "Status", isStatus: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, {bool isStatus = false, bool isInventory = false}) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF8A6421)),
        title: Text(title, style: const TextStyle(color: Color(0xFF2D1E10), fontSize: 22, fontWeight: FontWeight.w600)),
        onTap: () {
          Navigator.pop(context);
          if (isStatus) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => StatusScreen(settings: widget.settings)));
          } else if (isInventory) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => InventoryScreen(inventory: _inventory)));
          } else if (title == "Karte") {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MapScreen()));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (context) => GameMenuDetailScreen(title: title)));
          }
        },
      ),
    );
  }

  Widget _buildHorizontalScrollBubble(ChatMessage message) {
    final isUser = message.isUser;
    final borderColor = isUser ? const Color(0xFF8A6421) : const Color(0xFF5C4018);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: Stack(clipBehavior: Clip.none, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: const Color(0xFFF4EAD4), border: Border.symmetric(vertical: BorderSide(color: borderColor, width: 2))), child: Text(message.text, style: const TextStyle(color: Color(0xFF2D1E10), fontSize: 15, height: 1.25))),
          Positioned(top: -6, left: -2, right: -2, child: Container(height: 8, decoration: BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(4)))),
          Positioned(bottom: -6, left: -2, right: -2, child: Container(height: 8, decoration: BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(4)))),
        ]),
      ),
    );
  }
}

// --- STATUS SCREEN ---
//Alte Stateless version(bereits auf attribute und attacken angepasst)
/*
class StatusScreen extends StatelessWidget {
  final GameSettings settings;
  const StatusScreen({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/hintergrund_pergament.jpg', fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.black))),
          Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.5))),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF4EAD4),
                border: Border.all(color: const Color(0xFF8A6421), width: 4),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 15)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("HELDEN-STATUS", style: TextStyle(color: Color(0xFF2D1E10), fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const Divider(color: Color(0xFF8A6421), thickness: 2, indent: 20, endIndent: 20),
                  const SizedBox(height: 20),
                  _buildStatusRow(Icons.person, "Name", settings.charName),
                  _buildStatusRow(Icons.favorite, "Lebenspunkte", "${settings.spieler.leben} / ${settings.spieler.maxleben}"),
                  _buildStatusRow(Icons.battery_full, "Ausdauer", "${settings.spieler.ausdauer} / ${settings.spieler.maxausdauer}"),
                  _buildStatusRow(Icons.refresh, "Ausdauerregeneration", "${settings.spieler.ausdauerregeneration}"),
                  _buildStatusRow(Icons.shield, "Verteidigung", "${settings.spieler.verteidigung}"),
                  _buildStatusRow(Icons.bolt, "Geschwindigkeit", "${settings.spieler.geschwindigkeit}"),
                  _buildStatusRow(Icons.sports_mma, "Stärke", "${settings.spieler.staerke}"),

                  const SizedBox(height: 30),

                  _buildAttackenListe(),

                  const SizedBox(height: 30),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8A6421), foregroundColor: const Color(0xFFF4EAD4), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Zurück zum Abenteuer"),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8A6421), size: 28),
          const SizedBox(width: 15),
          Text("$label: ", style: const TextStyle(color: Color(0xFF5C4018), fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: const TextStyle(color: Color(0xFF2D1E10), fontSize: 20, fontWeight: FontWeight.w400, fontStyle: FontStyle.italic))),
        ],
      ),
    );
  }

  Widget _buildAttackenListe() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: Color(0xFF8A6421),
            ),
            SizedBox(width: 8),
            Text(
              "Attacken",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D1E10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Container(
          height: 220,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            border: Border.all(
              color: const Color(0xFF8A6421),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: settings.spieler.attacken.alleAttacken.isEmpty
              ? const Center(
                  child: Text(
                    "Keine Attacken vorhanden",
                    style: TextStyle(
                      color: Color(0xFF2D1E10),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount:
                      settings.spieler.attacken.alleAttacken.length,
                  itemBuilder: (context, index) {
                    final attacke =
                        settings.spieler.attacken.alleAttacken[index];

                    return Card(
                      color: const Color(0xFFF4EAD4),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: Icon(
                          attacke.aoe
                                ? Icons.blur_on
                                : attacke.aufgegner
                                    ? Icons.gps_fixed
                                    : Icons.healing,
                          color: const Color(0xFF8A6421),
                        ),
                        title: Text(
                          attacke.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black
                          ),
                        ),
                        subtitle: Text(
                          "${attacke.beschreibung}\n"
                          "Kraft: ${attacke.kraft}\n"
                          "Ausdauer Kosten: ${attacke.kosten}",
                          style: const TextStyle(
                            color: Colors.black
                          ),
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () =>
                              _attackeLoeschenDialog(index),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  
  Future<void> _attackeLoeschenDialog(int index) async {
    final attacke =
        settings.spieler.attacken.alleAttacken[index];

    final bool? loeschen = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Attacke entfernen"),
          content: Text(
            'Möchtest du die Attacke "${attacke.name}" wirklich entfernen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Nein"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Ja"),
            ),
          ],
        );
      },
    );

    if (loeschen == true) {
      setState(() {
        settings.spieler.attacken.AttackeLoeschen(index);
      });
    }
  }
}
*/

class StatusScreen extends StatefulWidget {
  final GameSettings settings;

  const StatusScreen({
    super.key,
    required this.settings,
  });

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/hintergrund_pergament.jpg',
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                color: Colors.black,
              ),
            ),
          ),

          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),

          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF4EAD4),
                border: Border.all(
                  color: const Color(0xFF8A6421),
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "HELDEN-STATUS",
                      style: TextStyle(
                        color: Color(0xFF2D1E10),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),

                    const Divider(
                      color: Color(0xFF8A6421),
                      thickness: 2,
                      indent: 20,
                      endIndent: 20,
                    ),

                    const SizedBox(height: 20),

                    _buildStatusRow(
                      Icons.person,
                      "Name",
                      widget.settings.charName,
                    ),

                    _buildStatusRow(
                      Icons.favorite,
                      "Lebenspunkte",
                      "${widget.settings.spieler.leben} / ${widget.settings.spieler.maxleben}",
                    ),

                    _buildStatusRow(
                      Icons.battery_full,
                      "Ausdauer",
                      "${widget.settings.spieler.ausdauer} / ${widget.settings.spieler.maxausdauer}",
                    ),

                    _buildStatusRow(
                      Icons.refresh,
                      "Ausdauerregeneration",
                      "${widget.settings.spieler.ausdauerregeneration}",
                    ),

                    _buildStatusRow(
                      Icons.shield,
                      "Verteidigung",
                      "${widget.settings.spieler.verteidigung}",
                    ),

                    _buildStatusRow(
                      Icons.bolt,
                      "Geschwindigkeit",
                      "${widget.settings.spieler.geschwindigkeit}",
                    ),

                    _buildStatusRow(
                      Icons.sports_mma,
                      "Stärke",
                      "${widget.settings.spieler.staerke}",
                    ),

                    const SizedBox(height: 30),

                    _buildAttackenListe(),

                    const SizedBox(height: 30),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8A6421),
                        foregroundColor: const Color(0xFFF4EAD4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Zurück zum Abenteuer",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF8A6421),
            size: 28,
          ),

          const SizedBox(width: 15),

          Text(
            "$label: ",
            style: const TextStyle(
              color: Color(0xFF5C4018),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF2D1E10),
                fontSize: 20,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttackenListe() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: Color(0xFF8A6421),
            ),
            SizedBox(width: 8),
            Text(
              "Attacken",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D1E10),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Container(
          height: 220,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            border: Border.all(
              color: const Color(0xFF8A6421),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              widget.settings.spieler.attacken.alleAttacken.isEmpty
                  ? const Center(
                      child: Text(
                        "Keine Attacken vorhanden",
                        style: TextStyle(
                          color: Color(0xFF2D1E10),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: widget
                          .settings
                          .spieler
                          .attacken
                          .alleAttacken
                          .length,
                      itemBuilder: (context, index) {
                        final attacke = widget
                            .settings
                            .spieler
                            .attacken
                            .alleAttacken[index];

                        return Card(
                          color: const Color(0xFFF4EAD4),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: Icon(
                              attacke.aoe
                                  ? Icons.blur_on
                                  : attacke.aufgegner
                                      ? Icons.gps_fixed
                                      : Icons.healing,
                              color: const Color(0xFF8A6421),
                            ),

                            title: Text(
                              attacke.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),

                            subtitle: Text(
                              "${attacke.beschreibung}\n"
                              "Kraft: ${attacke.kraft}\n"
                              "Ausdauer Kosten: ${attacke.kosten}",
                              style: const TextStyle(
                                color: Colors.black,
                              ),
                            ),

                            isThreeLine: true,

                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () =>
                                  _attackeLoeschenDialog(index),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Future<void> _attackeLoeschenDialog(int index) async {
    final attacke =
        widget.settings.spieler.attacken.alleAttacken[index];

    final bool? loeschen = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Attacke entfernen"),
          content: Text(
            'Möchtest du die Attacke "${attacke.name}" wirklich entfernen?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text("Nein"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text("Ja"),
            ),
          ],
        );
      },
    );

    if (loeschen == true) {
      setState(() {
        widget.settings.spieler.attacken.attackeLoeschen(index);
      });
    }
  }
}

// --- INVENTAR SCREEN ---
//TODO Inventar muss auf Spieler angepasst werden
class InventoryScreen extends StatelessWidget {
  final List<InventoryItem> inventory;
  const InventoryScreen({super.key, required this.inventory});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/hintergrund_pergament.jpg', fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.black))),
          Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.5))),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF4EAD4),
                border: Border.all(color: const Color(0xFF8A6421), width: 4),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 20)],
              ),
              child: Column(
                children: [
                  const Text("BEUTEL & INVENTAR", style: TextStyle(color: Color(0xFF2D1E10), fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const Divider(color: Color(0xFF8A6421), thickness: 2, indent: 10, endIndent: 10),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: inventory.length,
                      itemBuilder: (context, index) {
                        final item = inventory[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFE3C3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBA9355).withValues(alpha: 0.5), width: 1.5),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: const Color(0xFF2D1E10), borderRadius: BorderRadius.circular(6)),
                              child: Icon(item.icon, color: item.iconColor, size: 28),
                            ),
                            title: Text(item.name, style: const TextStyle(color: Color(0xFF2D1E10), fontSize: 18, fontWeight: FontWeight.bold)),
                            subtitle: Text(item.description, style: const TextStyle(color: Color(0xFF5C4018), fontSize: 13, fontStyle: FontStyle.italic)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: const Color(0xFF8A6421), borderRadius: BorderRadius.circular(12)),
                              child: Text("x${item.quantity}", style: const TextStyle(color: Color(0xFFF4EAD4), fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8A6421),
                      foregroundColor: const Color(0xFFF4EAD4),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Sack schließen", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- PLATZHALTER DETAIL SCREEN ---

class GameMenuDetailScreen extends StatelessWidget {
  final String title;
  const GameMenuDetailScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(color: const Color(0xFFF4EAD4), border: Border.all(color: const Color(0xFF8A6421), width: 4), borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(color: Color(0xFF2D1E10), fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text("Diese Chronik wird noch geschrieben...", style: TextStyle(color: Color(0xFF2D1E10), fontSize: 18, fontStyle: FontStyle.italic)),
              const SizedBox(height: 30),
              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8A6421), foregroundColor: const Color(0xFFF4EAD4)), onPressed: () => Navigator.pop(context), child: const Text("Zurück")),
            ],
          ),
        ),
      ),
    );
  }
}

// --- KAMPF SCREEN ---
//TODO kann entfernt werden
class CombatScreen extends StatelessWidget {
  final String enemyName;
  final int enemyHp;

  const CombatScreen({
    super.key, 
    required this.enemyName, 
    required this.enemyHp
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/hintergrund_pergament.jpg', fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.black))),
          Positioned.fill(child: Container(color: Colors.red.withValues(alpha: 0.3))), 
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2D1E10),
                border: Border.all(color: Colors.redAccent, width: 4),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.gavel, color: Colors.redAccent, size: 60),
                  const SizedBox(height: 10),
                  const Text("KAMPF GESTARTET!", style: TextStyle(color: Colors.redAccent, fontSize: 30, fontWeight: FontWeight.bold)),
                  const Divider(color: Colors.red, thickness: 2),
                  const SizedBox(height: 20),
                  Text("Gegner: $enemyName", style: const TextStyle(color: Color(0xFFF4EAD4), fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text("Lebenspunkte: $enemyHp HP", style: const TextStyle(color: Colors.orangeAccent, fontSize: 18)),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)
                    ),
                    onPressed: () => Navigator.pop(context), 
                    child: const Text("Kampf beenden & Fliehen", style: TextStyle(fontSize: 16)),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}