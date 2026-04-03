import 'package:flutter/material.dart';
import '../models/livraison.dart';
import '../theme/app_theme.dart';
import '../widgets/livraison_form_sheet.dart' hide statutColor;

//Tuile de livraison affichée dans l'aperçu du tableau de bord.
class DashboardDeliveryTile extends StatelessWidget {
  final Livraison livraison;

  const DashboardDeliveryTile({super.key, required this.livraison});

  @override
  Widget build(BuildContext context) {
    final color = statutColor(livraison.statut);
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.bgPrincipal,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showEditSheet(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        livraison.nomClient,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        livraison.adresse,
                        style: tt.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Indicateur coloré du statut
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LivraisonFormSheet(livraison: livraison),
    );
  }
}
