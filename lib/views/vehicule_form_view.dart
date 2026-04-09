import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../viewmodels/vehicules_viewmodel.dart';

//Écran d'ajout de véhicule

class VehiculeFormView extends ConsumerStatefulWidget {
  const VehiculeFormView({super.key});

  @override
  ConsumerState<VehiculeFormView> createState() => _VehiculeFormViewState();
}

class _VehiculeFormViewState extends ConsumerState<VehiculeFormView> {
  // Sélection du type
  String _typeSelectionne = 'Moto';
  final List<_TypeVehicule> _types = const [
    _TypeVehicule(label: 'Moto',    icon: Icons.moped),
    _TypeVehicule(label: 'Voiture', icon: Icons.directions_car_rounded),
    _TypeVehicule(label: 'Fourgon', icon: Icons.local_shipping_rounded),
  ];

  // Contrôleurs de champs
  final _marqueCtrl        = TextEditingController();
  final _immatrCtrl        = TextEditingController();
  final _chargeCtrl        = TextEditingController();
  final _volumeCtrl        = TextEditingController();
  final _anneeCtrl         = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _marqueCtrl.dispose();
    _immatrCtrl.dispose();
    _chargeCtrl.dispose();
    _volumeCtrl.dispose();
    _anneeCtrl.dispose();
    super.dispose();
  }

  //Validation & enregistrement
  void _enregistrer() {
    if (!_formKey.currentState!.validate()) return;

    final parts  = _marqueCtrl.text.trim().split(' ');
    final marque = parts.first;
    final modele = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    ref.read(vehiculesViewModelProvider.notifier).ajouterVehicule(
      marque:        marque,
      modele:        modele,
      immatriculation: _immatrCtrl.text.trim().toUpperCase(),
      type:          _typeSelectionne,
      chargeMaxKg:   int.tryParse(_chargeCtrl.text) ?? 0,
      volumeM3:      double.tryParse(_volumeCtrl.text.replaceAll(',', '.')) ?? 0,
      annee:         int.tryParse(_anneeCtrl.text) ?? DateTime.now().year,
    );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Véhicule ajouté !',
            style: const TextStyle(fontFamily: 'Nunito')),
        backgroundColor: AppColors.statusLivree,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  //Build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrincipal,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Type de véhicule'),
                      const SizedBox(height: 14),
                      _buildTypeSelector(),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: _marqueCtrl,
                        label: 'Marque & Modèle',
                        placeholder: 'ex: Renault Master',
                        validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _immatrCtrl,
                        label: 'Immatriculation',
                        placeholder: 'ex: AB-123-CD',
                        capitalization: TextCapitalization.characters,
                        validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _chargeCtrl,
                              label: 'Charge (kg)',
                              placeholder: 'ex: 1200',
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Requis' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _volumeCtrl,
                              label: 'Volume (m³)',
                              placeholder: 'ex: 8',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Requis' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _anneeCtrl,
                        label: 'Année (Optionnel)',
                        placeholder: 'ex: 2021',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                      ),
                      const SizedBox(height: 36),
                      _buildButtons(context),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //Widgets

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0x33FFB572),
            const Color(0x33FFB572),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bouton retour
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.chevron_left, color: AppColors.textMuted, size: 24),
                Text(
                  'Véhicules',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Nouveau véhicule',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Remplissez les informations',
            style: TextStyle(
              color: AppColors.statusCours,
              fontSize: 16,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        fontFamily: 'Nunito',
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: _types.map((t) {
        final selected = _typeSelectionne == t.label;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: t.label != _types.last.label ? 10 : 0,
            ),
            child: GestureDetector(
              onTap: () => setState(() => _typeSelectionne = t.label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.coral.withOpacity(0.18)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? AppColors.coral
                        : Colors.white.withOpacity(0.08),
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      t.icon,
                      color: selected ? AppColors.coral : AppColors.textMuted,
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.label,
                      style: TextStyle(
                        color: selected ? AppColors.coral : AppColors.textMuted,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization capitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Nunito',
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: capitalization,
          validator: validator,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontFamily: 'Nunito',
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              color: AppColors.textMuted.withOpacity(0.5),
              fontFamily: 'Nunito',
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppColors.statusAnnulee, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _enregistrer,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text(
              'Enregistrer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                fontFamily: 'Nunito',
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.coral,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.coral, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              'Annuler',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                fontFamily: 'Nunito',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

//Modèle interne
class _TypeVehicule {
  final String label;
  final IconData icon;
  const _TypeVehicule({required this.label, required this.icon});
}