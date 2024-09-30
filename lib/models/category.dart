class Category {
  String id;
  String userId;
  String name;

  Category({
    required this.id,
    required this.userId,
    required this.name
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
    };
  }

  static Category fromMap(Map<String, dynamic> map, String documentId) {
    return Category(
      id: documentId,
      userId: map['userId'],
      name: map['name'],
    );
  }
}