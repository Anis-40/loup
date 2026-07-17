import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../features/game/domain/models/player.dart';
import '../theme/app_theme.dart';

class PlayerTile extends StatelessWidget {
  final Player player;
  final bool isHost;
  final VoidCallback? onKick;
  final bool showRole;

  const PlayerTile({
    super.key,
    required this.player,
    this.isHost = false,
    this.onKick,
    this.showRole = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
      decoration: BoxDecoration(
        color: player.isAlive ? AppColors.card : AppColors.blood.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: player.isHost ? AppColors.gold.withOpacity(0.6) : AppColors.primary.withOpacity(0.2),
          width: player.isHost ? 1.5 : 0.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: player.isAlive ? AppColors.primary : AppColors.blood,
          child: Text(
            player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          player.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: player.isAlive ? AppColors.text : AppColors.textSecond,
            decoration: player.isAlive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: showRole && player.role != null
            ? Text(player.role!.nameKey().tr(), style: const TextStyle(color: AppColors.accent))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (player.isHost)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.gold.withOpacity(0.5)),
                ),
                child: Text('host_badge'.tr(), style: const TextStyle(color: AppColors.gold, fontSize: 11)),
              ),
            if (player.isMayor)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.6)),
                ),
                child: Text('🎖️ ${'mayor_badge'.tr()}', style: const TextStyle(color: AppColors.primary, fontSize: 11)),
              ),
            if (!player.isAlive)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.blood.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('dead_badge'.tr(), style: const TextStyle(color: AppColors.danger, fontSize: 11)),
              ),
            if (isHost && onKick != null && !player.isHost)
              IconButton(
                icon: const Icon(Icons.cancel_rounded, color: AppColors.danger, size: 20),
                onPressed: onKick,
                tooltip: 'kick_player'.tr(),
              ),
          ],
        ),
      ),
    );
  }
}
