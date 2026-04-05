import 'package:flutter/material.dart';
import '../models/client.dart';
import '../theme/app_theme.dart';

//Ligne client dans la liste, avec avatar + ring de rang + compteur livraisons.
class ClientRow extends StatelessWidget {
  final Client client;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ClientRow({
    super.key,
    required this.client,
    required this.onTap,
    this.onDelete,
  });

  Color get _avatarColor {
    switch (client.rang) {
      case RangClient.gold:     return AppColors.coral;
      case RangClient.silver:   return AppColors.statusLivree;
      case RangClient.bronze:   return AppColors.statusCours;
      case RangClient.standard: return AppColors.statusAttente;
    }
  }

  Color get _ringColor {
    switch (client.rang) {
      case RangClient.gold:     return AppColors.statusCours;   // amber
      case RangClient.silver:   return AppColors.textMuted;
      case RangClient.bronze:   return const Color(0xFFCD7F32);
      case RangClient.standard: return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
        ),
        child: Row(
          children: [
            // Avatar + ring
            _AvatarWithRing(
              initiales: client.initiales,
              avatarColor: _avatarColor,
              ringColor: _ringColor,
            ),
            const SizedBox(width: 12),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        client.nomComplet,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Nunito',
                        ),
                      ),
                      if (client.rang != RangClient.standard) ...[
                        const SizedBox(width: 6),
                        _RangBadge(rang: client.rang),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    client.adresse,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontFamily: 'Nunito',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Compteur livraisons
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${client.livraisonsTotal}',
                  style: const TextStyle(
                    color: AppColors.statusLivree,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Nunito',
                  ),
                ),
                const Text(
                  'livraisons',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

//Avatar

class _AvatarWithRing extends StatelessWidget {
  final String initiales;
  final Color avatarColor;
  final Color ringColor;

  const _AvatarWithRing({
    required this.initiales,
    required this.avatarColor,
    required this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: avatarColor,
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Text(
                initiales,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
          ),
          if (ringColor != Colors.transparent)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: ringColor, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

//Badge rang

class _RangBadge extends StatelessWidget {
  final RangClient rang;
  const _RangBadge({required this.rang});

  Color get _color {
    switch (rang) {
      case RangClient.gold:     return AppColors.statusCours;
      case RangClient.silver:   return AppColors.textMuted;
      case RangClient.bronze:   return const Color(0xFFCD7F32);
      case RangClient.standard: return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        rang.label,
        style: TextStyle(
          color: _color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          fontFamily: 'Nunito',
        ),
      ),
    );
  }
}
