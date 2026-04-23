// lib/widgets/livraison_card.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/livraison.dart';
import '../models/preuve_livraison.dart';
import '../models/client.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../services/osrm_service.dart';
import '../services/tsptw_service.dart';
import '../providers/navigation_provider.dart';
import '../providers/carte_controller_provider.dart';
import '../views/stats_view.dart';
import 'verification_livraison_sheet.dart';

class LivraisonCard extends ConsumerStatefulWidget {
  final Livraison livraison;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final void Function(StatutLivraison) onStatutChange;
  final void Function(StatutLivraison, String note) onStatutChangeWithNote;

  const LivraisonCard({
    super.key,
    required this.livraison,
    required this.onTap,
    required this.onDelete,
    required this.onStatutChange,
    required this.onStatutChangeWithNote,
  });

  @override
  ConsumerState<LivraisonCard> createState() => _LivraisonCardState();
}

class _LivraisonCardState extends ConsumerState<LivraisonCard> {
  bool _isExpanded = false;
  LatLng? _cachedPosition;
  bool _isLoadingPosition = false;
  PreuveLivraison? _preuve;
  String? _clientPhone;

  @override
  void initState() {
    super.initState();
    _loadPreuve();
    _loadClientPhone();
  }

  Future<void> _loadPreuve() async {
    if (widget.livraison.statut == StatutLivraison.livree) {
      final preuve = await DatabaseService().getPreuveByLivraison(widget.livraison.id);
      if (mounted) {
        setState(() {
          _preuve = preuve;
        });
      }
    }
  }

  Future<void> _loadClientPhone() async {
    final db = DatabaseService();
    final clients = await db.getAllClients();

    // Chercher le client par son nom (approximation)
    for (final client in clients) {
      if (client.nomComplet.toLowerCase() == widget.livraison.nomClient.toLowerCase()) {
        if (mounted) {
          setState(() {
            _clientPhone = client.phone;
          });
        }
        break;
      }
    }
  }

  // Retourne l'icône et la couleur associées à un statut
  (IconData, Color) _getStatusIconAndColor(StatutLivraison statut) {
    switch (statut) {
      case StatutLivraison.enCours:
        return (Icons.moped, AppColors.statusCours);
      case StatutLivraison.enAttente:
        return (Icons.access_time_rounded, AppColors.statusAttente);
      case StatutLivraison.livree:
        return (Icons.check_circle_outline, AppColors.statusLivree);
      case StatutLivraison.annulee:
        return (Icons.cancel_outlined, AppColors.statusAnnulee);
      case StatutLivraison.aReporter:
        return (Icons.replay, AppColors.statusReporter);
    }
  }

