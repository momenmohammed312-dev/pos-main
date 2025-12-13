class User {
  final int? id;
  final String name;
  final String role;
  final String? pin;

  User({this.id, required this.name, this.role = 'cashier', this.pin});

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'role': role,
        'pin': pin,
      };
}
