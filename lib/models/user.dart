// lib/models/user.dart
class User {
  final String id;
  final String email;
  final String nom;
  final String prenom;
  final DateTime dateCreation;
  final String? phone;

  const User({
    required this.id,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.dateCreation,
    this.phone,
  });

  String get nomComplet => '$prenom $nom';
  String get initiales => '${prenom[0]}${nom[0]}'.toUpperCase();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'date_creation': dateCreation.toIso8601String(),
      'phone': phone,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      dateCreation: DateTime.parse(map['date_creation'] ?? DateTime.now().toIso8601String()),
      phone: map['phone'],
    );
  }

  User copyWith({
    String? id,
    String? email,
    String? nom,
    String? prenom,
    DateTime? dateCreation,
    String? phone,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      dateCreation: dateCreation ?? this.dateCreation,
      phone: phone ?? this.phone,
    );
  }
}