class CategoryModel {
  String id;
  String userId;
  String name;

  CategoryModel({
    required this.id,
    required this.userId,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
    };
  }

  static CategoryModel fromMap(Map<String, dynamic> map, String documentId) {
    return CategoryModel(
      id: documentId,
      userId: map['userId'],
      name: map['name'],
    );
  }
}
