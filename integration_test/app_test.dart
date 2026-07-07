import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
// Wichtig: Verwende deinen echten Projektnamen
import 'package:flutter_application_1/main.dart'; 

void main() {
  // Initialisiert den Integrationstest-Treiber für das Gerät/den Emulator
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End (E2E) Spiel-Fluss Test', () {
    
    testWidgets('Sollte Charakter erstellen, Chat öffnen und Interaktion erlauben', 
        (WidgetTester tester) async {
      
      // 1. App starten
      await tester.pumpWidget(const ChatBotApp());
      await tester.pumpAndSettle(); // Warten, bis der StartScreen geladen ist

      // Überprüfen, ob wir auf dem StartScreen sind
      //expect(find.textContaining('Chroniken der Schattenwelt'), findsOneWidget);

      // 2. Auf "Spiel Erstellen" tippen
      final spielErstellenBtn = find.text('Spiel Erstellen');
      expect(spielErstellenBtn, findsOneWidget);
      await tester.tap(spielErstellenBtn);
      
      // Warten, bis die Animation zum SetupScreen beendet ist
      await tester.pumpAndSettle();

      // 3. Namen "TestHeld" in das Textfeld eingeben
      // Wir suchen das erste TextField auf dem SetupScreen
      final nameTextField = find.byType(TextField);
      expect(nameTextField, findsOneWidget);
      await tester.enterText(nameTextField, 'TestHeld');
      await tester.pumpAndSettle();

      // 4. Auf "Abenteuer Beginnen" tippen
final startBtn = find.text('Abenteuer Beginnen');
expect(startBtn, findsOneWidget);

// === HIER DIE FIX-ZEILEN EINFÜGEN ===
// Zwingt das SingleChildScrollView, so weit zu scrollen, bis der Button sichtbar ist
await tester.ensureVisible(startBtn);
await tester.pumpAndSettle(); // Warten, bis die Scroll-Animation vorbei ist
// ====================================

await tester.tap(startBtn);

// Da hier potenziell SharedPreferences geladen werden, 
// warten wir etwas länger, bis der ChatScreen da ist
await tester.pumpAndSettle(const Duration(seconds: 2));

     // 5. "Nutze Heiltrank" in den Chat eintippen
final chatInput = find.descendant(
  of: find.byType(ChatScreen),
  matching: find.byType(TextField),
);
await tester.enterText(chatInput, 'Nutze Heiltrank');
await tester.pumpAndSettle();

// === HIER DIE ZEILE ABÄNDERN ===
// Ersetze Icons.send durch Icons.draw, da das dein echtes Absende-Icon ist!
// Absendebutton (Icon) suchen und drücken
      final sendButton = find.byIcon(Icons.draw);
      expect(sendButton, findsOneWidget);
      await tester.tap(sendButton);
      
      // Warten, bis die Nachricht im UI verarbeitet wurde
      await tester.pumpAndSettle();

      // === SCHRITT 6 HIER ANPASSEN ===
      // Wir prüfen, ob unsere eingegebene Aktion erfolgreich im Chat-Verlauf angezeigt wird
      final chatBlase = find.text('Nutze Heiltrank'); 
      expect(chatBlase, findsOneWidget);
      
      // Der Test ist erfolgreich durchgelaufen, ohne dass die App bei den
      // Screen-Übergängen (Start -> Setup -> Chat) abgestürzt ist!
    });
  });
}