// lib/models/preuve_livraison.dart
import 'dart:convert';
import 'dart:typed_data';

class PreuveLivraison {
  final String id;
  final String livraisonId;
  final DateTime timestamp;
  final String? photoPath;
  final Uint8List? signatureBytes;
  final int nbColisVerifies;
  final String? commentaire;

  const PreuveLivraison({
    required this.id,
    required this.livraisonId,
    required this.timestamp,
    this.photoPath,
    this.signatureBytes,
    required this.nbColisVerifies,
    this.commentaire,
  });

  bool get aPhoto => photoPath != null;
  bool get aSignature => signatureBytes != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'livraison_id': livraisonId,
      'timestamp': timestamp.toIso8601String(),
      'photo_path': photoPath,
      'signature': signatureBytes != null ? base64Encode(signatureBytes!) : null,
      'nb_colis_verifies': nbColisVerifies,
      'commentaire': commentaire,
    };
  }

  factory PreuveLivraison.fromMap(Map<String, dynamic> map) {
    return PreuveLivraison(
      id: map['id'],
      livraisonId: map['livraison_id'],
      timestamp: DateTime.parse(map['timestamp']),
      photoPath: map['photo_path'],
      signatureBytes: map['signature'] != null
          ? base64Decode(map['signature'])
          : null,
      nbColisVerifies: map['nb_colis_verifies'],
      commentaire: map['commentaire'],
    );
  }
}