  // Retourne le fond arrondi avec l'icône du statut
  Widget _buildStatusIcon(StatutLivraison statut) {
    final (iconData, iconColor) = _getStatusIconAndColor(statut);
    final isFinal = statut.isFinal;
    final opacity = isFinal ? 0.5 : 1.0;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(
        iconData,
        color: iconColor.withOpacity(opacity),
        size: 26,
      ),
    );
  }

  Future<void> _localiserSurCarte() async {
    setState(() {
      _isLoadingPosition = true;
    });

    try {
      final position = await OsrmService.geocode(widget.livraison.adresse);

      if (position != null && mounted) {
        _cachedPosition = position;

        final carteController = ref.read(carteControllerProvider);
        carteController.showLocation(position.lat, position.lng, widget.livraison.adresse);

        ref.read(navigationProvider.notifier).setTab(2);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Adresse introuvable'),
            backgroundColor: AppColors.statusReporter,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de localisation: ${e.toString()}'),
            backgroundColor: AppColors.statusAnnulee,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPosition = false;
        });
      }
    }
  }

  void _callClient() {
    if (_clientPhone != null && _clientPhone!.isNotEmpty) {
      // Pour lancer un appel téléphonique
      // Uri telUri = Uri(scheme: 'tel', path: _clientPhone);
      // await launchUrl(telUri);

      // Pour l'instant, afficher une boîte de dialogue avec le numéro
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Contacter le client',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.livraison.nomClient,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                _clientPhone!,
                style: const TextStyle(color: AppColors.statusLivree, fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fermer'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                // Ici vous pouvez ajouter l'action d'appel réel
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fonction d\'appel à implémenter'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.phone, size: 16),
              label: const Text('Appeler'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusLivree,
              ),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun numéro de téléphone enregistré pour ce client'),
          backgroundColor: AppColors.statusReporter,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _getSuccessMessage(StatutLivraison status) {
    switch (status) {
      case StatutLivraison.enCours:
        return "Livraison démarrée !";
      case StatutLivraison.livree:
        return "Livraison terminée avec succès !";
      case StatutLivraison.annulee:
        return "Livraison annulée";
      case StatutLivraison.aReporter:
        return "Livraison reportée à plus tard";
      case StatutLivraison.enAttente:
        return "Livraison remise en attente";
    }
  }

  void _applyStatusChange(StatutLivraison newStatus) {
    if (newStatus == StatutLivraison.livree) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => VerificationLivraisonSheet(
          livraison: widget.livraison,
          onValidated: () {
            widget.onStatutChange(newStatus);
            _loadPreuve();
          },
        ),
      );
    } else if (newStatus == StatutLivraison.annulee ||
        newStatus == StatutLivraison.aReporter) {
      _showJustificationDialog(newStatus);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getSuccessMessage(newStatus)),
          backgroundColor: statutColor(newStatus),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.onStatutChange(newStatus);
    }
  }

  void _showJustificationDialog(StatutLivraison newStatus) {
    final controller = TextEditingController();
    final isAnnulation = newStatus == StatutLivraison.annulee;
    final color = isAnnulation ? AppColors.coral : AppColors.statusAttente;
    final icon  = isAnnulation ? Icons.cancel_outlined : Icons.schedule_outlined;
    final titre = isAnnulation ? 'Annuler la livraison' : 'Reporter la livraison';
    final hint  = isAnnulation
        ? 'Ex: Client absent, adresse incorrecte, colis endommagé...'
        : 'Ex: Problème véhicule, route bloquée, délai fournisseur...';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool hasError = false;
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.surface2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      titre,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(text: 'Une justification est '),
                        TextSpan(
                          text: 'obligatoire',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(text: ' pour cette action.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    autofocus: true,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: hasError ? AppColors.coral : AppColors.border,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: hasError ? AppColors.coral : AppColors.border,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: color, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    onChanged: (_) {
                      if (hasError) setStateDialog(() => hasError = false);
                    },
                  ),
                  if (hasError) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 14, color: AppColors.coral),
                        const SizedBox(width: 4),
                        const Text(
                          'Veuillez saisir une justification',
                          style: TextStyle(
                            color: AppColors.coral,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                  ),
                  child: const Text('Annuler'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final justification = controller.text.trim();
                    if (justification.isEmpty) {
                      setStateDialog(() => hasError = true);
                      return;
                    }
                    Navigator.pop(ctx);
                    // Save justification in livraison notes then change status
                    final notesAvecJustif = '[${isAnnulation ? "Annulation" : "Report"}] $justification';
                    widget.onStatutChangeWithNote(newStatus, notesAvecJustif);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_getSuccessMessage(newStatus)),
                        backgroundColor: color,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: Icon(icon, size: 16),
                  label: Text(isAnnulation ? 'Confirmer l\'annulation' : 'Confirmer le report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = statutColor(widget.livraison.statut);
    final isFinal = widget.livraison.statut.isFinal;

    return Dismissible(
      key: Key(widget.livraison.id),
      direction: isFinal ? DismissDirection.none : DismissDirection.endToStart,
      background: _deleteBackground(),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => widget.onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: isFinal ? AppColors.surface2.withOpacity(0.5) : AppColors.surface2,
          borderRadius: BorderRadius.circular(14),
          border: isFinal ? Border.all(color: color.withOpacity(0.3), width: 1) : null,
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                if (!isFinal) {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    _buildStatusIcon(widget.livraison.statut),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.livraison.nomClient,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isFinal ? AppColors.textMuted : AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Nunito',
                              decoration: widget.livraison.statut == StatutLivraison.annulee
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.livraison.adresse,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isFinal ? AppColors.textMuted.withOpacity(0.7) : AppColors.coral,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (!isFinal)
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 200),
                        turns: _isExpanded ? 0.5 : 0.0,
                        child: Icon(Icons.keyboard_arrow_down, color: color, size: 24),
                      ),
                    _StatutBadge(
                      statut: widget.livraison.statut,
                      color: color,
                      onChanged: _applyStatusChange,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _isExpanded && !isFinal ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              firstChild: _ExpandedContent(
                livraison: widget.livraison,
                preuve: _preuve,
                clientPhone: _clientPhone,
                onLocaliser: _localiserSurCarte,
                onCallClient: _callClient,
                isLoadingPosition: _isLoadingPosition,
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _deleteBackground() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.statusAnnulee.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.statusAnnulee.withOpacity(0.3), width: 0.5),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete_outline, color: AppColors.statusAnnulee, size: 24),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ?',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
        content: Text('Supprimer la livraison de ${widget.livraison.nomClient} ?',
            style: const TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusAnnulee),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _ExpandedContent extends StatelessWidget {
  final Livraison livraison;
  final PreuveLivraison? preuve;
  final String? clientPhone;
  final VoidCallback onLocaliser;
  final VoidCallback onCallClient;
  final bool isLoadingPosition;

  const _ExpandedContent({
    required this.livraison,
    this.preuve,
    this.clientPhone,
    required this.onLocaliser,
    required this.onCallClient,
    required this.isLoadingPosition,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      decoration: BoxDecoration(
        color: AppColors.bgPrincipal.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Lieu de livraison',
            value: livraison.adresse,
            action: _LocaliserButton(
              onPressed: onLocaliser,
              isLoading: isLoadingPosition,
            ),
          ),
          const SizedBox(height: 10),
          // NOUVEAU: Ligne de contact téléphone
          if (clientPhone != null && clientPhone!.isNotEmpty)
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Contact client',
              value: clientPhone!,
              action: _CallButton(
                onPressed: onCallClient,
              ),
            ),
          if (clientPhone != null && clientPhone!.isNotEmpty)
            const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.schedule_outlined,
            label: 'Créneau horaire',
            value: livraison.creneau,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.inventory_2_outlined,
            label: 'Nombre de colis',
            value: '${livraison.nbColis} colis',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.scale_outlined,
            label: 'Poids total',
            value: '${livraison.poids.toStringAsFixed(1)} kg',
          ),
          if (livraison.notes != null && livraison.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes_outlined, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      livraison.notes!,
                      style: const TextStyle(
                        color: AppColors.textSub,
                        fontSize: 13,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (preuve != null && livraison.statut == StatutLivraison.livree) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.statusLivree.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.statusLivree.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: AppColors.statusLivree, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Validé le ${_formatDate(preuve!.timestamp)}',
                          style: const TextStyle(
                            color: AppColors.statusLivree,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${preuve!.nbColisVerifies}/${livraison.nbColis} colis vérifiés',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (preuve!.aPhoto || preuve!.aSignature)
                    Row(
                      children: [
                        if (preuve!.aPhoto)
                          const Icon(Icons.camera_alt, size: 14, color: AppColors.textMuted),
                        if (preuve!.aPhoto && preuve!.aSignature)
                          const SizedBox(width: 4),
                        if (preuve!.aSignature)
                          const Icon(Icons.edit, size: 14, color: AppColors.textMuted),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? action;
  final bool isPlaceholder;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.action,
    this.isPlaceholder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isPlaceholder ? AppColors.textMuted.withOpacity(0.1) : AppColors.coral.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: isPlaceholder ? AppColors.textMuted : AppColors.coral),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isPlaceholder ? AppColors.textMuted : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Nunito',
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: isPlaceholder ? AppColors.textMuted : AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: isPlaceholder ? FontWeight.w400 : FontWeight.w600,
                  fontFamily: 'Nunito',
                  fontStyle: isPlaceholder ? FontStyle.italic : null,
                ),
              ),
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class _LocaliserButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const _LocaliserButton({
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.statusLivree.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.statusLivree.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.statusLivree),
              )
            else
              Icon(Icons.location_on_sharp, size: 14, color: AppColors.statusLivree),
            const SizedBox(width: 6),
            Text(
              isLoading ? 'Localisation...' : 'Localiser',
              style: TextStyle(
                color: AppColors.statusLivree,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// NOUVEAU: Bouton d'appel
class _CallButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CallButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.statusLivree.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.statusLivree.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone_rounded, size: 14, color: AppColors.statusLivree),
            const SizedBox(width: 6),
            Text(
              'Appeler',
              style: TextStyle(
                color: AppColors.statusLivree,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatutBadge extends StatelessWidget {
  final StatutLivraison statut;
  final Color color;
  final void Function(StatutLivraison) onChanged;

  const _StatutBadge({
    required this.statut,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (statut.isFinal) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          statut.label,
          style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Nunito'),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              statut.label,
              style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Nunito'),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 18, color: color),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    final actions = statut.availableActions;
    if (actions.isEmpty) {
      _showReadOnlyMessage(context);
      return;
    }
    _showActionMenu(context, actions);
  }

  void _showActionMenu(BuildContext context, List<StatutLivraison> actions) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + button.size.height,
        offset.dx + button.size.width,
        offset.dy + button.size.height,
      ),
      items: actions.map((status) {
        final statusColor = statutColor(status);
        return PopupMenuItem(
          value: status,
          child: Row(
            children: [
              Icon(status.actionIcon, size: 20, color: statusColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      status.actionLabel,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: statusColor),
                    ),
                    Text(
                      _getActionSubtitle(status),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ).then((newStatus) {
      if (newStatus != null && newStatus != statut) {
        onChanged(newStatus);
      }
    });
  }

  String _getActionSubtitle(StatutLivraison status) {
    switch (status) {
      case StatutLivraison.enCours:
        return "Passer le statut à 'En cours'";
      case StatutLivraison.livree:
        return "La livraison sera marquée comme terminée";
      case StatutLivraison.annulee:
        return "La livraison sera annulée";
      case StatutLivraison.aReporter:
        return "Remettre en attente pour plus tard";
      case StatutLivraison.enAttente:
        return "La livraison pourra être reprise plus tard";
    }
  }

  void _showReadOnlyMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          statut == StatutLivraison.livree
              ? "✓ Livraison terminée - Aucune action possible"
              : "✗ Livraison annulée - Aucune action possible",
        ),
        backgroundColor: statut == StatutLivraison.livree ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}