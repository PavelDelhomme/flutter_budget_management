class DeadUserModel {
  String id;
  String email;
  String name;

  DeadUserModel({
    required this.id,
    required this.email,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
    };
  }

  static DeadUserModel fromMap(Map<String, dynamic> map) {
    return DeadUserModel(
      id: map['id'],
      email: map['email'],
      name: map['name'],
    );
  }
}