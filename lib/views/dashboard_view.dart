// lib/views/dashboard_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/livraison.dart';
import '../theme/app_theme.dart';
import '../viewmodels/livraisons_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_carousel.dart';  // ✅ NOUVEAU
import '../widgets/dashboard_delivery_tile.dart';
import '../widgets/dashboard_empty_state.dart';
import '../widgets/livraison_form_sheet.dart' hide statutColor;

class DashboardView extends ConsumerWidget {
  final VoidCallback? onVoirTout;

  const DashboardView({super.key, this.onVoirTout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(livraisonsViewModelProvider);
    final authState = ref.watch(authViewModelProvider);
    final userName = authState.user?.prenom ?? 'Utilisateur';

    final total = state.totalLivraisons;
    final livrees = state.countParStatut(StatutLivraison.livree);
    final enCours = state.countParStatut(StatutLivraison.enCours);
    final retard = state.countParStatut(StatutLivraison.aReporter);
    final progress = total > 0 ? livrees / total : 0.0;
    final apercu = state.livraisons.take(5).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header (greeting + barre de progression)
        SliverToBoxAdapter(
          child: DashboardHeader(
            progress: progress,
            total: total,
            livrees: livrees,
            userName: userName,
          ),
        ),

        // ✅ NOUVEAU : Carrousel de cartes (remplace la grille KPI)
        const SliverPadding(
          padding: EdgeInsets.symmetric(vertical: 16),
          sliver: SliverToBoxAdapter(
            child: DashboardCarousel(),
          ),
        ),

        // Titre section + lien « Voir tout »
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          sliver: SliverToBoxAdapter(
            child: _SectionHeader(onVoirTout: onVoirTout),
          ),
        ),

        // Liste aperçu ou état vide
        if (apercu.isEmpty)
          SliverToBoxAdapter(
            child: DashboardEmptyState(
              onAjouter: () => _showFormSheet(context),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (_, i) => DashboardDeliveryTile(livraison: apercu[i]),
                childCount: apercu.length,
              ),
            ),
          ),

        // Bouton nouvelle livraison
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          sliver: SliverToBoxAdapter(
            child: _NewDeliveryButton(
              onPressed: () => _showFormSheet(context),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 8)),
      ],
    );
  }

  void _showFormSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LivraisonFormSheet(),
    );
  }
}

// ... (le reste du code reste inchangé)

class _SectionHeader extends StatelessWidget {
  final VoidCallback? onVoirTout;
  const _SectionHeader({this.onVoirTout});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Livraisons du jour',
          style: tt.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        GestureDetector(
          onTap: onVoirTout,
          child: Text(
            'Voir tout',
            style: tt.bodySmall?.copyWith(
              color: AppColors.textMuted,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _NewDeliveryButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _NewDeliveryButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: const Text('Nouvelle livraison'),
    );
  }
}