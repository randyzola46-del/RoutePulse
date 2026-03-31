import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/livraison.dart';
import '../../viewmodels/livraisons_viewmodel.dart';
import '../../widgets/livraison_card.dart';
import '../../widgets/livraison_form_sheet.dart' hide statutColor;
import '../../theme/app_theme.dart';

class LivraisonsListView extends ConsumerWidget {
  const LivraisonsListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(livraisonsViewModelProvider);
    final vm    = ref.read(livraisonsViewModelProvider.notifier);

    return Scaffold(
      appBar: _buildAppBar(context, state, vm),
      body: Column(
        children: [
          _KpiRow(state: state),
          _FiltreChips(state: state, vm: vm),
          const SizedBox(height: 4),
          Expanded(child: _buildListeOuVide(context, ref, state, vm)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _ouvrirFormulaire(context),
        backgroundColor: AppColors.coral,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Nouvelle',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  //AppBar

  AppBar _buildAppBar(
      BuildContext context,
      LivraisonsState state,
      LivraisonsViewModel vm,
      ) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Livraisons'),
          Text(
            '${state.livraisonsFiltrees.length} / ${state.totalLivraisons} affichées',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: TextField(
            onChanged: vm.setRecherche,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              hintText: 'Rechercher un client, une adresse...',
              prefixIcon: Icon(Icons.search, color: AppColors.textMuted, size: 20),
              isDense: true,
            ),
          ),
        ),
      ),
    );
  }

  //Liste

  Widget _buildListeOuVide(
      BuildContext context,
      WidgetRef ref,
      LivraisonsState state,
      LivraisonsViewModel vm,
      ) {
    final liste = state.livraisonsFiltrees;

    if (liste.isEmpty) {
      return _EtatVide(
        onAjouter: () => _ouvrirFormulaire(context),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: liste.length,
      itemBuilder: (context, index) {
        final livraison = liste[index];
        return LivraisonCard(
          livraison: livraison,
          onTap: () => _ouvrirFormulaire(context, livraison: livraison),
          onDelete: () {
            vm.supprimerLivraison(livraison.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${livraison.nomClient} supprimé'),
                action: SnackBarAction(
                  label: 'Annuler',
                  textColor: AppColors.coral,
                  onPressed: () => vm.ajouterLivraison(
                    nomClient: livraison.nomClient,
                    adresse: livraison.adresse,
                    creneau: livraison.creneau,
                    nbColis: livraison.nbColis,
                    poids: livraison.poids,
                    notes: livraison.notes,
                  ),
                ),
              ),
            );
          },
          onStatutChange: (s) => vm.changerStatut(livraison.id, s),
        );
      },
    );
  }

  void _ouvrirFormulaire(BuildContext context, {Livraison? livraison}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LivraisonFormSheet(livraison: livraison),
    );
  }
}

//KPI Row

class _KpiRow extends StatelessWidget {
  final LivraisonsState state;
  const _KpiRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _KpiCard(
            label: 'Total',
            value: '${state.totalLivraisons}',
            color: AppColors.coralLight,
          ),
          _KpiCard(
            label: 'En cours',
            value: '${state.countParStatut(StatutLivraison.enCours)}',
            color: AppColors.statusCours,
          ),
          _KpiCard(
            label: 'Livrées',
            value: '${state.countParStatut(StatutLivraison.livree)}',
            color: AppColors.statusLivree,
          ),
          _KpiCard(
            label: 'Retard',
            value: '${state.countParStatut(StatutLivraison.aReporter)}',
            color: AppColors.statusReporter,
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _KpiCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withOpacity(0.15), width: 0.5),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

//Filtre Chips

class _FiltreChips extends StatelessWidget {
  final LivraisonsState state;
  final LivraisonsViewModel vm;
  const _FiltreChips({required this.state, required this.vm});

  @override
  Widget build(BuildContext context) {
    final filtres = <StatutLivraison?>[
      null, // Tous
      StatutLivraison.enAttente,
      StatutLivraison.enCours,
      StatutLivraison.livree,
      StatutLivraison.annulee,
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: filtres.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = filtres[i];
          final selected = state.filtreStatut == f;
          final color = f == null ? AppColors.coral : statutColor(f);
          final label = f == null ? 'Tous' : f.label;

          return GestureDetector(
            onTap: () => vm.setFiltreStatut(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? color : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? color : color.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

//État vide

class _EtatVide extends StatelessWidget {
  final VoidCallback onAjouter;
  const _EtatVide({required this.onAjouter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.coral.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.local_shipping_outlined,
                color: AppColors.coral, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune livraison',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Commencez par créer une livraison',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: onAjouter,
            icon: const Icon(Icons.add, color: AppColors.coral),
            label: const Text('Créer une livraison',
                style: TextStyle(
                    color: AppColors.coral, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
