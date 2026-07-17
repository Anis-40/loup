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

class OfflineDistributorPage extends ConsumerStatefulWidget {
  const OfflineDistributorPage({super.key});

  @override
  ConsumerState<OfflineDistributorPage> createState() => _State();
}

class _State extends ConsumerState<OfflineDistributorPage> {
  bool _started = false;
  bool _collectingNames = false;
  List<RoleType>? _roles;
  final List<TextEditingController> _nameCtrls = [];
  int _currentIndex = 0;
  bool _flipped = false;

  void _prepareNames() {
    final list = ref.read(roleConfigProvider.notifier).flatList;
    if (list.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب اختيار 3 أدوار على الأقل')),
      );
      return;
    }
    list.shuffle();
    _roles = list;
    _nameCtrls.clear();
    for (int i = 0; i < _roles!.length; i++) {
      _nameCtrls.add(TextEditingController());
    }
    setState(() {
      _collectingNames = true;
    });
  }

  void _startDistribution() {
    for (var ctrl in _nameCtrls) {
      if (ctrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى إدخال جميع أسماء اللاعبين')),
        );
        return;
      }
    }
    setState(() {
      _collectingNames = false;
      _started = true;
      _currentIndex = 0;
      _flipped = false;
    });
  }

  void _next() {
    if (_currentIndex < _roles!.length - 1) {
      setState(() {
        _currentIndex++;
        _flipped = false;
      });
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_started) return _buildDistributor();
    if (_collectingNames) return _buildNameInput();
    return _buildSetup();
  }

  Widget _buildSetup() {
    final config = ref.watch(roleConfigProvider);
    final total = config.values.fold(0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(title: const Text('1. اختيار الأدوار')),
      body: Column(children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'حدد عدد البطاقات التي ستوزعها يدوياً',
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
            label: 'التالي: إدخال الأسماء ($total)',
            icon: Icons.arrow_forward_rounded,
            color: total >= 3 ? AppColors.primary : AppColors.textSecond,
            onTap: total >= 3 ? _prepareNames : null,
          ),
        ),
      ]),
    );
  }

  Widget _buildNameInput() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('2. أسماء اللاعبين'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _collectingNames = false),
        ),
      ),
      body: Column(children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('أدخل أسماء اللاعبين لضمان الشفافية في التوزيع',
            style: TextStyle(color: AppColors.textSecond)),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _nameCtrls.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: _nameCtrls[i],
                decoration: InputDecoration(
                  labelText: 'اللاعب رقم ${i + 1}',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: GlowingButton(
            label: 'ابدأ توزيع البطاقات',
            icon: Icons.play_arrow_rounded,
            color: AppColors.success,
            onTap: _startDistribution,
          ),
        ),
      ]),
    );
  }

  Widget _buildDistributor() {
    final roleType = _roles![_currentIndex];
    final role = Role.all[roleType]!;
    final playerName = _nameCtrls[_currentIndex].text.trim();
    final isLast = _currentIndex == _roles!.length - 1;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0D2B), Color(0xFF0D0D1A)],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            const SizedBox(height: 40),
            Text(
              playerName,
              style: const TextStyle(color: AppColors.gold, fontSize: 32, fontWeight: FontWeight.w900),
            ).animate().fadeIn().scale(),
            const SizedBox(height: 8),
            Text(
              _flipped ? 'احفظ دورك جيداً ثم مرر الهاتف' : 'مرر الهاتف لـ $playerName ثم انقر للكشف',
              style: const TextStyle(color: AppColors.textSecond, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            RoleCard(
              key: ValueKey('$_currentIndex-$_flipped'), // Force reset only on next
              role: role,
              onFlipped: () => setState(() => _flipped = true),
            ),
            const Spacer(),
            if (_flipped) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: TextButton.icon(
                  onPressed: () => _showRoleDesc(role),
                  icon: const Icon(Icons.info_outline, color: AppColors.accent),
                  label: const Text('شرح قدرات الدور', style: TextStyle(color: AppColors.accent)),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: GlowingButton(
                  label: isLast ? 'تم التوزيع بنجاح' : 'اللاعب التالي',
                  icon: isLast ? Icons.check_circle : Icons.arrow_forward_rounded,
                  color: AppColors.success,
                  onTap: _next,
                ),
              ),
            ],
            const SizedBox(height: 40),
          ]),
        ),
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
      default: return {'name': 'قروي', 'color': AppColors.success};
    }
  }

  @override
  void dispose() {
    for (var c in _nameCtrls) {
      c.dispose();
    }
    super.dispose();
  }
}
