class DeadCategoryModel {
  String name;
  double allocatedAmount;
  double spentAmount;

  DeadCategoryModel({
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

  static DeadCategoryModel fromMap(Map<String, dynamic> map) {
    return DeadCategoryModel(
      name: map['name'],
      allocatedAmount: map['allocatedAmount'],
      spentAmount: map['spentAmount'],
    );
  }
}