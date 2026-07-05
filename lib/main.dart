import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/map_screen.dart';

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

  GameSettings({
    required this.id,
    required this.charName,
    required this.gender,
    required this.difficulty,
    required this.setting,
    this.usePredefinedAdventure = false,
  });

  Map<String, dynamic> toJson() => {
        "id": id,
        "char_name": charName,
        "gender": gender,
        "difficulty": difficulty,
        "setting": setting,
        "adventure_type": usePredefinedAdventure ? "Vorgegeben" : "Prozedural",
      };

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      charName: json['char_name'] ?? "Wanderer",
      gender: json['gender'] ?? "Divers",
      difficulty: json['difficulty'] ?? "Mittel",
      setting: json['setting'] ?? "Mittelalter",
      usePredefinedAdventure: json['adventure_type'] == "Vorgegeben",
    );
  }
}

class InventoryItem {
  final String name;
  final String description;
  final int quantity;
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
            child: Image.asset('assets/hintergrund_pergament.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.4)),
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
                  text: "Spiel Laden",
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
        backgroundColor: const Color(0xFF8A6421).withOpacity(0.9),
        foregroundColor: const Color(0xFFF4EAD4),
        minimumSize: const Size(250, 55),
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

// --- SPIELSTÄNDE AUSWAHL SCREEN ---

class SaveGameListScreen extends StatefulWidget {
  const SaveGameListScreen({super.key});

  @override
  State<SaveGameListScreen> createState() => _SaveGameListScreenState();
}

class _SaveGameListScreenState extends State<SaveGameListScreen> {
  List<Map<String, dynamic>> _saveGames = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSaveGameList();
  }

  Future<void> _loadSaveGameList() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('savegame_'));
    
    List<Map<String, dynamic>> loadedSaves = [];
    for (String key in keys) {
      try {
        final data = jsonDecode(prefs.getString(key) ?? '');
        loadedSaves.add(data);
      } catch (e) {
        print("Fehler beim Parsen von Speicherstand $key: $e");
      }
    }

