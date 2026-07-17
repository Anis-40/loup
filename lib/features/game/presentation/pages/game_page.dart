import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glowing_button.dart';
import '../../../../core/widgets/phase_banner.dart';
import '../../../../core/widgets/player_tile.dart';
import '../../../../core/widgets/role_card.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/player.dart';
import '../../domain/models/role.dart';
import '../../domain/providers/game_provider.dart';

class GamePage extends ConsumerWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state  = ref.watch(gameStateProvider);
    final player = ref.watch(currentPlayerProvider);
    final isHost = ref.watch(isHostProvider);

    ref.listen<GameState>(gameStateProvider, (_, next) {
      if (next.phase == GamePhase.gameOver) context.go('/game-over');
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('الجولة: ${state.round}'),
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: PhaseBanner(phase: state.phase),
        ),
      ),
      body: _buildBody(context, ref, state, player, isHost),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref,
      GameState state, player, bool isHost) {
    switch (state.phase) {
      case GamePhase.roleReveal:
        return _RoleRevealView(player: player, isHost: isHost, ref: ref);
      case GamePhase.mayorElection:
        return _MayorElectionView(state: state, player: player, isHost: isHost, ref: ref);
      case GamePhase.night:
        return _NightView(state: state, player: player, isHost: isHost, ref: ref);
      case GamePhase.day:
        return _DayView(state: state, isHost: isHost, ref: ref);
      case GamePhase.voting:
        return _VotingView(state: state, player: player, isHost: isHost, ref: ref);
      default:
        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
  }
}

// ─── Narrator Panel Widget ──────────────────────────────────────────────────
class _NarratorPanel extends StatelessWidget {
  final String title;
  final List<String> instructions;
  final Widget? action;
  const _NarratorPanel({required this.title, required this.instructions, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.5), width: 1.5),
        boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.auto_awesome, color: AppColors.gold, size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
        ]),
        const Divider(color: AppColors.gold, height: 20, thickness: 0.5),
        ...instructions.map((ins) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('• ', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
            Expanded(child: Text(ins, style: const TextStyle(color: AppColors.text, fontSize: 13))),
          ]),
        )),
        if (action != null) ...[
          const SizedBox(height: 12),
          action!,
        ],
      ]),
    );
  }
}

// ─── 3D Flip Role Card ────────────────────────────────────────────────────────
class _RoleRevealView extends StatefulWidget {
  final Player? player;
  final bool isHost;
  final WidgetRef ref;
  const _RoleRevealView({this.player, required this.isHost, required this.ref});
  @override
  State<_RoleRevealView> createState() => _RoleRevealViewState();
}

class _RoleRevealViewState extends State<_RoleRevealView> {
  bool _flipped = false;

  @override
  Widget build(BuildContext context) {
    final role = widget.player?.role;
    if (role == null) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text('جارٍ توزيع الأدوار...', style: TextStyle(color: AppColors.textSecond)),
        ]),
      );
    }

    final isWolf = role.team == RoleTeam.wolves;
    final cardColor = isWolf ? AppColors.danger : AppColors.success;
    final bgGrad = isWolf
        ? const [Color(0xFF1A0000), Color(0xFF0D0D1A)]
        : const [Color(0xFF0A1A00), Color(0xFF0D0D1A)];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: bgGrad,
        ),
      ),
      child: SafeArea(
        child: Column(children: [
          if (widget.isHost)
            _NarratorPanel(
              title: 'تعليمات الراوي: توزيع الأدوار',
              instructions: const [
                'اطلب من اللاعبين الضغط على البطاقة لكشف أدوارهم.',
                'تأكد من عدم رؤية الآخرين لبطاقات بعضهم.',
                'عندما ينتهي الجميع، اطلب منهم إغلاق أعينهم وابدأ الليل.',
              ],
              action: GlowingButton(
                label: 'بدء انتخاب العمدة',
                icon: Icons.how_to_vote,
                color: AppColors.accent,
                onTap: () => widget.ref.read(gameStateProvider.notifier).startMayorElection(),
              ),
            ),

          const SizedBox(height: 12),
          Text(
            _flipped ? role.nameKey().tr() : 'اضغط على البطاقة لكشف دورك',
            style: TextStyle(
              color: _flipped ? cardColor : AppColors.textSecond,
              fontSize: _flipped ? 28 : 16,
              fontWeight: _flipped ? FontWeight.w900 : FontWeight.normal,
              shadows: _flipped
                  ? [Shadow(color: cardColor.withOpacity(0.5), blurRadius: 20)]
                  : null,
            ),
          ).animate().fadeIn(),

          const Spacer(),
          RoleCard(
            role: role,
            onFlipped: () => setState(() => _flipped = true),
          ),
          const Spacer(),

          if (_flipped) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardColor.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(color: cardColor.withOpacity(0.1), blurRadius: 20),
                  ],
                ),
                child: Text(
                  role.descKey().tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.text, fontSize: 15, height: 1.7),
                ),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
            const SizedBox(height: 12),
            if (widget.isHost)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GlowingButton(
                  label: 'بدء الليل مباشرة (بدون عمدة)',
                  icon: Icons.nightlight_round,
                  color: AppColors.primary,
                  onTap: () => widget.ref.read(gameStateProvider.notifier).goToNight(),
                ),
              ),
            if (!widget.isHost)
              const Padding(
                padding: EdgeInsets.only(top: 10, bottom: 4),
                child: Text('انتظر المدير للمتابعة...',
                    style: TextStyle(color: AppColors.textSecond, fontSize: 13)),
              ),
          ] else ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Icon(Icons.touch_app, color: AppColors.textSecond, size: 28),
            ),
          ],
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

