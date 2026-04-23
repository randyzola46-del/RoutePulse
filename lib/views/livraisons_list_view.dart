import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/livraison.dart';
import '../models/vehicule.dart';
import '../viewmodels/livraisons_viewmodel.dart';
import '../viewmodels/vehicules_viewmodel.dart';
import '../widgets/livraison_card.dart';
import '../widgets/livraison_form_sheet.dart';
import '../theme/app_theme.dart';
import '../widgets/snackbar_utils.dart';

class LivraisonsListView extends ConsumerStatefulWidget {
  const LivraisonsListView({super.key});

  @override
  ConsumerState<LivraisonsListView> createState() => _LivraisonsListViewState();
}

class _LivraisonsListViewState extends ConsumerState<LivraisonsListView> {
  double _poidsActuelVehicule = 0.0;
  String? _lastDeletedId;
  bool _isUpdatingPoids = false;

  Vehicule? _vehiculeActif(VehiculesState state) {
    try {
      return state.vehicules.firstWhere(
            (v) => v.disponibilite == DisponibiliteVehicule.disponible,
      );
    } catch (_) {
      return null;
    }
  }

  void _mettreAJourPoidsVehicule(List<Livraison> livraisons) {
    if (_isUpdatingPoids) return;
    _isUpdatingPoids = true;

    setState(() {
      _poidsActuelVehicule = livraisons
          .where((l) => l.statut == StatutLivraison.enCours)
          .fold(0.0, (sum, l) => sum + l.poids);
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _isUpdatingPoids = false;
    });
  }

  void _handleStatutChange(Livraison livraison, StatutLivraison nouveauStatut, LivraisonsViewModel vm) {
    vm.changerStatut(livraison.id, nouveauStatut);
    String message = _getStatutChangeMessage(livraison.nomClient, nouveauStatut);
    SnackBarUtils.showStatutChange(context, nouveauStatut, message);

    Future.microtask(() {
      final etatActuel = ref.read(livraisonsViewModelProvider);
      _mettreAJourPoidsVehicule(etatActuel.livraisons);
    });
  }

  void _handleStatutChangeWithNote(Livraison livraison, StatutLivraison nouveauStatut, String note, LivraisonsViewModel vm) {
    vm.changerStatutAvecNote(livraison.id, nouveauStatut, note);
    String message = _getStatutChangeMessage(livraison.nomClient, nouveauStatut);
    SnackBarUtils.showStatutChange(context, nouveauStatut, message);

    Future.microtask(() {
      final etatActuel = ref.read(livraisonsViewModelProvider);
      _mettreAJourPoidsVehicule(etatActuel.livraisons);
    });
  }