    // Neueste Spielstände oben anzeigen
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/hintergrund_pergament.jpg', fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.5))),
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
                  const Text("GESPEICHERTE CHRONIKEN",
                      style: TextStyle(color: Color(0xFFC5A059), fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
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
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                                        onPressed: () => _deleteSaveGame(settings.id),
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
          Positioned.fill(child: Image.asset('assets/hintergrund_pergament.jpg', fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.5))),
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

  const ChatScreen({super.key, required this.settings, this.initialSaveData});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // BITTE HIER DEINEN EIGENEN API KEY EINSETZEN
  final String _apiKey = ""; 
  
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
      _saveGame(); // Direkt nach Start initial sichern
    }
  }

  void _loadFromInitialData() {
    final save = widget.initialSaveData!;
    
    // Chat wiederherstellen
    final List<dynamic> savedChat = save['chat'];
    _messages = savedChat.map((msg) => ChatMessage(text: msg['text'], isUser: msg['isUser'])).toList();

    // Inventar wiederherstellen
    final List<dynamic> savedInv = save['inventory'];
    _inventory = savedInv.map((item) {
      IconData icon = Icons.backpack; 
      if (item['name'].toString().contains("Schwert") || item['name'].toString().contains("Säbel")) icon = Icons.gavel;
      if (item['name'].toString().contains("Trank") || item['name'].toString().contains("Rum")) icon = Icons.science;
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
        InventoryItem(name: "Blaster-Pistole", description: "Modell 'Nova-7'. Energiegeladen und präzise.", quantity: 1, icon: Icons.bolt, iconColor: Colors.blue),
        InventoryItem(name: "Plasma-Schild", description: "Tragbarer Deflektor gegen Laserbeschuss.", quantity: 1, icon: Icons.shield, iconColor: Colors.cyan),
        InventoryItem(name: "Nanomed-Kit", description: "Heilt zelluläre Wunden vollautomatisch.", quantity: 2, icon: Icons.biotech, iconColor: Colors.green),
        InventoryItem(name: "Credit-Chips", description: "Digitale galaktische Währung.", quantity: 250, icon: Icons.monetization_on, iconColor: Colors.amber),
      ];
    } else if (widget.settings.setting == 'Piraten') {
      _inventory = [
        InventoryItem(name: "Rostiger Säbel", description: "Erfüllt seinen Zweck im Nahkampf.", quantity: 1, icon: Icons.gavel, iconColor: Colors.blueGrey),
        InventoryItem(name: "Kompass des Schicksals", description: "Zeigt nicht nach Norden, sondern wohin man will.", quantity: 1, icon: Icons.explore, iconColor: Colors.brown),
        InventoryItem(name: "Buddel edler Rum", description: "Gut für die Moral der Crew.", quantity: 3, icon: Icons.science, iconColor: Colors.deepOrange),
        InventoryItem(name: "Golddublonen", description: "Glänzendes Beutegut aus spanischen Galeonen.", quantity: 60, icon: Icons.monetization_on, iconColor: Colors.amber),
      ];
    } else {
      _inventory = [
        InventoryItem(name: "Eisenschwert", description: "Ein treuer, scharfer Gefährte.", quantity: 1, icon: Icons.gavel, iconColor: Colors.grey),
        InventoryItem(name: "Ritter-Schild", description: "Bemalt mit dem Wappen des Reiches.", quantity: 1, icon: Icons.shield, iconColor: Colors.brown),
        InventoryItem(name: "Heiltrank", description: "Ein süßlich schmeckendes, rotes Elixier.", quantity: 2, icon: Icons.science, iconColor: Colors.red),
        InventoryItem(name: "Goldmünzen", description: "Klingende Währung für Händler und Tavernen.", quantity: 120, icon: Icons.monetization_on, iconColor: Colors.amber),
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

  Future<String> _fetchRealAIResponse(String userMessage) async {
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${_apiKey.trim()}');
    final contextData = jsonEncode(widget.settings.toJson());
    
    final systemInstruction = """
Du bist der Game Master eines interaktiven RPGs. Spieldaten: $contextData. Welt-Setting: ${widget.settings.setting}.

Deine Aufgaben:
1. Erschaffe eine Kampagne mit einem roten Faden, bestehend aus 3-5 zusammenhängenden Orten.
2. Jeder Ort bietet NPCs zum Interagieren, Gegenstände zum Untersuchen und mindestens eine Quest.
3. Der Spieler kann Gegenstände/Items finden, die nützlich für ihn sind.
4. Halte deine Antworten atmosphärisch, aber kurz (max. 3-4 Sätze), um das Spiel flüssig zu halten.

WICHTIG - KAMPFSYSTEM:
Wenn ein Kampf ausbricht, füge AM ENDE deiner Antwort in einer eigenen neuen Zeile EXAKT folgendes ein:
[START_COMBAT:{"enemy": "Name des Gegners", "hp": 50, "danger": "Mittel"}]
Schreibe danach absolut nichts mehr!
""";

    final requestBody = {
      "contents": [
        {
          "parts": [{"text": userMessage}]
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
    
    if (aiAnswer.contains('[START_COMBAT:')) {
      final startIndex = aiAnswer.indexOf('[START_COMBAT:');
      final endIndex = aiAnswer.indexOf(']', startIndex);
      
      if (startIndex != -1 && endIndex != -1) {
        final combatDataString = aiAnswer.substring(startIndex + 14, endIndex);
        final cleanAnswer = aiAnswer.substring(0, startIndex).trim();
        
        setState(() {
          _messages[loadingIndex] = ChatMessage(text: cleanAnswer, isUser: false);
          _isLoading = false;
        });
        _scrollToBottom();
        await _saveGame(); // Speichern vor dem Kampf

        try {
          final Map<String, dynamic> combatData = jsonDecode(combatDataString);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CombatScreen(
                enemyName: combatData['enemy'] ?? "Unbekannter Gegner",
                enemyHp: combatData['hp'] ?? 50,
              ),
            ),
          );
        } catch (e) {
          print("Fehler beim Parsen der Kampfdaten: $e");
        }
        return; 
      }
    }
    
    setState(() {
      _messages[loadingIndex] = ChatMessage(text: aiAnswer, isUser: false);
      _isLoading = false;
    });
    _scrollToBottom();
    await _saveGame(); 
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
          Positioned.fill(child: Image.asset('assets/hintergrund_landschaft.jpg', fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: const Color(0xFF1E140A).withOpacity(0.35))),
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
                          padding: const EdgeInsets.all(10), 
                          decoration: BoxDecoration(
                            color: const Color(0xFF8A6421).withOpacity(0.85), 
                            borderRadius: BorderRadius.circular(8), 
                            border: Border.all(color: const Color(0xFFC5A059), width: 2)
                          ), 
                          child: const Icon(Icons.menu, color: Color(0xFFF4EAD4), size: 26)
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
                            color: const Color(0xFFF2E3C6).withOpacity(_isLoading ? 0.5 : 0.9), 
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

class StatusScreen extends StatelessWidget {
  final GameSettings settings;
  const StatusScreen({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/hintergrund_pergament.jpg', fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.5))),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF4EAD4),
                border: Border.all(color: const Color(0xFF8A6421), width: 4),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 15)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("HELDEN-STATUS", style: TextStyle(color: Color(0xFF2D1E10), fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const Divider(color: Color(0xFF8A6421), thickness: 2, indent: 20, endIndent: 20),
                  const SizedBox(height: 20),
                  _buildStatusRow(Icons.person, "Name", settings.charName),
                  _buildStatusRow(Icons.wc, "Geschlecht", settings.gender),
                  _buildStatusRow(Icons.landscape, "Welt", settings.setting),
                  _buildStatusRow(Icons.bolt, "Schwierigkeit", settings.difficulty),
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
}

// --- INVENTAR SCREEN ---

class InventoryScreen extends StatelessWidget {
  final List<InventoryItem> inventory;
  const InventoryScreen({super.key, required this.inventory});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/hintergrund_pergament.jpg', fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.5))),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF4EAD4),
                border: Border.all(color: const Color(0xFF8A6421), width: 4),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 20)],
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
                            border: Border.all(color: const Color(0xFFBA9355).withOpacity(0.5), width: 1.5),
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
          Positioned.fill(child: Image.asset('assets/hintergrund_pergament.jpg', fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: Colors.red.withOpacity(0.3))), 
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
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
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