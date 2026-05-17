import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
      home: const ChatScreen(),
    );
  }
}

// --- PLATZHALTER FÜR DIE NEUEN FENSTER ---

class GameMenuDetailScreen extends StatelessWidget {
  final String title;
  const GameMenuDetailScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/hintergrund.jpg', fit: BoxFit.cover)),
          Container(color: Colors.black.withOpacity(0.6)),
          Center(
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFFF4EAD4),
                border: Border.all(color: const Color(0xFF8A6421), width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(color: Color(0xFF2D1E10), fontSize: 32, fontFamily: 'Serif', fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  const Text("Diese Chronik wird noch geschrieben...", style: TextStyle(color: Color(0xFF2D1E10), fontSize: 18, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8A6421)),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Zurück"),
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

// --- HAUPT CHAT SCREEN ---

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  final String _apiKey = "AIzaSyA0XR3uGUG4G13x3UpBoZJdfCtkv-t6tyI";

  final List<ChatMessage> _messages = [
    ChatMessage(text: "Seid gegrüßt, Wanderer. Welche Geheimnisse führen Euch heute zu mir?", isUser: false),
  ];

  Future<String> _fetchRealAIResponse(String userMessage) async {
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${_apiKey.trim()}');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{"parts": [{"text": "Du bist ein mystischer Chatbot aus einem Fantasy-RPG. Antworte kurz, altmodisch und weise. Nutzer fragt: $userMessage"}]}]
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return data['candidates'][0]['content']['parts'][0]['text'];
      return "Die Magie schwand: ${data['error']['message']}";
    } catch (e) {
      return "Der Pfad ist blockiert: $e";
    }
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() => _messages.add(ChatMessage(text: text, isUser: true)));
    _messageController.clear();
    _scrollToBottom();

    int loadingIndex = _messages.length;
    setState(() => _messages.add(ChatMessage(text: "Die Tinte schreibt...", isUser: false)));
    _scrollToBottom();

    String aiAnswer = await _fetchRealAIResponse(text);
    setState(() => _messages[loadingIndex] = ChatMessage(text: aiAnswer, isUser: false));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildFantasyDrawer(),
      body: Stack(
        children: [
          // Hintergrundbild jetzt korrekt benannt
          Positioned.fill(child: Image.asset('assets/hintergrund.jpg', fit: BoxFit.cover)),
          Positioned.fill(
            child: Container(
              color: const Color(0xFF140D07).withOpacity(0.35),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    // --- HIER IST DIE OPTIMIERTE OBERE LEISTE ---
Padding(
  padding: const EdgeInsets.only(right: 16.0, top: 12.0, bottom: 4.0), // Padding auf "right" geändert
  child: Row(
    mainAxisAlignment: MainAxisAlignment.end, // JETZT NEU: Drückt alles nach RECHTS
    children: [
      GestureDetector(
        onTap: () => _scaffoldKey.currentState?.openDrawer(),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF8A6421).withOpacity(0.85),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFC5A059), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(2, 2),
              )
            ],
          ),
          child: const Icon(Icons.menu, color: Color(0xFFF4EAD4), size: 26),
        ),
      ),
    ],
  ),
),

                    // Der Chat-Bereich
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) => _buildHorizontalScrollBubble(_messages[index]),
                      ),
                    ),

                    // Eingabebereich unten
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2E3C6).withOpacity(0.9),
                                borderRadius: BorderRadius.circular(6.0),
                                border: Border.all(color: const Color(0xFF7A5821), width: 2),
                              ),
                              child: TextField(
                                controller: _messageController,
                                style: const TextStyle(color: Color(0xFF2D1E10), fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                  hintText: 'Flüstert Eure Frage...',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: InputBorder.none,
                                ),
                                onSubmitted: _sendMessage,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => _sendMessage(_messageController.text),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF7A5821),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFC5A059), width: 2),
                              ),
                              child: const Icon(Icons.draw, color: Color(0xFFF2E3C6), size: 24),
                            ),
                          ),
                        ],
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

  Widget _buildFantasyDrawer() {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF4EAD4),
          border: Border(right: BorderSide(color: Color(0xFF8A6421), width: 5)),
        ),
        child: Column(
          children: [
            const DrawerHeader(
              child: Center(
                child: Text("MENÜ", style: TextStyle(color: Color(0xFF2D1E10), fontSize: 36, fontFamily: 'Serif', fontWeight: FontWeight.bold)),
              ),
            ),
            _buildDrawerItem(Icons.map, "Karte"),
            _buildDrawerItem(Icons.backpack, "Inventar"),
            _buildDrawerItem(Icons.person, "Status"),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF8A6421)),
      title: Text(title, style: const TextStyle(color: Color(0xFF2D1E10), fontSize: 22, fontFamily: 'Serif', fontWeight: FontWeight.w600)),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (context) => GameMenuDetailScreen(title: title)));
      },
    );
  }

  Widget _buildHorizontalScrollBubble(ChatMessage message) {
    final isUser = message.isUser;
    final borderColor = isUser ? const Color(0xFF8A6421) : const Color(0xFF5C4018);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 14.0),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF4EAD4),
                border: Border.symmetric(vertical: BorderSide(color: borderColor, width: 2)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 5, offset: const Offset(2, 3))],
              ),
              child: Text(message.text, style: const TextStyle(color: Color(0xFF2D1E10), fontSize: 15.0, fontFamily: 'Serif', height: 1.25)),
            ),
            Positioned(top: -6, left: -2, right: -2, child: _roller(borderColor, true)),
            Positioned(bottom: -6, left: -2, right: -2, child: _roller(borderColor, false)),
          ],
        ),
      ),
    );
  }

  Widget _roller(Color color, bool isTop) {
    return Container(
      height: 8,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}