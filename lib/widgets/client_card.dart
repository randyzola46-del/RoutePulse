import 'package:flutter/material.dart';
import '../models/client.dart';
import '../theme/app_theme.dart';

class ClientCard extends StatelessWidget {
  final Client client;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onNewDelivery;

  const ClientCard({
    super.key,
    required this.client,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onNewDelivery,
  });

  Color get _rangColor {
    switch (client.rang) {
      case RangClient.gold:
        return const Color(0xFFFFB830);
      case RangClient.silver:
        return const Color(0xFFB8C0CC);
      case RangClient.bronze:
        return const Color(0xFFCD7F32);
      case RangClient.standard:
        return AppColors.statusAttente;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rangColor = _rangColor;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: rangColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        client.initiales,
                        style: TextStyle(
                          color: rangColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.nomComplet,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          client.adresse,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (client.phone != null && client.phone!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.phone, size: 12, color: AppColors.statusLivree),
                              const SizedBox(width: 4),
                              Text(
                                client.phone!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.statusLivree,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    color: AppColors.surface,
                    onSelected: (value) {
                      switch (value) {
                        case 'delivery':
                          onNewDelivery?.call();
                          break;
                        case 'edit':
                          onEdit();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (onNewDelivery != null)
                        const PopupMenuItem(
                          value: 'delivery',
                          child: Row(
                            children: [
                              Icon(Icons.local_shipping, size: 20),
                              SizedBox(width: 12),
                              Text('Nouvelle livraison'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 12),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20),
                            SizedBox(width: 12),
                            Text('Supprimer'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildBadge(client.rang.label, rangColor),
                  _buildBadge('${client.livraisonsTotal} livr.', AppColors.coral),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}