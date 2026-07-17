import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glowing_button.dart';
import '../../../../core/widgets/role_card.dart';
import '../../../game/domain/models/role.dart';
import '../../../game/domain/providers/role_config_provider.dart';

class OfflineDeckPickerPage extends ConsumerStatefulWidget {
  const OfflineDeckPickerPage({super.key});

  @override
  ConsumerState<OfflineDeckPickerPage> createState() => _State();
}

class _State extends ConsumerState<OfflineDeckPickerPage> {
  bool _started = false;
  List<RoleType>? _deck;
  List<bool>? _picked; // تتبع البطاقات التي تم اختيارها
  int? _selectedCardIndex;
  bool _showFullScreen = false;
  bool _selectedCardFlipped = false;

  void _prepareDeck() {
    final list = ref.read(roleConfigProvider.notifier).flatList;
    if (list.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب اختيار 3 بطاقات على الأقل')),
      );
      return;
    }
    list.shuffle();
    setState(() {
      _deck = list;
      _picked = List.generate(list.length, (_) => false);
      _started = true;
      _selectedCardIndex = null;
      _showFullScreen = false;
    });
  }

  void _pickCard(int index) {
    if (_picked![index]) return;
    setState(() {
      _selectedCardIndex = index;
      _showFullScreen = true;
      _selectedCardFlipped = false;
    });
  }

  void _confirmAndClose() {
    setState(() {
      _picked![_selectedCardIndex!] = true;
      _showFullScreen = false;
      _selectedCardIndex = null;
    });

    // إذا انتهت جميع البطاقات نعود للرئيسية
    if (_picked!.every((p) => p)) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) context.go('/');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) return _buildSetup();
    return _buildDeckView();
  }

  Widget _buildSetup() {
    final config = ref.watch(roleConfigProvider);
    final total = config.values.fold(0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(title: const Text('إعداد مجموعة البطاقات')),
      body: Column(children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'اختر الأدوار التي ستكون في المجموعة المقلوبة ليختار منها اللاعبون',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecond, fontSize: 14),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: RoleType.values.map((rt) {
              final count = config[rt] ?? 0;
              final info = _getRoleInfo(rt);
              return ListTile(
                title: Text(info['name'], style: TextStyle(color: info['color'])),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger),
                      onPressed: () => ref.read(roleConfigProvider.notifier).decrease(rt),
                    ),
                    Text('$count', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.success),
                      onPressed: () => ref.read(roleConfigProvider.notifier).increase(rt),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: GlowingButton(
            label: 'إنشاء المجموعة ($total بطاقة)',
            icon: Icons.layers_outlined,
            color: total >= 3 ? AppColors.accent : AppColors.textSecond,
            onTap: total >= 3 ? _prepareDeck : null,
          ),
        ),
      ]),
    );
  }

  Widget _buildDeckView() {
    final remainingCount = _picked!.where((p) => !p).length;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFF0D0D2B), Color(0xFF0D0D1A)],
              ),
            ),
            child: SafeArea(
              child: Column(children: [
                const SizedBox(height: 10),
                const Text('اختر بطاقة واحدة 🃏',
                  style: TextStyle(color: AppColors.gold, fontSize: 24, fontWeight: FontWeight.bold)),
                Text('بقي $remainingCount بطاقات مخفية',
                  style: const TextStyle(color: AppColors.textSecond, fontSize: 13)),
                const SizedBox(height: 20),

                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // خفضنا العدد إلى 2 لتصبح البطاقات أكبر
                      childAspectRatio: 0.65, // جعلها أطول قليلاً
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: _deck!.length,
                    itemBuilder: (context, index) {
                      final picked = _picked![index];
                      if (picked) return const SizedBox(); 

                      return GestureDetector(
                        onTap: () => _pickCard(index),
                        child: Hero(
                          tag: 'card-$index',
                          child: _MiniCardFront(),
                        ),
                      ).animate().scale(delay: (index * 50).ms).fadeIn();
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton(
                    onPressed: () => setState(() => _started = false),
                    child: const Text('إعادة ضبط الأدوار', style: TextStyle(color: AppColors.textSecond)),
                  ),
                ),
              ]),
            ),
          ),

          if (_showFullScreen)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.9),
                child: SafeArea(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('كشف البطاقة',
                      style: TextStyle(color: AppColors.gold, fontSize: 30, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    const Text('احفظ دورك بخصوصية ثم أغلق البطاقة',
                      style: TextStyle(color: AppColors.textSecond)),
                    const Spacer(),

                    RoleCard(
                      key: ValueKey('selected-$_selectedCardIndex'),
                      role: Role.all[_deck![_selectedCardIndex!]]!,
                      onFlipped: () => setState(() => _selectedCardFlipped = true),
                    ),

                    const Spacer(),

                    if (_selectedCardFlipped) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: TextButton.icon(
                          onPressed: () => _showRoleDesc(Role.all[_deck![_selectedCardIndex!]]!),
                          icon: const Icon(Icons.info_outline, color: AppColors.accent),
                          label: const Text('شرح قدرات الدور', style: TextStyle(color: AppColors.accent)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: GlowingButton(
                          label: 'حفظ وإخفاء البطاقة',
                          icon: Icons.visibility_off_outlined,
                          color: AppColors.success,
                          onTap: _confirmAndClose,
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ]),
                ),
              ).animate().fadeIn(duration: 400.ms),
            ),
        ],
      ),
    );
  }

  void _showRoleDesc(Role role) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(role.nameKey().tr(), style: const TextStyle(color: AppColors.primary)),
        content: Text(role.descKey().tr(), style: const TextStyle(color: AppColors.text)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('فهمت')),
        ],
      ),
    );
  }

  Map<String, dynamic> _getRoleInfo(RoleType rt) {
    switch (rt) {
      case RoleType.werewolf: return {'name': 'مستذئب', 'color': AppColors.danger};
      case RoleType.seer: return {'name': 'عرّافة', 'color': AppColors.accent};
      case RoleType.witch: return {'name': 'ساحرة', 'color': const Color(0xFF9B59B6)};
      case RoleType.hunter: return {'name': 'صيّاد', 'color': AppColors.day};
      case RoleType.doctor: return {'name': 'طبيب', 'color': const Color(0xFF2ECC71)};
      case RoleType.thief: return {'name': 'سارق', 'color': const Color(0xFF34495E)};
      case RoleType.fox: return {'name': 'ثعلب', 'color': const Color(0xFFE67E22)};
      case RoleType.cupid: return {'name': 'كيوبيد', 'color': const Color(0xFFE91E63)};
      case RoleType.elder: return {'name': 'كبير القرية', 'color': const Color(0xFF7F8C8D)};
      case RoleType.idiot: return {'name': 'الأحمق', 'color': const Color(0xFFF1C40F)};
      case RoleType.wild_child: return {'name': 'الطفل البري', 'color': const Color(0xFFD35400)};
      case RoleType.white_wolf: return {'name': 'الذئب الأبيض', 'color': Colors.white};
      case RoleType.big_bad_wolf: return {'name': 'والد الذئاب', 'color': const Color(0xFF7B0000)};
      case RoleType.crow: return {'name': 'الغراب', 'color': const Color(0xFF2C3E50)};
      case RoleType.scapegoat: return {'name': 'كبش الفداء', 'color': const Color(0xFFD35400)};
      case RoleType.devoted_maid: return {'name': 'الخادمة المخلصة', 'color': const Color(0xFFF39C12)};
      case RoleType.black_wolf: return {'name': 'الذئب الأسود', 'color': const Color(0xFF121212)};
      default: return {'name': 'قروي', 'color': AppColors.success};
    }
  }
}

