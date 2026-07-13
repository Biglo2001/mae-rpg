import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Für das Kopieren in die Zwischenablage
import 'package:flutter_application_1/Kampfsystem/battle_screen.dart';
import 'package:flutter_application_1/Kampfsystem/chat_bot.dart';
import 'package:flutter_application_1/Kampfsystem/item.dart';
import 'package:flutter_application_1/Kampfsystem/item_liste.dart';
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
  final String apiKey;
  final String charName;
  final String gender;
  final String difficulty;
  final String setting;
  final bool usePredefinedAdventure;
  Spieler spieler;

  GameSettings({
    required this.id,
    required this.apiKey,
    required this.charName,
    required this.gender,
    required this.difficulty,
    required this.setting,
    required this.spieler,
    this.usePredefinedAdventure = false,
  });

  Map<String, dynamic> toJson() => {
        "id": id,
        "api_key": apiKey,
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
      apiKey: json['api_key'],
      charName: json['char_name'] ?? "Wanderer",
      gender: json['gender'] ?? "Divers",
      difficulty: json['difficulty'] ?? "Mittel",
      setting: json['setting'] ?? "Mittelalter",
      spieler: Spieler.fromJson(json['spieler']),
      usePredefinedAdventure: json['adventure_type'] == "Vorgegeben",
    );
  }
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
            child: Container(color: Colors.black.withValues(alpha: 0.4)),
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
    // await prefs.clear(); //TODO Alte Speicherdaten Stimmen nicht mit der Neuen version überein. Bei auftretenden fehlern einmal Zeile entkommentieren --> App starten und Spiele Laden --> App schließen --> zeile zum Kommentar machen
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
        apiKey: oldSettings.apiKey,
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
  final TextEditingController _apiKeyController = TextEditingController();

  String _selectedGender = 'Männlich';
  String _selectedDifficulty = 'Mittel';
  String _selectedSetting = 'Mittelalter';

  bool _isPredefined = false;

  bool _apiKeyInvalid = false;
  bool _isCheckingApiKey = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/hintergrund_pergament.jpg',
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(color: Colors.black),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFFC5A059),
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "CHARAKTER-SCHMIEDE",
                    style: TextStyle(
                      color: Color(0xFFC5A059),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),

                  _buildLabel("Ihr Google AI Studio API-Key"),

                  _buildTextField(
                    _apiKeyController,
                    "AQ. ...",
                    isApiField: true,
                  ),

                  const SizedBox(height: 20),

                  _buildLabel("Wie heißt dein Charakter?"),

                  _buildTextField(
                    _nameController,
                    "Euer Name...",
                  ),

                  const SizedBox(height: 20),

                  _buildLabel("Geschlecht"),

                  _buildDropdown(
                    ['Männlich', 'Weiblich', 'Divers'],
                    _selectedGender,
                    (v) => setState(() => _selectedGender = v!),
                  ),

                  const SizedBox(height: 20),

                  _buildLabel("Schwierigkeit"),

                  _buildDropdown(
                    ['Leicht', 'Mittel', 'Schwer'],
                    _selectedDifficulty,
                    (v) => setState(() => _selectedDifficulty = v!),
                  ),

                  const SizedBox(height: 20),

                  _buildLabel("Welt-Setting"),

                  _buildDropdown(
                    ['Mittelalter', 'Sci-Fi', 'Piraten'],
                    _selectedSetting,
                    (v) => setState(() => _selectedSetting = v!),
                  ),

                  const SizedBox(height: 30),

                  Row(
                    children: [
                      Checkbox(
                        value: _isPredefined,
                        activeColor: const Color(0xFF8A6421),
                        onChanged: (v) =>
                            setState(() => _isPredefined = v!),
                      ),
                      const Expanded(
                        child: Text(
                          "Ein vorgegebenes Abenteuer spielen?",
                          style: TextStyle(
                            color: Color(0xFFF4EAD4),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8A6421),
                        foregroundColor: const Color(0xFFF4EAD4),
                        minimumSize: const Size(220, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: Color(0xFFC5A059),
                            width: 2,
                          ),
                        ),
                      ),
                      onPressed: _isCheckingApiKey
                          ? null
                          : () async {
                              final apiKey =
                                  _apiKeyController.text.trim();

                              if (apiKey.isEmpty) {
                                setState(() {
                                  _apiKeyInvalid = true;
                                });
                                return;
                              }

                              setState(() {
                                _isCheckingApiKey = true;
                              });

                              final isValid =
                                  await _validateApiKey(apiKey);

                              setState(() {
                                _isCheckingApiKey = false;
                              });

                              if (!isValid) {
                                setState(() {
                                  _apiKeyInvalid = true;
                                });

                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Der eingegebene API-Key ist ungültig.",
                                    ),
                                  ),
                                );
                                return;
                              }

                              final name =
                                  _nameController.text.isEmpty
                                      ? "Namenloser"
                                      : _nameController.text;

                              final settings = GameSettings(
                                id: DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString(),
                                apiKey: apiKey,
                                charName: name,
                                gender: _selectedGender,
                                difficulty:
                                    _selectedDifficulty,
                                setting: _selectedSetting,
                                usePredefinedAdventure:
                                    _isPredefined,
                                spieler:
                                    StartInitialisierung
                                        .erstelleSpieler(
                                  name,
                                  _selectedSetting,
                                ),
                              );
                              if (!context.mounted) return;
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ChatScreen(
                                    settings: settings,
                                  ),
                                ),
                              );
                            },
                      child: _isCheckingApiKey
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child:
                                  CircularProgressIndicator(
                                color:
                                    Color(0xFFF4EAD4),
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              "Abenteuer Beginnen",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFC5A059),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool isApiField = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF4EAD4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isApiField && _apiKeyInvalid
                  ? Colors.red
                  : const Color(0xFF8A6421),
              width: 2,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: isApiField,
            onChanged: (_) {
              if (_apiKeyInvalid) {
                setState(() {
                  _apiKeyInvalid = false;
                });
              }
            },
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
            ),
            style: const TextStyle(
              color: Color(0xFF2D1E10),
              fontSize: 18,
            ),
          ),
        ),
        if (isApiField && _apiKeyInvalid)
          const Padding(
            padding: EdgeInsets.only(
              left: 4,
              top: 6,
            ),
            child: Text(
              "❌ Ungültiger Google AI Studio API-Key",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDropdown(
    List<String> items,
    String current,
    Function(String?) onChanged,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EAD4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF8A6421),
          width: 2,
        ),
      ),
      child: DropdownButton<String>(
        value: current,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: const Color(0xFFF4EAD4),
        iconEnabledColor: const Color(0xFF8A6421),
        items: items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(
                  e,
                  style: const TextStyle(
                    color: Color(0xFF2D1E10),
                    fontSize: 18,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Future<bool> _validateApiKey(String apiKey) async {
    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent?key=${apiKey.trim()}',),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": "test"}
              ]
            }
          ]
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }
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
  late Chatbot cb;
  
  late List<ChatMessage> _messages;
 // late List<InventoryItem> _inventory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    cb = Chatbot(settings: widget.settings);
    if (widget.initialSaveData != null) {
     _loadFromInitialData();
    } else {
      _messages = [ChatMessage(text: _generateIntroText(), isUser: false)];
      //_initInventory();
      _saveGame(); 
    }
  }

  // Dynamischer Intro-Text basierend auf dem Welt-Setting und Abenteuer vorgegeben
  String _generateIntroText() {
    String name = widget.settings.charName;
    String anrede = widget.settings.gender == 'Männlich' ? 'Abenteurer' : (widget.settings.gender == 'Weiblich' ? 'Abenteurerin' : 'Wanderer');

    if(widget.settings.usePredefinedAdventure) {
      if (widget.settings.setting == 'Sci-Fi') {
        return "Systeme online... Seid gegrüßt, $anrede $name. Ihr erwacht aus dem Kryoschlaf auf der Orbitalstation 'Aegis-IV'. Die Notbeleuchtung flackert rot und dichte Rauchschwaden ziehen durch die Gänge. Euer primäres Ziel ist es, die Brücke zu erreichen, das unbekannte Alien-Notsignal zu entschlüsseln und die Kernreaktoren zu stabilisieren, bevor die Station in die Atmosphäre stürzt. Was tut ihr?";
      } else if (widget.settings.setting == 'Piraten') {
        return "Ahoi, $anrede $name! Die Gischt peitscht euch ins Gesicht, als ihr in einer schummrigen Spelunke im Hafen von Tortuga sitzt. Vor euch liegt eine vergilbte Pergamentkarte, die den Weg zur sagenumwobenen 'Insel der verlorenen Seelen' weist. Euer Ziel ist es, eine Crew anzuheuern, die Blockade der königlichen Marine zu durchbrechen und das verfluchte Azteken-Gold zu bergen. Was tut ihr?";
      } else {
        // Standard: Mittelalter
        return "Seid gegrüßt, $anrede $name. Ein dichter Nebel liegt über dem Düsterwald, als ihr vor den massiven, moosbewachsenen Toren der vergessenen Festung 'Eisengrab' steht. Legenden besagen, dass tief in den Katakomben das entwendete Sonnen-Relikt eures Ordens ruht. Euer Ziel ist es, unbemerkt einzudringen, die Wachen zu umgehen oder zu bezwingen und das Relikt zu sichern. Was tut ihr?";
      }
    } else {
      if (widget.settings.setting == 'Sci-Fi') {
        return "Systeme online... Seid gegrüßt, $anrede $name. Was tut ihr?";
      } else if (widget.settings.setting == 'Piraten') {
        return "Ahoi, $anrede $name! Was tut ihr?";
      } else {
        // Standard: Mittelalter
        return "Seid gegrüßt, $anrede $name. Was tut ihr?";
      }
    }
  }

   void _loadFromInitialData() {
    final save = widget.initialSaveData!;
    
    final List<dynamic> savedChat = save['chat'];
    _messages = savedChat.map((msg) => ChatMessage(text: msg['text'], isUser: msg['isUser'])).toList();
    _scrollToBottom();
  }

  Future<void> _saveGame() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> chatJson = _messages.map((msg) => {'text': msg.text, 'isUser': msg.isUser}).toList();
    //List<Map<String, dynamic>> inventoryJson = _inventory.map((item) => {'name': item.name, 'description': item.description, 'quantity': item.quantity}).toList();

    Map<String, dynamic> gameState = {
      'settings': widget.settings.toJson(),
      'chat': chatJson,
     // 'inventory': inventoryJson,
    };

    await prefs.setString('savegame_${widget.settings.id}', jsonEncode(gameState));
  }

  Future<String> _fetchRealAIResponse(String userMessage) async {
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent?key=${widget.settings.apiKey.trim()}');
    
    final invList = widget.settings.spieler.items.toJson();
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
      - Du kannst immer nur eine der folgenden option wählen:

      - AUFHEBEN: Wenn der Spieler versucht etwas aufzuheben, prüfe streng ob es existiert. Wenn JA, antworte normal und hänge in einer NEUEN ZEILE an: [ADD_ITEM:{"name": "Item", "desc": "Beschreibung"}]. Es soll nur möglich sein Gegenstände aufzuheben, die den Spieler Heilen, einem Gegner schaden verursachen oder Flächenschaden verursachen.
      - HEILENDE ITEMS BENUTZEN: Wenn der Spieler einen heilenden Gegenstand benutzt (wenn diese methode benutzt wird ist ITEM VERLIEREN nicht notwendig), hänge an: [HEALING_ITEM:{"name": "Name"}]
      - ITEMS VERLIEREN: Wenn der Spieler einen Gegenstand ablegt, wegwirft, ihm etwas gestohlen wird oder er einen Gegenstand benutz (mit ausnahem von Heilenden Gegenständen), hänge an: [REMOVE_ITEM:{"name": "Name"}]
      - SCHADEN / HEILUNG: Wenn der Spieler durch Events in der Story Leben verliert oder regeneriert (ohne dass er ein item benutz), hänge an: [UPDATE_HP:-15] (für 15 Schaden) oder [UPDATE_HP:20] (für Heilung).
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

  Future<String> _fetchAfterBattleResponse(int gewonnen) async {
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent?key=${widget.settings.apiKey.trim()}');

    final chatHistory = _messages.length > 3 
        ? _messages.sublist(_messages.length - 3).map((m) => "${m.isUser ? 'Spieler' : 'Game Master'}: ${m.text}").join("\n")
        : _messages.map((m) => "${m.isUser ? 'Spieler' : 'Game Master'}: ${m.text}").join("\n");

    final systemInstruction = """
      Du bist der Game Master eines interaktiven RPGs. Welt-Setting: ${widget.settings.setting}.
      Aktuelle HP: ${widget.settings.spieler.leben}/${widget.settings.spieler.maxleben}.

      Bedingung:
      - Der Kampf wurde beendet. Der ausgang ist $gewonnen. 0 == Gewonnen || 1 == Entkommen || 2 == Verloren.
      - Der Kampf selbst soll nicht beschrieben werden.
      - Halte deine Antworten atmosphärisch, aber kurz (max. 3-4 Sätze).

      Deine Aufgabe:
      - wenn Gewonnen: "Der Spieler hat den Kampf gewonnen. Schreib eine Siegesnachricht."
      - wenn Entkommen: "Der Spieler ist aus dem Kampf entkommen. Schreib eine Nachricht wie er entkommen ist."
      - wenn Verloren: "Der Spieler hat den Kampf verloren. Schreib eine Nachricht wie er grade so überlebt."
      """;

    final requestBody = {
      "contents": [
        {
          "parts": [
            {"text": "Bisheriger Verlauf:\n$chatHistory\n"}
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

    int loadingIndex = _messages.length;
    setState(() => _messages.add(ChatMessage(text: "Die Tinte schreibt...", isUser: false)));
    _scrollToBottom();
    
    String aiAnswer = await _fetchRealAIResponse(text);
    String cleanAnswer = aiAnswer;

    // --- 1. HP Updates verarbeiten ---
    final hpRegex = RegExp(r'\[UPDATE_HP:([+-]?\d+)\]');
    Iterable<RegExpMatch> hpMatches = hpRegex.allMatches(cleanAnswer);
    for (final match in hpMatches) {
      int hpChange = int.tryParse(match.group(1) ?? '0') ?? 0;
      setState(() {
        widget.settings.spieler.leben = (widget.settings.spieler.leben + hpChange).clamp(1, widget.settings.spieler.maxleben);
      });
    }
    cleanAnswer = cleanAnswer.replaceAll(hpRegex, '').trim();

    // --- 2. Heilende Items benutzen ---
    final healingRegex = RegExp(r'\[HEALING_ITEM:(\{.*?\})\]');
    Iterable<RegExpMatch> healingMatches = healingRegex.allMatches(cleanAnswer);
    for (final match in healingMatches) {
      try {
        final data = jsonDecode(match.group(1)!);
        String name = data['name'];

        int idx = widget.settings.spieler.items.getIndex(name);
        setState(() {
          if (idx != 999) {
            Item i = widget.settings.spieler.items.getItem(idx);

            //wenn das item ein Heilgegenstand ist heile den Spieler
            if(i.aoe == false && i.aufgegner == false) {
              if( widget.settings.spieler.leben + (i.kraft*widget.settings.spieler.staerke).round() > widget.settings.spieler.maxleben) {
                widget.settings.spieler.leben =  widget.settings.spieler.maxleben;
              } else {
                widget.settings.spieler.leben += (i.kraft*widget.settings.spieler.staerke).round();
              }
            }

            cleanAnswer += "\n\n❤️ [Leben durch $name wiederhergestellt]";
            widget.settings.spieler.items.entferenItem(i); 
          } else {
            cleanAnswer += "\n\n\u2764\uFE0F [Gegenstand befindet sich nicht im Inventar: $name]";
          }
        });
      } catch (_) {}
    }
    cleanAnswer = cleanAnswer.replaceAll(healingRegex, '').trim();

    // --- 3. Items entfernen / fallen lassen ---
    final removeRegex = RegExp(r'\[REMOVE_ITEM:(\{.*?\})\]');
    Iterable<RegExpMatch> removeMatches = removeRegex.allMatches(cleanAnswer);
    for (final match in removeMatches) {
      try {
        final data = jsonDecode(match.group(1)!);
        String name = data['name'];

        int idx = widget.settings.spieler.items.getIndex(name);
        setState(() {
          if (idx != 999) {
            Item i = widget.settings.spieler.items.getItem(idx);
            cleanAnswer += "\n\n❌ [Gegenstand verloren: $name]";
            widget.settings.spieler.items.entferenItem(i); 
          } else {
            cleanAnswer += "\n\n❌ [Gegenstand befindet sich nicht im Inventar: $name]";
          }
        });
      } catch (_) {}
    }
    cleanAnswer = cleanAnswer.replaceAll(removeRegex, '').trim();

    // --- 4. Items aufheben ---
    final addRegex = RegExp(r'\[ADD_ITEM:(\{[\s\S]*?\})\]');

    Iterable<RegExpMatch> addMatches = addRegex.allMatches(cleanAnswer);
    for (final match in addMatches) {
      try {
        final data = jsonDecode(match.group(1)!);
        String name = data['name']?.toString() ?? 'Unbekanntes Item';
        String desc = data['desc']?.toString() ?? '';
        Item neu = await cb.erstelleItem(name, desc, widget.settings);
        setState(() {
          widget.settings.spieler.items.addItem(neu);
          cleanAnswer += "\n\n✨ [Gegenstand aufgehoben: $name]";
        });
      } catch (e, s) {
          debugPrint("ADD_ITEM Error: $e");
          debugPrintStack(stackTrace: s);
      }
    }
    cleanAnswer = cleanAnswer.replaceAll(addRegex, '').trim();

    // --- 5. Kampf auslesen ---
    final combatRegex = RegExp(r'\[START_COMBAT:(\{.*?\})\]');
    Map<String, dynamic>? combatData;
    if (combatRegex.hasMatch(cleanAnswer)) {
      try {
        combatData = jsonDecode(combatRegex.firstMatch(cleanAnswer)!.group(1)!);

      } catch (_) {}
    }
    cleanAnswer = cleanAnswer.replaceAll(combatRegex, '').trim();

    setState(() {
      _messages[loadingIndex] = ChatMessage(text: cleanAnswer, isUser: false);
      _isLoading = false;
    });
    
    _scrollToBottom();
    await _saveGame(); 
    
    if (combatData != null) {
      if (!mounted) return;
      final int kampfAusgang = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BattleScreen(settings: widget.settings, initialSaveData: widget.initialSaveData, cleanAnswer: cleanAnswer),
        ),
      );

      int afterBattleloadingIndex = _messages.length;
      setState((){ _messages.add(ChatMessage(text: "Die Tinte schreibt...", isUser: false)); _isLoading = true;});
      _scrollToBottom();

      //Kampfausgang massage
      String msg = await _fetchAfterBattleResponse(kampfAusgang);
      setState(() {
        _messages[afterBattleloadingIndex] = ChatMessage(text: msg, isUser: false);
        _isLoading = false;
      });
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
            Navigator.push(context, MaterialPageRoute(builder: (context) => InventoryScreen(inventory: widget.settings.spieler.items)));
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
              errorBuilder: (c, e, s) => Container(color: Colors.black),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
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
                      child: const Text("Zurück zum Abenteuer"),
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

  Widget _buildStatusRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8A6421), size: 28),
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
            Icon(Icons.auto_awesome, color: Color(0xFF8A6421)),
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
          child: widget.settings.spieler.attacken.alleAttacken.isEmpty
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
                  itemCount: widget.settings.spieler.attacken.alleAttacken.length,
                  itemBuilder: (context, index) {
                    final attacke = widget.settings.spieler.attacken.alleAttacken[index];

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
                          style: const TextStyle(color: Colors.black),
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _attackeLoeschenDialog(index),
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
    final attacke = widget.settings.spieler.attacken.alleAttacken[index];

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
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Nein"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
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
class InventoryScreen extends StatelessWidget {
  final ItemListe inventory;
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
      itemCount: inventory.getAnzahl(),
      itemBuilder: (context, index) {
        final item = inventory.getItem(index);
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEFE3C3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFBA9355).withValues(alpha: 0.5), width: 1.5),
          ),
          child: ListTile(
            // Ein festes, atmosphärisches Icon passend für ein RPG-Item
            leading: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2D1E10), 
                borderRadius: BorderRadius.circular(6),
              ),
              child: !item.aoe && !item.aufgegner
                        ? const Icon(Icons.healing, color: Colors.green, size: 28)
                        : item.aoe && item.aufgegner
                            ? const Icon(Icons.blur_on, color: Colors.purple, size: 28)
                            : !item.aoe && item.aufgegner
                                ? const Icon(Icons.gps_fixed, color: Colors.red, size: 28)
                                : const Icon(Icons.auto_awesome, color: Color(0xFFBA9355), size: 28),
            ),
            title: Text(
              item.name, 
              style: const TextStyle(color: Color(0xFF2D1E10), fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // "item.beschreibung" statt "item.description" passend zu deiner Modell-Klasse
            subtitle: Text(
              item.beschreibung, 
              style: const TextStyle(color: Color(0xFF5C4018), fontSize: 13, fontStyle: FontStyle.italic),
            ),
            // Optional: Zeigt die Kraft des Items auf der rechten Seite an
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF8A6421), 
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Kraft: ${item.kraft}", 
                style: const TextStyle(color: Color(0xFFF4EAD4), fontSize: 14, fontWeight: FontWeight.bold),
              ),
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
    child: const Text("Inventar schließen", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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