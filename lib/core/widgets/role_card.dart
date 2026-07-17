import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../features/game/domain/models/role.dart';
import '../theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RoleCard extends StatefulWidget {
  final Role role;
  final VoidCallback? onFlipped;

  const RoleCard({super.key, required this.role, this.onFlipped});

  @override
  State<RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<RoleCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _flipped = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _anim = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  void _flip() {
    if (!_flipped) {
      _ctrl.forward();
      setState(() => _flipped = true);
      widget.onFlipped?.call();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const neutralColor = Color(0xFF4A4A8A);

    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          final angle = _anim.value;
          final showFront = angle < math.pi / 2;
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: showFront
                ? const _CardFront(color: neutralColor)
                : _CardBack(role: widget.role),
          );
        },
      ),
    );
  }
}

class _CardFront extends StatelessWidget {
  final Color color;
  const _CardFront({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300, height: 440, // جعل البطاقة أكبر
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            Color(0xFF545C6A), // لون رمادي صخري فاتح
            Color(0xFF38404E), // لون رمادي صخري متوسط
            Color(0xFF1E242E), // لون رمادي صخري داكن
          ],
        ),
        border: Border.all(color: Colors.grey.shade800, width: 4),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 5, offset: Offset(0, 10)),
        ],
      ),
      child: Stack(children: [
        Positioned.fill(
          child: CustomPaint(painter: _RockPatternPainter()),
        ),
        Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Image.asset(
              'assets/images/wolf_icon.png',
              width: 100, height: 100,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            const Text('لعبة المستذئبين', style: TextStyle(color: Colors.white70, fontSize: 18, letterSpacing: 2, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('انقر للكشف', style: TextStyle(color: Colors.white30, fontSize: 14)),
          ]),
        ),
      ]),
    );
  }
}

class _CardBack extends StatelessWidget {
  final Role role;
  const _CardBack({required this.role});

  @override
  Widget build(BuildContext context) {
    final info = _getProgrammaticInfo(role.type);
    final color = info.color;
    final String? assetPath = _getAssetPath(role.type);

    return Transform(
      transform: Matrix4.identity()..rotateY(math.pi),
      alignment: Alignment.center,
      child: Container(
        width: 300, height: 440, // مطابقة للحجم الأكبر الجديد
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.8), width: 4),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.4), blurRadius: 50, spreadRadius: 10),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(children: [
            Positioned.fill(
              child: assetPath != null
                ? Image.asset(assetPath, fit: BoxFit.cover)
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [color.withOpacity(0.4), Colors.black, color.withOpacity(0.2)],
                      ),
                    ),
                    child: CustomPaint(painter: _RoleArtPainter(type: role.type, color: color)),
                  ),
            ),

            if (assetPath == null)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                    ),
                  ),
                ),
              ),

            if (assetPath == null)
              Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(info.icon, size: 100, color: color).animate().shimmer(duration: 2.seconds),
                  const SizedBox(height: 20),
                ]),
              ),

            if (assetPath == null)
              Positioned(
                bottom: 40, left: 0, right: 0,
                child: Column(children: [
                  Text(
                    role.nameKey().tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: color, fontSize: 36, fontWeight: FontWeight.w900,
                        shadows: [Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 15)]),
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: color.withOpacity(0.4)),
                    ),
                    child: Text(
                      _getTeamName(role.team),
                      style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                ]),
              ),
          ]),
        ),
      ),
    );
  }

  String? _getAssetPath(RoleType type) {
    switch (type) {
      case RoleType.werewolf: return 'assets/images/card_werewolf.png';
      case RoleType.seer: return 'assets/images/card_seer.png';
      case RoleType.witch: return 'assets/images/card_witch.png';
      case RoleType.hunter: return 'assets/images/card_hunter.png';
      case RoleType.villager: return 'assets/images/card_villager.png';
      case RoleType.crow: return 'assets/images/card_crow.png';
      case RoleType.cupid: return 'assets/images/card_cupid.png';
      case RoleType.doctor: return 'assets/images/card_doctor.png';
      case RoleType.elder: return 'assets/images/card_elder.png';
      case RoleType.fox: return 'assets/images/card_fox.png';
      case RoleType.idiot: return 'assets/images/card_idiot.png';
      case RoleType.thief: return 'assets/images/card_thief.png';
      case RoleType.white_wolf: return 'assets/images/card_white_wolf.png';
      case RoleType.wild_child: return 'assets/images/card_wild_child.png';
      default: return null;
    }
  }

  String _getTeamName(RoleTeam team) {
    switch (team) {
      case RoleTeam.wolves: return 'فريق الذئاب 🐺';
      case RoleTeam.village: return 'فريق القرية 🏘️';
      case RoleTeam.neutral: return 'فريق محايد ⚖️';
      case RoleTeam.solo: return 'فريق منفرد 🎯';
    }
  }

  _ProgrammaticCardInfo _getProgrammaticInfo(RoleType type) {
    switch (type) {
      case RoleType.black_wolf: return _ProgrammaticCardInfo(Icons.pets, const Color(0xFF1A1A1A));
      case RoleType.white_wolf: return _ProgrammaticCardInfo(Icons.wb_sunny_outlined, Colors.white);
      case RoleType.big_bad_wolf: return _ProgrammaticCardInfo(Icons.dangerous_outlined, const Color(0xFF910000));
      case RoleType.doctor: return _ProgrammaticCardInfo(Icons.health_and_safety, const Color(0xFF2ECC71));
      case RoleType.fox: return _ProgrammaticCardInfo(Icons.radar, const Color(0xFFE67E22));
      case RoleType.crow: return _ProgrammaticCardInfo(Icons.auto_awesome_motion, const Color(0xFF34495E));
      case RoleType.cupid: return _ProgrammaticCardInfo(Icons.favorite, const Color(0xFFE91E63));
      case RoleType.elder: return _ProgrammaticCardInfo(Icons.verified_user, const Color(0xFF7F8C8D));
      case RoleType.idiot: return _ProgrammaticCardInfo(Icons.sentiment_very_satisfied, const Color(0xFFF1C40F));
      case RoleType.scapegoat: return _ProgrammaticCardInfo(Icons.help_center, const Color(0xFFD35400));
      case RoleType.devoted_maid: return _ProgrammaticCardInfo(Icons.cleaning_services, const Color(0xFFF39C12));
      case RoleType.thief: return _ProgrammaticCardInfo(Icons.theater_comedy, const Color(0xFF34495E));
      case RoleType.wild_child: return _ProgrammaticCardInfo(Icons.child_care, const Color(0xFFFF5722));
      default: return _ProgrammaticCardInfo(Icons.person, AppColors.success);
    }
  }
}