// بطاقة صغيرة صخرية للعرض في الشبكة
class _MiniCardFront extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            Color(0xFF545C6A), // لون رمادي صخري فاتح
            Color(0xFF38404E), // لون رمادي صخري متوسط
            Color(0xFF1E242E), // لون رمادي صخري داكن
          ],
        ),
        border: Border.all(color: Colors.grey.shade800, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 5)),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
             child: CustomPaint(painter: _MiniRockPatternPainter()),
          ),
          Center(
            child: Image.asset(
              'assets/images/wolf_icon.png',
              width: 50, height: 50,
              color: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }
}

// رسم تشققات حجرية مصغرة للبطاقة الصغيرة
class _MiniRockPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path1 = Path()
      ..moveTo(size.width * 0.1, 0)
      ..lineTo(size.width * 0.3, size.height * 0.3)
      ..lineTo(size.width * 0.2, size.height * 0.6)
      ..lineTo(size.width * 0.45, size.height);

    final path2 = Path()
      ..moveTo(size.width * 0.8, 0)
      ..lineTo(size.width * 0.6, size.height * 0.4)
      ..lineTo(size.width * 0.8, size.height * 0.8)
      ..lineTo(size.width * 0.6, size.height);

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
    
    final dotPaint = Paint()..color = Colors.black.withOpacity(0.15)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.8), 2.5, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 3, dotPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}
