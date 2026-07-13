/*
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Kampfsystem/start_initialirung.dart';
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
      spieler: StartInitialisierung.erstelleSpieler("Gandalf", "Mittelalter"),
    );

    // 2. Act: Das Widget in der Testumgebung rendern
    await tester.pumpWidget(MaterialApp(
      home: StatusScreen(settings: testSettings),
    ));

    // 3. Assert: Suchen, ob die Texte auf dem Bildschirm existieren
    expect(find.text('HELDEN-STATUS'), findsOneWidget);
    expect(find.text('Gandalf'), findsOneWidget);
  });
}*/