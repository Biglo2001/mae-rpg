import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// ERSETZE 'dein_projekt_name' durch deinen tatsächlichen Projektnamen
import 'package:flutter_application_1/main.dart'; 

void main() {
  testWidgets('StatusScreen zeigt Charakterwerte korrekt an', (WidgetTester tester) async {
    // 1. Arrange: Scheindaten für den Zustand definieren
    final testSettings = GameSettings(
      id: '1',
      charName: 'Gandalf',
      gender: 'Männlich',
      difficulty: 'Mittel',
      setting: 'Mittelalter',
      hp: 75,
      maxHp: 100,
    );

    // 2. Act: Das Widget in der Testumgebung rendern
    await tester.pumpWidget(MaterialApp(
      home: StatusScreen(settings: testSettings),
    ));

    // 3. Assert: Suchen, ob die Texte auf dem Bildschirm existieren
    expect(find.text('HELDEN-STATUS'), findsOneWidget);
    expect(find.text('Gandalf'), findsOneWidget);
    expect(find.text('75 / 100'), findsOneWidget);
    expect(find.text('Männlich'), findsOneWidget);
    expect(find.text('Mittelalter'), findsOneWidget);
    expect(find.text('Mittel'), findsOneWidget);
  });
}