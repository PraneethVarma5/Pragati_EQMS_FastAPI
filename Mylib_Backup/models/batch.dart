class Batch {
  String id;

  String name;

  String description;

  DateTime createdOn;

  bool active;

  Batch({
    required this.id,
    required this.name,
    required this.description,
    required this.createdOn,
    this.active = true,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "description": description,
      "createdOn": createdOn.toIso8601String(),
      "active": active,
    };
  }

  factory Batch.fromMap(
      Map<dynamic, dynamic> map,
      ) {
    return Batch(
      id: map["id"],
      name: map["name"],
      description: map["description"],
      createdOn: DateTime.parse(
        map["createdOn"],
      ),
      active: map["active"] ?? true,
    );
  }
}