// ── رسام نمط البطاقة الخلفي ──────────────────────────────────────────────────
class _CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.08)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (double i = 0; i < size.width + size.height; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(0, i), paint);
      canvas.drawLine(Offset(size.width, i), Offset(i, size.height), paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// ─── Mayor Election View ──────────────────────────────────────────────────────
class _MayorElectionView extends StatefulWidget {
  final GameState state;
  final Player? player;
  final bool isHost;
  final WidgetRef ref;
  const _MayorElectionView({required this.state, this.player, required this.isHost, required this.ref});
  @override
  State<_MayorElectionView> createState() => _MayorElectionViewState();
}

class _MayorElectionViewState extends State<_MayorElectionView> {
  String? _myVote;
  @override
  Widget build(BuildContext context) {
    final alive = widget.state.alivePlayers;
    return Column(children: [
      if (widget.isHost)
        _NarratorPanel(
          title: 'تعليمات الراوي: انتخاب العمدة',
          instructions: const [
            'اطلب من اللاعبين ترشيح أنفسهم لمنصب العمدة.',
            'اسمح لكل مرشح بإلقاء خطاب قصير.',
            'اطلب من الجميع التصويت الآن على هواتفهم.',
            'بعد انتهاء التصويت، اضغط على زر النتائج.',
          ],
          action: GlowingButton(
            label: 'تتويج العمدة والذهاب لليوم',
            icon: Icons.celebration,
            color: AppColors.success,
            onTap: () => widget.ref.read(gameStateProvider.notifier).resolveMayorElection(),
          ),
        ),
      const SizedBox(height: 12),
      Text('انتخاب عمدة القرية 🎖️', style: const TextStyle(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.bold)),
      const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('العمدة له صوتان في التصويت النهاري', style: TextStyle(color: AppColors.textSecond, fontSize: 12)),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: alive.length,
          itemBuilder: (_, i) {
            final p = alive[i];
            final selected = _myVote == p.id;
            return GestureDetector(
              onTap: () {
                setState(() => _myVote = p.id);
                widget.ref.read(gameStateProvider.notifier).sendVote(widget.player!.id, p.id);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary.withOpacity(0.2) : AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? AppColors.primary : AppColors.primary.withOpacity(0.1)),
                ),
                child: Row(children: [
                   Text(p.name, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
                   const Spacer(),
                   if (selected) const Icon(Icons.check_circle, color: AppColors.primary),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

// ─── Night View ───────────────────────────────────────────────────────────────
class _NightView extends StatefulWidget {
  final GameState state;
  final Player? player;
  final bool isHost;
  final WidgetRef ref;
  const _NightView({required this.state, this.player, required this.isHost, required this.ref});
  @override
  State<_NightView> createState() => _NightViewState();
}

class _NightViewState extends State<_NightView> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final myRole = widget.player?.role;
    final alivePlayers = widget.state.alivePlayers;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF020210), Color(0xFF0D0D1A)],
        ),
      ),
      child: SafeArea(
        child: Column(children: [
          if (widget.isHost)
            _NarratorPanel(
              title: 'تعليمات الراوي: الليل يحلّ',
              instructions: const [
                'اطلب من الجميع إغلاق أعينهم (الكل ينام).',
                'نادي المستذئبين: يفتحون أعينهم ويختارون ضحية.',
                'نادي الطبيب: يفتح عينيه ويختار شخصاً ليحميه.',
                'نادي العرّافة: تفتح عينيها وتكشف هوية لاعب.',
                'تأكد من تسجيل جميع الحركات قبل الانتقال لليوم.',
              ],
              action: GlowingButton(
                label: 'شروق الشمس (الذهاب لليوم)',
                icon: Icons.wb_sunny,
                color: AppColors.day,
                onTap: () => widget.ref.read(gameStateProvider.notifier).goToDay(),
              ),
            ),

          const SizedBox(height: 12),
          const Icon(Icons.nightlight_round, size: 50, color: Color(0xFF6060FF)),
          const SizedBox(height: 8),
          Text('night_phase'.tr(),
              style: const TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          if (_canAct(myRole?.type))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_instructionForRole(myRole?.type), style: const TextStyle(color: AppColors.accent)),
            ),

          if (_canAct(myRole?.type))
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: alivePlayers.length,
                itemBuilder: (_, i) {
                  final p = alivePlayers[i];
                  final selected = _selected == p.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = p.id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary.withOpacity(0.3) : AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected
                            ? AppColors.primary : AppColors.primary.withOpacity(0.2)),
                      ),
                      child: ListTile(
                        title: Text(p.name, style: const TextStyle(color: AppColors.text)),
                        trailing: selected
                            ? const Icon(Icons.check_circle, color: AppColors.primary)
                            : null,
                      ),
                    ),
                  );
                },
              ),
            )
          else
            const Expanded(child: Center(
              child: Text('القرية نائمة... 😴',
                  style: TextStyle(color: AppColors.textSecond, fontSize: 18)),
            )),

          if (_canAct(myRole?.type) && _selected != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: GlowingButton(
                label: 'تأكيد الحركة',
                color: AppColors.danger,
                onTap: () {
                  final action = _actionForRole(myRole!.type);
                  widget.ref.read(gameStateProvider.notifier).sendNightAction(
                      action, _selected!, widget.player!.id);
                  setState(() => _selected = null);
                },
              ),
            ),
        ]),
      ),
    );
  }

  bool _canAct(RoleType? t) => t == RoleType.werewolf || t == RoleType.seer || t == RoleType.doctor;

  String _instructionForRole(RoleType? t) {
    if (t == RoleType.werewolf) return 'choose_victim'.tr();
    if (t == RoleType.seer) return 'choose_to_reveal'.tr();
    if (t == RoleType.doctor) return 'اختر لاعباً لحمايته من الذئاب الليلة';
    return '';
  }

  String _actionForRole(RoleType t) {
    if (t == RoleType.werewolf) return 'WOLF_KILL';
    if (t == RoleType.seer) return 'SEER_REVEAL';
    if (t == RoleType.doctor) return 'DOCTOR_SAVE';
    return '';
  }
}