// رسم شقوق ليعطي انطباع الحجر للبطاقة غير المكشوفة
class _RockPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path1 = Path()
      ..moveTo(size.width * 0.1, 0)
      ..lineTo(size.width * 0.3, size.height * 0.2)
      ..lineTo(size.width * 0.2, size.height * 0.4)
      ..lineTo(size.width * 0.45, size.height * 0.7)
      ..lineTo(size.width * 0.3, size.height);

    final path2 = Path()
      ..moveTo(size.width * 0.8, 0)
      ..lineTo(size.width * 0.6, size.height * 0.25)
      ..lineTo(size.width * 0.75, size.height * 0.45)
      ..lineTo(size.width * 0.55, size.height * 0.8)
      ..lineTo(size.width * 0.7, size.height);
      
    final path3 = Path()
      ..moveTo(0, size.height * 0.3)
      ..lineTo(size.width * 0.3, size.height * 0.3)
      ..lineTo(size.width * 0.5, size.height * 0.4);

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
    canvas.drawPath(path3, paint);
    
    // Some stone scattered dots
    final dotPaint = Paint()..color = Colors.black.withOpacity(0.15)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.8), 3, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.85), 4, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.15), 2.5, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.25), 4, dotPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _RoleArtPainter extends CustomPainter {
  final RoleType type;
  final Color color;
  _RoleArtPainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.08)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    if (type == RoleType.white_wolf || type == RoleType.black_wolf || type == RoleType.big_bad_wolf) {
      for (var i = 1; i <= 8; i++) {
        canvas.drawCircle(Offset(size.width / 2, size.height / 3), i * 30.0, paint);
      }
    } else {
      for (double i = 0; i < size.width + size.height; i += 50) {
        canvas.drawLine(Offset(i, 0), Offset(0, i), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ProgrammaticCardInfo {
  final IconData icon;
  final Color color;
  _ProgrammaticCardInfo(this.icon, this.color);
}
