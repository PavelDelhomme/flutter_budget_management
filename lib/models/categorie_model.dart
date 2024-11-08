class Categorie {
  String id;
  String userId;
  String name;

  Categorie({
    required this.id,
    required this.userId,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "userId": userId,
      "name": name,
    };
  }

  static Categorie fromMap(Map<String, dynamic> map) {
    return Categorie(id: map['id'], userId: map['userId'], name: map['name']);
  }
}
