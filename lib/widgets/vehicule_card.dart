import 'package:flutter/material.dart';
import '../models/vehicule.dart';
import '../theme/app_theme.dart';

class VehiculeCard extends StatelessWidget {
  final Vehicule vehicule;
  final VoidCallback onTap;

  const VehiculeCard({
    super.key,
    required this.vehicule,
    required this.onTap,
  });

  bool get _disponible =>
      vehicule.disponibilite == DisponibiliteVehicule.disponible;

  Color get _accentColor =>
      _disponible ? AppColors.statusAttente : AppColors.textMuted;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _disponible
                ? AppColors.statusAttente.withOpacity(0.25)
                : Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bande latérale colorée
                Container(
                  width: 4,
                  color: _accentColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 12),
                        _buildJauges(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Icône véhicule
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _accentColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _accentColor.withOpacity(0.25)),
          ),
          child: Icon(
            Icons.local_shipping_rounded,
            color: _accentColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        // Nom + immat
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vehicule.nomComplet,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Nunito',
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Text(
                  vehicule.immatriculation,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Nunito',
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Badge disponibilité
        _DisponibiliteBadge(disponible: _disponible),
      ],
    );
  }

  Widget _buildJauges() {
    return Row(
      children: [
        Expanded(
          child: _JaugeCell(
            label: 'Charge',
            valeur: '${vehicule.chargeMaxKg} Kg',
            ratio: vehicule.chargeMaxKg / 2000,
            couleur: _disponible ? AppColors.statusAttente : AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _JaugeCell(
            label: 'Volume',
            valeur: '${vehicule.volumeM3.toStringAsFixed(0)} m³',
            ratio: vehicule.volumeM3 / 16,
            couleur: _disponible ? AppColors.coral : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

//Badge Disponible / Indisponible

class _DisponibiliteBadge extends StatelessWidget {
  final bool disponible;
  const _DisponibiliteBadge({required this.disponible});

  @override
  Widget build(BuildContext context) {
    final color = disponible ? AppColors.statusLivree : AppColors.statusAnnulee;
    final label = disponible ? 'Disponible' : 'Indisponible';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          fontFamily: 'Nunito',
        ),
      ),
    );
  }
}

//Cellule jauge

class _JaugeCell extends StatelessWidget {
  final String label;
  final String valeur;
  final double ratio;
  final Color couleur;

  const _JaugeCell({
    required this.label,
    required this.valeur,
    required this.ratio,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valeur,
            style: TextStyle(
              color: couleur,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(couleur),
            ),
          ),
        ],
      ),
    );
  }
}
