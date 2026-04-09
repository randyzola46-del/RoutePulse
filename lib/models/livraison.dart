import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum StatutLivraison {
  enAttente,
  enCours,
  livree,
  aReporter,
  annulee,
}

extension StatutLivraisonX on StatutLivraison {
  String get label {
    switch (this) {
      case StatutLivraison.enAttente:
        return 'En attente';
      case StatutLivraison.enCours:
        return 'En cours';
      case StatutLivraison.livree:
        return 'Livrée';
      case StatutLivraison.aReporter:
        return 'À reporter';
      case StatutLivraison.annulee:
        return 'Annulée';
    }
  }

  bool get isFinal {
    return this == StatutLivraison.livree || this == StatutLivraison.annulee;
  }

  List<StatutLivraison> get availableActions {
    switch (this) {
      case StatutLivraison.enAttente:
        return [StatutLivraison.enCours];
      case StatutLivraison.enCours:
        return [StatutLivraison.livree, StatutLivraison.annulee, StatutLivraison.aReporter];
      case StatutLivraison.aReporter:
        return [StatutLivraison.enAttente, StatutLivraison.annulee];
      case StatutLivraison.livree:
      case StatutLivraison.annulee:
        return [];
    }
  }


  String get actionLabel {
    switch (this) {
      case StatutLivraison.enCours:
        return 'Démarrer la livraison';
      case StatutLivraison.livree:
        return 'Livrée (succès)';
      case StatutLivraison.annulee:
        return 'Annulée (échec)';
      case StatutLivraison.aReporter:
        return 'Reporter à plus tard';
      case StatutLivraison.enAttente:
        return 'Remettre en attente';
    }
  }

  //Icône pour chaque action
  IconData get actionIcon {
    switch (this) {
      case StatutLivraison.enCours:
        return Icons.play_arrow;
      case StatutLivraison.livree:
        return Icons.check_circle;
      case StatutLivraison.annulee:
        return Icons.cancel;
      case StatutLivraison.aReporter:
        return Icons.schedule;
      case StatutLivraison.enAttente:
        return Icons.refresh;
    }
  }
}

class Livraison {
  final String id;
  final String nomClient;
  final String adresse;
  final String creneau;
  final int nbColis;
  final double poids;
  final StatutLivraison statut;
  final String? notes;
  final DateTime dateCreation;
  final String? vehiculeId;

  const Livraison({
    required this.id,
    required this.nomClient,
    required this.adresse,
    required this.creneau,
    required this.nbColis,
    required this.poids,
    required this.statut,
    this.notes,
    required this.dateCreation,
    this.vehiculeId,
  });

  Livraison copyWith({
    String? id,
    String? nomClient,
    String? adresse,
    String? creneau,
    int? nbColis,
    double? poids,
    StatutLivraison? statut,
    String? notes,
    DateTime? dateCreation,
    Object? vehiculeId = _sentinel,
  }) {
    return Livraison(
      id: id ?? this.id,
      nomClient: nomClient ?? this.nomClient,
      adresse: adresse ?? this.adresse,
      creneau: creneau ?? this.creneau,
      nbColis: nbColis ?? this.nbColis,
      poids: poids ?? this.poids,
      statut: statut ?? this.statut,
      notes: notes ?? this.notes,
      dateCreation: dateCreation ?? this.dateCreation,
      vehiculeId: vehiculeId == _sentinel ? this.vehiculeId : vehiculeId as String?,
    );
  }
}

const _sentinel = Object();