// ─── Day View ─────────────────────────────────────────────────────────────────
class _DayView extends StatelessWidget {
  final GameState state;
  final bool isHost;
  final WidgetRef ref;
  const _DayView({required this.state, required this.isHost, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (isHost)
        _NarratorPanel(
          title: 'تعليمات الراوي: الصباح',
          instructions: const [
            'أخبر الجميع من مات الليلة (أو إذا لم يمت أحد بفضل الطبيب).',
            'افتح باب النقاش بين القرويين لاكتشاف الذئاب.',
            'يمكنك إقصاء أي لاعب يدوياً إذا خالف القواعد أو مات بقرارك.',
            'عندما ينتهي النقاش، ابدأ مرحلة التصويت الرسمي.',
          ],
          action: GlowingButton(
            label: 'فتح باب التصويت الرسمي',
            icon: Icons.how_to_vote,
            color: AppColors.accent,
            onTap: () => ref.read(gameStateProvider.notifier).startVoting(),
          ),
        ),

      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.wb_sunny, color: AppColors.day, size: 30),
        const SizedBox(width: 10),
        Text('day_phase'.tr(), style: const TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 12),

      Expanded(
        child: ListView.builder(
          itemCount: state.players.length,
          itemBuilder: (_, i) {
            final p = state.players[i];
            return Stack(children: [
              PlayerTile(player: p, isHost: isHost, showRole: p.roleRevealed),
              if (isHost && p.isAlive)
                Positioned(
                  left: 20, top: 10,
                  child: IconButton(
                    icon: const Icon(Icons.no_accounts, color: AppColors.danger, size: 20),
                    tooltip: 'إقصاء يدوي (قتل)',
                    onPressed: () => _confirmKill(context, ref, p),
                  ),
                ),
            ]);
          },
        ),
      ),
    ]);
  }

  void _confirmKill(BuildContext context, WidgetRef ref, Player p) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('تأكيد الإقصاء'),
      content: Text('هل أنت متأكد من قتل اللاعب "${p.name}"؟ سيتم كشف دوره للجميع.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        TextButton(
          onPressed: () {
            ref.read(gameStateProvider.notifier).eliminatePlayer(p.id);
            Navigator.pop(ctx);
          },
          child: const Text('تأكيد القتل', style: TextStyle(color: AppColors.danger)),
        ),
      ],
    ));
  }
}

