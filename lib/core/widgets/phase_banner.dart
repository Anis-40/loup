import 'package:flutter/material.dart';
import '../../features/game/domain/models/game_state.dart';
import '../theme/app_theme.dart';

class PhaseBanner extends StatelessWidget {
  final GamePhase phase;
  const PhaseBanner({super.key, required this.phase});

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = _phaseInfo(phase);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        border: Border(bottom: BorderSide(color: color.withOpacity(0.4))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  (String, IconData, Color) _phaseInfo(GamePhase p) {
    switch (p) {
      case GamePhase.night:   return ('الليل', Icons.nightlight_round, AppColors.night.withBlue(180));
      case GamePhase.day:     return ('النهار', Icons.wb_sunny, AppColors.day);
      case GamePhase.voting:  return ('التصويت', Icons.how_to_vote, AppColors.accent);
      case GamePhase.lobby:   return ('غرفة الانتظار', Icons.meeting_room, AppColors.primary);
      default:                return ('اللعبة', Icons.gamepad, AppColors.primary);
    }
  }
}
