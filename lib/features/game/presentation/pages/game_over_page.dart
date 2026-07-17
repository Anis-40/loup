import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glowing_button.dart';
import '../../../../core/widgets/player_tile.dart';
import '../../domain/providers/game_provider.dart';

class GameOverPage extends ConsumerWidget {
  const GameOverPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state  = ref.watch(gameStateProvider);
    final isHost = ref.watch(isHostProvider);
    final wolvesWon = state.gameWinner == 'wolves';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: wolvesWon
              ? [const Color(0xFF2A0000), AppColors.background]
              : [const Color(0xFF002A00), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            const SizedBox(height: 30),

            // Trophy / Wolf Icon
            Icon(
              wolvesWon ? Icons.coronavirus : Icons.emoji_events,
              size: 90,
              color: wolvesWon ? AppColors.danger : AppColors.gold,
            ).animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut)
              .then()
              .shimmer(duration: 1200.ms, color: Colors.white30),

            const SizedBox(height: 20),

            Text(
              'game_over'.tr(),
              style: const TextStyle(color: AppColors.textSecond, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              wolvesWon ? 'werewolves_win'.tr() : 'villagers_win'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: wolvesWon ? AppColors.danger : AppColors.success,
                shadows: [Shadow(
                  color: (wolvesWon ? AppColors.danger : AppColors.success).withOpacity(0.5),
                  blurRadius: 25,
                )],
              ),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 30),

            // Final player list with roles revealed
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: state.players.length,
                itemBuilder: (_, i) => PlayerTile(
                  player: state.players[i],
                  showRole: true,
                ),
              ),
            ),

            if (isHost)
              Padding(
                padding: const EdgeInsets.all(16),
                child: GlowingButton(
                  label: 'play_again'.tr(),
                  icon: Icons.replay_rounded,
                  color: AppColors.primary,
                  onTap: () {
                    // Reset and go back to lobby
                    context.go('/');
                  },
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
