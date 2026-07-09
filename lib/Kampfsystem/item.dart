class Item {
  final String name;
  final String beschreibung;
  final double kraft;
  final bool aufgegner;
  final bool aoe;

  Item({
    required this.name,
    required this.beschreibung,
    required this.kraft,
    required this.aufgegner,
    required this.aoe
  });

  //toJson Funktion
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'beschreibung': beschreibung,
      'kraft': kraft,
      'aufgegner': aufgegner,
      'aoe': aoe
    };
  }
  //FromJson
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      name: json['name'],
      beschreibung: json['beschreibung'],
      kraft: json['kraft'],
      aufgegner: json['aufgegner'],
      aoe: json['aoe'],
    );
  }

}