// ─── Voting View ──────────────────────────────────────────────────────────────
class _VotingView extends StatefulWidget {
  final GameState state;
  final Player? player;
  final bool isHost;
  final WidgetRef ref;
  const _VotingView({required this.state, this.player, required this.isHost, required this.ref});
  @override
  State<_VotingView> createState() => _VotingViewState();
}

class _VotingViewState extends State<_VotingView> {
  String? _myVote;
  bool _voted = false;

  @override
  Widget build(BuildContext context) {
    final votes = widget.state.currentVotes;
    final alive = widget.state.alivePlayers;

    return Column(children: [
      if (widget.isHost)
        _NarratorPanel(
          title: 'تعليمات الراوي: المحكمة والشنق',
          instructions: const [
            'الآن يقوم الجميع بالتصويت على هاتفهم.',
            'تذكر: العمدة صوته يحسب عن صوتين.',
            'عند اكتمال التصويت، اضغط لشنق صاحب أعلى الأصوات.',
          ],
          action: GlowingButton(
            label: 'تنفيذ حكم الإعدام والذهاب لليل',
            icon: Icons.gavel,
            color: AppColors.danger,
            onTap: () => widget.ref.read(gameStateProvider.notifier).resolveVotes(),
          ),
        ),

      const SizedBox(height: 12),
      Text('vote_phase'.tr(), style: const TextStyle(color: AppColors.accent, fontSize: 22, fontWeight: FontWeight.bold)),
      const Text('اختر من تريد طرده من القرية', style: TextStyle(color: AppColors.textSecond, fontSize: 13)),
      const SizedBox(height: 12),

      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: alive.length,
          itemBuilder: (_, i) {
            final p = alive[i];

            // حساب الأصوات مع اعتبار العمدة
            double totalWeight = 0;
            votes.forEach((voterId, targetId) {
               if (targetId == p.id) {
                 final isMayor = widget.state.players.any((pl) => pl.id == voterId && pl.isMayor);
                 totalWeight += isMayor ? 2.0 : 1.0;
               }
            });

            final selected = _myVote == p.id;
            final isMe = p.id == widget.player?.id;

            return GestureDetector(
              onTap: (!_voted && !isMe) ? () {
                setState(() { _myVote = p.id; });
                widget.ref.read(gameStateProvider.notifier).sendVote(widget.player!.id, p.id);
                setState(() => _voted = true);
              } : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AppColors.accent.withOpacity(0.2) : AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? AppColors.accent : AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(children: [
                  Expanded(child: Text(p.name, style: TextStyle(color: isMe ? AppColors.textSecond : AppColors.text, fontWeight: FontWeight.bold))),
                  if (totalWeight > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${totalWeight.toInt()} 🗳️', style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                    ),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}
