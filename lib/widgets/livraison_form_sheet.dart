import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/livraison.dart';
import '../viewmodels/livraisons_viewmodel.dart';
import '../theme/app_theme.dart';

class LivraisonFormSheet extends ConsumerStatefulWidget {
  final Livraison? livraison; // null = création, non-null = édition

  const LivraisonFormSheet({super.key, this.livraison});

  @override
  ConsumerState<LivraisonFormSheet> createState() => _LivraisonFormSheetState();
}

class _LivraisonFormSheetState extends ConsumerState<LivraisonFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomCtrl;
  late final TextEditingController _adresseCtrl;
  late final TextEditingController _creneauCtrl;
  late final TextEditingController _colisCtrl;
  late final TextEditingController _poidsCtrl;
  late final TextEditingController _notesCtrl;
  late StatutLivraison _statut;

  bool get _isEdit => widget.livraison != null;

  @override
  void initState() {
    super.initState();
    final l = widget.livraison;
    _nomCtrl     = TextEditingController(text: l?.nomClient ?? '');
    _adresseCtrl = TextEditingController(text: l?.adresse ?? '');
    _creneauCtrl = TextEditingController(text: l?.creneau ?? '');
    _colisCtrl   = TextEditingController(text: l?.nbColis.toString() ?? '1');
    _poidsCtrl   = TextEditingController(text: l?.poids.toString() ?? '');
    _notesCtrl   = TextEditingController(text: l?.notes ?? '');
    _statut      = l?.statut ?? StatutLivraison.enAttente;
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _adresseCtrl.dispose();
    _creneauCtrl.dispose();
    _colisCtrl.dispose();
    _poidsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final vm = ref.read(livraisonsViewModelProvider.notifier);

    if (_isEdit) {
      vm.modifierLivraison(
        widget.livraison!.copyWith(
          nomClient: _nomCtrl.text.trim(),
          adresse:   _adresseCtrl.text.trim(),
          creneau:   _creneauCtrl.text.trim(),
          nbColis:   int.tryParse(_colisCtrl.text) ?? 1,
          poids:     double.tryParse(_poidsCtrl.text) ?? 0,
          statut:    _statut,
          notes:     _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
        ),
      );
    } else {
      vm.ajouterLivraison(
        nomClient: _nomCtrl.text.trim(),
        adresse:   _adresseCtrl.text.trim(),
        creneau:   _creneauCtrl.text.trim(),
        nbColis:   int.tryParse(_colisCtrl.text) ?? 1,
        poids:     double.tryParse(_poidsCtrl.text) ?? 0,
        notes:     _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Titre
              Text(
                _isEdit ? 'Modifier la livraison' : 'Nouvelle livraison',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 20),

              _buildField(
                controller: _nomCtrl,
                label: 'Nom du client',
                icon: Icons.person_outline,
                validator: (v) =>
                    v!.trim().isEmpty ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _adresseCtrl,
                label: 'Adresse de livraison',
                icon: Icons.location_on_outlined,
                validator: (v) =>
                    v!.trim().isEmpty ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _creneauCtrl,
                label: 'Créneau horaire (ex: 14h – 16h)',
                icon: Icons.schedule_outlined,
                validator: (v) =>
                    v!.trim().isEmpty ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _colisCtrl,
                      label: 'Nb colis',
                      icon: Icons.inventory_2_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          int.tryParse(v ?? '') == null ? 'Invalide' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      controller: _poidsCtrl,
                      label: 'Poids (kg)',
                      icon: Icons.scale_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          double.tryParse(v ?? '') == null ? 'Invalide' : null,
                    ),
                  ),
                ],
              ),

              // Statut (seulement en édition)
              if (_isEdit) ...[
                const SizedBox(height: 12),
                const Text(
                  'STATUT',
                  style: TextStyle(
                    color: AppColors.coral,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: StatutLivraison.values.map((s) {
                    final selected = _statut == s;
                    final color = statutColor(s);
                    return ChoiceChip(
                      label: Text(s.label),
                      selected: selected,
                      onSelected: (_) => setState(() => _statut = s),
                      selectedColor: color.withOpacity(0.2),
                      backgroundColor: AppColors.surface2,
                      labelStyle: TextStyle(
                        color: selected ? color : AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                      side: BorderSide(
                        color: selected
                            ? color.withOpacity(0.5)
                            : Colors.transparent,
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 12),
              _buildField(
                controller: _notesCtrl,
                label: 'Notes (optionnel)',
                icon: Icons.notes_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: Text(_isEdit ? 'Enregistrer' : 'Créer la livraison'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 18),
      ),
    );
  }
}

Color statutColor(StatutLivraison s) {
  switch (s) {
    case StatutLivraison.enAttente:
      return AppColors.statusAttente;
    case StatutLivraison.enCours:
      return AppColors.statusCours;
    case StatutLivraison.livree:
      return AppColors.statusLivree;
    case StatutLivraison.aReporter:
      return AppColors.statusReporter;
    case StatutLivraison.annulee:
      return AppColors.statusAnnulee;
  }
}
