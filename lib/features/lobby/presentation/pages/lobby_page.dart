import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glowing_button.dart';
import '../../../../core/widgets/player_tile.dart';
import '../../../game/domain/models/game_state.dart';
import '../../../game/domain/providers/game_provider.dart';
import '../../../game/domain/providers/role_config_provider.dart';
import 'role_settings_page.dart';

class LobbyPage extends ConsumerWidget {
  const LobbyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state  = ref.watch(gameStateProvider);
    final isHost = ref.watch(isHostProvider);

    ref.listen<GameState>(gameStateProvider, (_, next) {
      if (next.phase == GamePhase.roleReveal || next.phase == GamePhase.night ||
          next.phase == GamePhase.day || next.phase == GamePhase.voting) {
        context.go('/game');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(state.roomName.isEmpty ? 'waiting_players'.tr() : state.roomName),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              label: Text('${state.players.length} لاعبين',
                  style: const TextStyle(fontSize: 12)),
              backgroundColor: AppColors.primary.withOpacity(0.2),
              side: BorderSide.none,
            ),
          ),
        ],
      ),
      body: Column(children: [

        // ── بطاقة IP للمدير ──────────────────────────────────────────────────
        if (isHost && state.hostIp != null && state.hostIp!.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gold.withOpacity(0.6), width: 1.5),
              boxShadow: [
                BoxShadow(color: AppColors.gold.withOpacity(0.15),
                    blurRadius: 20, spreadRadius: 2),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.wifi, color: AppColors.gold, size: 18),
                  SizedBox(width: 8),
                  Text('📡 عنوان المدير — شاركه مع اللاعبين',
                      style: TextStyle(color: AppColors.gold,
                          fontSize: 13, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                    ),
                    child: Text(
                      state.hostIp!,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    tooltip: 'نسخ',
                    icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: state.hostIp!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ تم نسخ عنوان IP!'),
                          duration: Duration(seconds: 2),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                  ),
                ]),
                const SizedBox(height: 8),
                const Text(
                  'اللاعبون: اختاروا "انضمام للغرفة" ← أدخلوا هذا الرقم',
                  style: TextStyle(color: AppColors.textSecond, fontSize: 11),
                ),
              ],
            ),
          ),

        // ── إرشاد للاعب ──────────────────────────────────────────────────────
        if (!isHost)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withOpacity(0.4)),
            ),
            child: const Row(children: [
              Icon(Icons.hourglass_top, color: AppColors.accent, size: 16),
              SizedBox(width: 8),
              Text('انتظر قيام المدير ببدء اللعبة...',
                  style: TextStyle(color: AppColors.accent, fontSize: 13)),
            ]),
          ),

        Expanded(
          child: state.players.isEmpty
            ? Center(child: Text('waiting_players'.tr(),
                style: const TextStyle(color: AppColors.textSecond)))
            : ListView.builder(
                itemCount: state.players.length,
                itemBuilder: (_, i) {
                  final p = state.players[i];
                  return PlayerTile(
                    player: p,
                    isHost: isHost,
                    onKick: isHost && !p.isHost
                      ? () => ref.read(gameStateProvider.notifier).kickPlayer(p.id)
                      : null,
                  );
                }),
        ),

        // Start Game button (Host only)
        if (isHost)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              if (state.players.length < AppConstants.minPlayers)
                Text(
                  'min_players'.tr(namedArgs: {'count': AppConstants.minPlayers.toString()}),
                  style: const TextStyle(color: AppColors.textSecond, fontSize: 13),
                ),
              const SizedBox(height: 8),
              GlowingButton(
                label: 'start_game'.tr(),
                icon: Icons.play_arrow_rounded,
                color: state.players.length >= AppConstants.minPlayers
                    ? AppColors.success : AppColors.textSecond,
                onTap: state.players.length >= AppConstants.minPlayers
                    ? () => ref.read(gameStateProvider.notifier).startGame()
                    : null,
              ),
            ]),
          ),

        if (!isHost)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2,
                    color: AppColors.primary)),
              const SizedBox(width: 12),
              Text('waiting_players'.tr(),
                style: const TextStyle(color: AppColors.textSecond)),
            ]),
          ),
      ]),
    );
  }
}
