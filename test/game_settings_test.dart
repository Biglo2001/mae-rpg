
import 'package:flutter_application_1/Kampfsystem/start_initialirung.dart';
import 'package:flutter_test/flutter_test.dart';
// ERSETZE 'dein_projekt_name' durch deinen tatsächlichen Projektnamen
import 'package:flutter_application_1/main.dart'; 

void main() {
  group('GameSettings Unit Tests', () {
    
    test('Sollte GameSettings korrekt in ein JSON-Map konvertieren (toJson)', () {
      // 1. Arrange: Test-Objekt erstellen
      final settings = GameSettings(
        id: 'test_123',
        apiKey: '',
        charName: 'Thorin',
        gender: 'Männlich',
        difficulty: 'Schwer',
        setting: 'Mittelalter',
        usePredefinedAdventure: true,
        spieler: StartInitialisierung.erstelleSpieler("Thorin", "Mittelalter"),
      );
      // 2. Act: Methode ausführen
      final json = settings.toJson();

      // 3. Assert: Überprüfen, ob alle Keys korrekt befüllt wurden
      expect(json['id'], 'test_123');
      expect(json['char_name'], 'Thorin');
      expect(json['gender'], 'Männlich');
      expect(json['difficulty'], 'Schwer');
      expect(json['setting'], 'Mittelalter');
      expect(json['adventure_type'], 'Vorgegeben');
    });

    test('Sollte GameSettings korrekt aus einer JSON-Map laden (fromJson)', () {
      // 1. Arrange: Simuliertes JSON aus der Datenbank/SharedPreferences
      final json = {
        'id': 'test_456',
        'api_key': 'kein key',
        'char_name': 'Elyra',
        'gender': 'Weiblich',
        'difficulty': 'Leicht',
        'setting': 'Sci-Fi',
        'adventure_type': 'Prozedural',
        'spieler': StartInitialisierung.erstelleSpieler("Elyra", 'Sci-Fi').toJson(),
      };

      // 2. Act: Instanz über Factory-Methode erstellen
      final settings = GameSettings.fromJson(json);

      // 3. Assert: Werte überprüfen
      expect(settings.id, 'test_456');
      expect(settings.charName, 'Elyra');
      expect(settings.gender, 'Weiblich');
      expect(settings.difficulty, 'Leicht');
      expect(settings.setting, 'Sci-Fi');
      expect(settings.usePredefinedAdventure, false);
    });
  });
}
