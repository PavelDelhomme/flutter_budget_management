class CategoryModel {
  String name;
  double spentAmount;

  CategoryModel({
    required this.name,
    this.spentAmount = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'spentAmount': spentAmount,
    };
  }

  static CategoryModel fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      name: map['name'],
      spentAmount: map['spentAmount'],
    );
  }
}