class CategoryModel {
  String name;
  double allocatedAmount;
  double spentAmount;

  CategoryModel({
    required this.name,
    required this.allocatedAmount,
    this.spentAmount = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'allocatedAmount': allocatedAmount,
      'spentAmount': spentAmount,
    };
  }

  static CategoryModel fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      name: map['name'],
      allocatedAmount: map['allocatedAmount'],
      spentAmount: map['spentAmount'],
    );
  }
}