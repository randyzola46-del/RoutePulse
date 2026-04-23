import 'package:flutter/material.dart';
import '../models/vehicule.dart';
import '../theme/app_theme.dart';

class VehiculeCard extends StatelessWidget {
  final Vehicule vehicule;
  final VoidCallback onTap;
  final ValueChanged<bool>? onToggleActif;

  const VehiculeCard({
    super.key,
    required this.vehicule,
    required this.onTap,
    this.onToggleActif,
  });

  bool get _actif =>
      vehicule.disponibilite == DisponibiliteVehicule.disponible;

  Color get _accentColor =>
      _actif ? AppColors.statusLivree : AppColors.textMuted;

  // Icône selon le type de véhicule
  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'moto':
        return Icons.moped;
      case 'voiture':
        return Icons.directions_car_rounded;
      case 'fourgon':
        return Icons.local_shipping_rounded;
      default:
        return Icons.local_shipping_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: _actif ? AppColors.surface : AppColors.surface.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _actif
                ? AppColors.statusAttente.withOpacity(0.25)
                : Colors.white.withOpacity(0.04),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
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
                        if (_actif) ...[
                          const SizedBox(height: 12),
                          _buildJauges(),
                        ],
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
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _accentColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _accentColor.withOpacity(0.25)),
          ),
          child: Icon(
            _getIconForType(vehicule.type),
            color: _accentColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: _actif ? AppColors.textPrimary : AppColors.textMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Nunito',
                ),
                child: Text(vehicule.nomComplet),
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
        _ToggleActif(
          actif: _actif,
          onChanged: onToggleActif,
        ),
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
            couleur: AppColors.statusAttente,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _JaugeCell(
            label: 'Volume',
            valeur: '${vehicule.volumeM3.toStringAsFixed(0)} m³',
            ratio: vehicule.volumeM3 / 16,
            couleur: AppColors.coral,
          ),
        ),
      ],
    );
  }
}

class _ToggleActif extends StatelessWidget {
  final bool actif;
  final ValueChanged<bool>? onChanged;

  const _ToggleActif({required this.actif, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged?.call(!actif),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: actif ? AppColors.statusLivree : AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              fontFamily: 'Nunito',
              letterSpacing: 0.4,
            ),
            child: Text(actif ? 'ACTIF' : 'INACTIF'),
          ),
          const SizedBox(height: 5),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 44,
            height: 24,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: actif
                  ? AppColors.statusLivree.withOpacity(0.25)
                  : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: actif
                    ? AppColors.statusLivree.withOpacity(0.5)
                    : Colors.white.withOpacity(0.12),
                width: 1,
              ),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment:
              actif ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: actif ? AppColors.statusLivree : AppColors.textMuted,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: (actif ? AppColors.statusLivree : Colors.black)
                          .withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}