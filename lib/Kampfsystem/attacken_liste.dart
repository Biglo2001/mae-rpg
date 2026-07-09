import 'attacke.dart';

// ✅ Klasse für die Attacken-Liste
class AttackenListe {
  final List<Attacke> _attacken = [];

  //Constructor
  AttackenListe();

  // ✅ Getter für die Liste
  List<Attacke> get alleAttacken => _attacken;

  // ✅ Einzelne Attacke holen
  Attacke getAttacke(int index) {
    return _attacken[index];
  }

  void attackeLoeschen(int index) {
    _attacken.removeAt(index);
  } 

  // ✅ Neue Attacke hinzufügen
  void addAttacke(Attacke attacke) {
    _attacken.add(attacke);
  }

  // ✅ toJson
  Map<String, dynamic> toJson() {
    return {
      'attacken': _attacken.map((a) => a.toJson()).toList(),
    };
  }

  // ✅ fromJson
  factory AttackenListe.fromJson(List<dynamic> json) {
    AttackenListe liste = AttackenListe();

    for (var attacke in json) {
      liste.addAttacke(
        Attacke.fromJson(attacke as Map<String, dynamic>),
      );
    }

    return liste;
  }
}