  String _getStatutChangeMessage(String nomClient, StatutLivraison nouveauStatut) {
    switch (nouveauStatut) {
      case StatutLivraison.enCours:
        return "$nomClient - Livraison démarrée";
      case StatutLivraison.livree:
        return "$nomClient - Livraison terminée avec succès";
      case StatutLivraison.annulee:
        return "$nomClient - Livraison annulée";
      case StatutLivraison.aReporter:
        return "$nomClient - Livraison reportée à plus tard";
      case StatutLivraison.enAttente:
        return "$nomClient - Remise en attente";
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(livraisonsViewModelProvider);  // ← watch important!
    final vm = ref.read(livraisonsViewModelProvider.notifier);
    final vehiculesState = ref.watch(vehiculesViewModelProvider);
    final vehiculeActif = _vehiculeActif(vehiculesState);

    // Forcer le rafraîchissement au montage si nécessaire
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.livraisons.isEmpty && !state.isLoading) {
        vm.chargerLivraisons();
      }
      _mettreAJourPoidsVehicule(state.livraisons);
    });

    return Scaffold(
      backgroundColor: AppColors.bgPrincipal,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(state),
            _buildSearchBar(vm),
            _buildFiltreChips(state, vm),
            const SizedBox(height: 4),
            Expanded(child: _buildListeOuVide(context, ref, state, vm, vehiculeActif)),
            if (vehiculeActif != null)
              _BarreChargeVehicule(
                vehicule: vehiculeActif,
                poidsActuel: _poidsActuelVehicule,
              ),
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(LivraisonsState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Livraisons',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              fontFamily: 'Nunito',
            ),
          ),
          Text(
            '${state.totalLivraisons} livraisons',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(LivraisonsViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: TextField(
        onChanged: vm.setRecherche,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'Nunito',
        ),
        decoration: InputDecoration(
          hintText: 'Rechercher',
          hintStyle: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
            fontFamily: 'Nunito',
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildFiltreChips(LivraisonsState state, LivraisonsViewModel vm) {
    final filtres = <_FiltreItem>[
      const _FiltreItem(statut: null, label: 'Tous'),
      const _FiltreItem(statut: StatutLivraison.enCours, label: 'En cours'),
      const _FiltreItem(statut: StatutLivraison.enAttente, label: 'Attente'),
      const _FiltreItem(statut: StatutLivraison.livree, label: 'Livrées'),
      const _FiltreItem(statut: StatutLivraison.aReporter, label: 'Reportés'),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filtres.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final f = filtres[i];
            final selected = state.filtreStatut == f.statut;

            return GestureDetector(
              onTap: () => vm.setFiltreStatut(f.statut),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.coral : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.coral,
                    width: 1.2,
                  ),
                ),
                child: Text(
                  f.label,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.coral,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildListeOuVide(
      BuildContext context,
      WidgetRef ref,
      LivraisonsState state,
      LivraisonsViewModel vm,
      Vehicule? vehiculeActif,
      ) {
    final liste = state.livraisonsFiltrees;

    if (liste.isEmpty) {
      return _EtatVide(onAjouter: () => _ouvrirFormulaire(context));
    }

    final groupes = <String, List<Livraison>>{};
    for (final l in liste) {
      final mois = _formatMois(l.dateCreation);
      groupes.putIfAbsent(mois, () => []).add(l);
    }
    final moisKeys = groupes.keys.toList();

    final items = <_ListItem>[];
    for (final mois in moisKeys) {
      items.add(_ListItem.header(mois));
      for (final l in groupes[mois]!) {
        items.add(_ListItem.livraison(l));
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20, top: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        if (item.isHeader) {
          return _MonthSeparator(label: item.header!);
        }

        final livraison = item.livraison!;
        return LivraisonCard(
          livraison: livraison,
          onTap: () => _ouvrirFormulaire(context, livraison: livraison),
          onDelete: () {
            final livraisonId = livraison.id;
            final livraisonNom = livraison.nomClient;

            if (_lastDeletedId == livraisonId) return;
            _lastDeletedId = livraisonId;

            vm.supprimerLivraison(livraisonId);

            final currentLivraisons = ref.read(livraisonsViewModelProvider).livraisons;
            _poidsActuelVehicule = currentLivraisons
                .where((l) => l.statut == StatutLivraison.enCours)
                .fold(0.0, (sum, l) => sum + l.poids);

            SnackBarUtils.showError(context, '$livraisonNom supprimé');

            Future.delayed(const Duration(milliseconds: 500), () {
              if (_lastDeletedId == livraisonId) {
                _lastDeletedId = null;
              }
            });
          },
          onStatutChange: (nouveauStatut) => _handleStatutChange(livraison, nouveauStatut, vm),
          onStatutChangeWithNote: (nouveauStatut, note) => _handleStatutChangeWithNote(livraison, nouveauStatut, note, vm),
        );
      },
    );
  }

  // NOUVEAU : Widget pour la barre d'action en bas
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton.icon(
          onPressed: () => _ouvrirFormulaire(context),
          icon: const Icon(Icons.add, size: 24),
          label: const Text(
            'Nouvelle livraison',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.coral,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
          ),
        ),
      ),
    );
  }

  String _formatMois(DateTime date) {
    const moisNoms = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${moisNoms[date.month - 1]} ${date.year}';
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

// Barre de charge véhicule
class _BarreChargeVehicule extends StatelessWidget {
  final Vehicule vehicule;
  final double poidsActuel;

  const _BarreChargeVehicule({
    required this.vehicule,
    required this.poidsActuel,
  });

  double get _ratio => (poidsActuel / vehicule.chargeMaxKg).clamp(0.0, 1.0);

  Color get _couleurBarre {
    if (_ratio >= 0.9) return AppColors.statusAnnulee;
    if (_ratio >= 0.7) return AppColors.statusCours;
    return AppColors.statusLivree;
  }

  @override
  Widget build(BuildContext context) {
    final surcharge = poidsActuel > vehicule.chargeMaxKg;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: _couleurBarre.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _couleurBarre.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_shipping_rounded,
                  color: _couleurBarre,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicule.nomComplet,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    Text(
                      'Charge max : ${vehicule.chargeMaxKg} kg',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: _couleurBarre,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Nunito',
                    ),
                    child: Text('${poidsActuel.toStringAsFixed(1)} kg'),
                  ),
                  if (surcharge)
                    const Text(
                      'Surcharge !',
                      style: TextStyle(
                        color: AppColors.statusAnnulee,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Nunito',
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  width: double.infinity,
                  color: AppColors.surface2,
                ),
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  widthFactor: _ratio,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: _couleurBarre,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: _couleurBarre.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthSeparator extends StatelessWidget {
  final String label;
  const _MonthSeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 0.5,
              color: AppColors.textMuted.withOpacity(0.3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Nunito',
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 0.5,
              color: AppColors.textMuted.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}

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

class _FiltreItem {
  final StatutLivraison? statut;
  final String label;
  const _FiltreItem({required this.statut, required this.label});
}

class _ListItem {
  final String? header;
  final Livraison? livraison;

  const _ListItem._({this.header, this.livraison});

  factory _ListItem.header(String h) => _ListItem._(header: h);
  factory _ListItem.livraison(Livraison l) => _ListItem._(livraison: l);

  bool get isHeader => header != null;
}