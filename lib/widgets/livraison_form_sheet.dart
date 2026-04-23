// lib/widgets/livraison_form_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/livraison.dart';
import '../models/client.dart';
import '../viewmodels/livraisons_viewmodel.dart';
import '../viewmodels/clients_viewmodel.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'time_range_picker.dart';

class ClientPrefill {
  final String nom;
  final String adresse;
  final String creneauPrefere;
  final String? phone;

  const ClientPrefill({
    required this.nom,
    required this.adresse,
    required this.creneauPrefere,
    this.phone,
  });
}

class LivraisonFormSheet extends ConsumerStatefulWidget {
  final Livraison? livraison;
  final ClientPrefill? prefillClient;

  const LivraisonFormSheet({
    super.key,
    this.livraison,
    this.prefillClient,
  });

  @override
  ConsumerState<LivraisonFormSheet> createState() => _LivraisonFormSheetState();
}

class _LivraisonFormSheetState extends ConsumerState<LivraisonFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomCtrl;
  late final TextEditingController _adresseCtrl;
  late final TextEditingController _phoneCtrl;
  late String _creneauValue;
  late final TextEditingController _colisCtrl;
  late final TextEditingController _poidsCtrl;
  late final TextEditingController _notesCtrl;
  late StatutLivraison _statut;

  bool get _isEdit => widget.livraison != null;
  bool _isSubmitting = false;
  String? _originalClientId;
  String? _originalPhone;

  @override
  void initState() {
    super.initState();
    final l = widget.livraison;
    final prefill = widget.prefillClient;

    _nomCtrl = TextEditingController(text: l?.nomClient ?? prefill?.nom ?? '');
    _adresseCtrl = TextEditingController(text: l?.adresse ?? prefill?.adresse ?? '');
    _phoneCtrl = TextEditingController(text: prefill?.phone ?? '');
    _creneauValue = l?.creneau ?? prefill?.creneauPrefere ?? '09:00 - 12:00';
    _colisCtrl = TextEditingController(text: l?.nbColis.toString() ?? '1');
    _poidsCtrl = TextEditingController(text: l?.poids.toString() ?? '');
    _notesCtrl = TextEditingController(text: l?.notes ?? '');
    _statut = l?.statut ?? StatutLivraison.enAttente;

    // Si c'est une modification, récupérer le téléphone du client existant
    if (_isEdit && l != null) {
      _loadClientPhone(l.clientId);
    }
  }

  Future<void> _loadClientPhone(String clientId) async {
    final db = DatabaseService();
    final client = await db.getClient(clientId);
    if (client != null && client.phone != null && mounted) {
      setState(() {
        _originalClientId = clientId;
        _originalPhone = client.phone;
        _phoneCtrl.text = client.phone!;
      });
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _adresseCtrl.dispose();
    _phoneCtrl.dispose();
    _colisCtrl.dispose();
    _poidsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateClientWithPhone(String nomClient, String adresse, String phone) async {
    final db = DatabaseService();
    final clients = await db.getAllClients();

    Client? existingClient;
    for (final c in clients) {
      if (c.nomComplet.toLowerCase() == nomClient.toLowerCase()) {
        existingClient = c;
        break;
      }
    }

    if (existingClient != null) {
      // Mettre à jour le téléphone si nécessaire
      if (existingClient.phone != phone && phone.isNotEmpty) {
        final updatedClient = existingClient.copyWith(phone: phone);
        await db.updateClient(updatedClient);

        final clientsVM = ref.read(clientsViewModelProvider.notifier);
        await clientsVM.loadClients();
      }
    } else if (phone.isNotEmpty) {
      // Créer un nouveau client avec téléphone
      final parts = nomClient.trim().split(' ');
      String prenom = parts.first;
      String nom = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      final nouveauClient = Client(
        id: const Uuid().v4(),
        prenom: prenom,
        nom: nom,
        adresse: adresse,
        phone: phone,
        rang: RangClient.standard,
        estRecurrent: false,
        livraisonsTotal: 0,
        tauxSucces: 0.0,
        creneauPrefere: '09:00 - 12:00',
        dateCreation: DateTime.now(),
      );
      await db.insertClient(nouveauClient);

      final clientsVM = ref.read(clientsViewModelProvider.notifier);
      await clientsVM.loadClients();
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final vm = ref.read(livraisonsViewModelProvider.notifier);

    try {
      // Mettre à jour le client avec le téléphone (pour création ou modification)
      if (_phoneCtrl.text.trim().isNotEmpty) {
        await _updateClientWithPhone(
          _nomCtrl.text.trim(),
          _adresseCtrl.text.trim(),
          _phoneCtrl.text.trim(),
        );
      }

      if (_isEdit) {
        await vm.modifierLivraison(
          widget.livraison!.copyWith(
            nomClient: _nomCtrl.text.trim(),
            adresse: _adresseCtrl.text.trim(),
            creneau: _creneauValue,
            nbColis: int.tryParse(_colisCtrl.text) ?? 1,
            poids: double.tryParse(_poidsCtrl.text) ?? 0,
            statut: _statut,
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          ),
        );
      } else {
        await vm.ajouterLivraison(
          nomClient: _nomCtrl.text.trim(),
          adresse: _adresseCtrl.text.trim(),
          creneau: _creneauValue,
          nbColis: int.tryParse(_colisCtrl.text) ?? 1,
          poids: double.tryParse(_poidsCtrl.text) ?? 0,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Livraison modifiée' : 'Livraison créée'),
            backgroundColor: AppColors.statusLivree,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.statusAnnulee,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGlobalSubmitting = ref.watch(livraisonsViewModelProvider).isSubmitting;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
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
                validator: (v) => v!.trim().isEmpty ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 12),

              _buildField(
                controller: _adresseCtrl,
                label: 'Adresse de livraison',
                icon: Icons.location_on_outlined,
                validator: (v) => v!.trim().isEmpty ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 12),

              _buildField(
                controller: _phoneCtrl,
                label: 'Téléphone du client',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),

              _buildCreneauField(),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _colisCtrl,
                      label: 'Nb colis',
                      icon: Icons.inventory_2_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) => int.tryParse(v ?? '') == null
                          ? 'Nombre invalide'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      controller: _poidsCtrl,
                      label: 'Poids (kg)',
                      icon: Icons.scale_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => double.tryParse(v ?? '') == null
                          ? 'Poids invalide'
                          : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Text(
                'DÉTAILS',
                style: TextStyle(
                  color: AppColors.coral,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),

              _buildField(
                controller: _notesCtrl,
                label: 'Notes (optionnel)',
                icon: Icons.notes_outlined,
                maxLines: 2,
              ),

              if (_isEdit) ...[
                const SizedBox(height: 16),
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
                        color: selected ? color.withOpacity(0.5) : Colors.transparent,
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: (_isSubmitting || isGlobalSubmitting) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: (_isSubmitting || isGlobalSubmitting)
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Text(_isEdit ? 'Enregistrer' : 'Créer la livraison'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreneauField() {
    String startTime = '09:00';
    String endTime = '12:00';

    try {
      final parts = _creneauValue.split(' - ');
      if (parts.length == 2) {
        startTime = parts[0];
        endTime = parts[1];
      }
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.schedule_outlined, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 8),
            const Text(
              'Créneau horaire',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TimeRangePicker(
          initialStartTime: startTime,
          initialEndTime: endTime,
          onTimeRangeSelected: (timeRange) {
            setState(() {
              _creneauValue = timeRange;
            });
          },
        ),
      ],
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
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 18),
      ),
    );
  }
}