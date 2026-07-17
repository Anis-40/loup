import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glowing_button.dart';
import '../../../game/domain/models/role.dart';
import '../../../game/domain/providers/role_config_provider.dart';
import '../../../game/domain/providers/game_provider.dart';

class RoleSettingsPage extends ConsumerWidget {
  const RoleSettingsPage({super.key});

  Widget _RoleTile(RoleType rt, int count, Map<String, dynamic> info, WidgetRef ref) {
    final color = info['color'] as Color;
    final isActive = count > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.08) : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? color.withOpacity(0.5) : AppColors.card,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        // صورة البطاقة
        ClipRRect(
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
          child: Image.asset(
            info['img'] as String,
            width: 70, height: 90,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 70, height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.4), color.withOpacity(0.1)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: Icon(Icons.auto_awesome, color: color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // المعلومات
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(info['name'] as String,
                style: TextStyle(color: color,
                  fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(info['team'] as String,
                  style: TextStyle(color: color, fontSize: 10)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(info['desc'] as String,
              style: const TextStyle(color: AppColors.textSecond, fontSize: 11),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          ]),
        ),
        // أزرار +/-
        Column(children: [
          IconButton(
            icon: Icon(Icons.add_circle, color: color, size: 28),
            onPressed: () => ref.read(roleConfigProvider.notifier).increase(rt),
          ),
          Text(
            '$count',
            style: TextStyle(
              color: isActive ? color : AppColors.textSecond,
              fontSize: 18, fontWeight: FontWeight.w900),
          ),
          IconButton(
            icon: Icon(
              Icons.remove_circle,
              color: count > 0 ? AppColors.danger : AppColors.textSecond,
              size: 28,
            ),
            onPressed: count > 0 ? () => ref.read(roleConfigProvider.notifier).decrease(rt) : null,
          ),
        ]),
        const SizedBox(width: 4),
      ]),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(roleConfigProvider);
    final total  = config.values.fold(0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(title: const Text('⚙️ إعداد الأدوار')),
      body: Column(children: [
        // ── شريط الإجمالي ─────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold.withOpacity(0.4)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('إجمالي البطاقات: $total',
              style: const TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
        ),

        // ── قائمة الأدوار ───────────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: RoleType.values.map((rt) {
              final count = config[rt] ?? 0;
              final info  = _roleInfo(rt);
              return _RoleTile(rt, count, info, ref);
            }).toList(),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: GlowingButton(
            label: 'حفظ الإعدادات',
            icon: Icons.check_circle_outline,
            color: total >= 3 ? AppColors.success : AppColors.textSecond,
            onTap: total >= 3 ? () => Navigator.of(context).pop() : null,
          ),
        ),
      ]),
    );
  }

  Map<String, dynamic> _roleInfo(RoleType rt) {
    switch (rt) {
      case RoleType.werewolf:
        return {'name': 'المستذئب', 'team': 'ذئاب', 'color': AppColors.danger,
          'img': 'assets/images/card_werewolf.png',
          'desc': 'يقتل قروياً كل ليلة مع رفاقه'};
      case RoleType.seer:
        return {'name': 'العرّافة', 'team': 'قرية', 'color': AppColors.accent,
          'img': 'assets/images/card_seer.png',
          'desc': 'تكشف كل ليلة هوية لاعب واحد'};
      case RoleType.witch:
        return {'name': 'الساحرة', 'team': 'قرية', 'color': const Color(0xFF9B59B6),
          'img': 'assets/images/card_witch.png',
          'desc': 'تملك دواء إنقاذ ودواء قتل (مرة واحدة لكل)'};
      case RoleType.hunter:
        return {'name': 'الصياد', 'team': 'قرية', 'color': AppColors.day,
          'img': 'assets/images/card_hunter.png',
          'desc': 'عند قتله يختار لاعباً آخر يموت معه'};
      case RoleType.villager:
        return {'name': 'القروي', 'team': 'قرية', 'color': AppColors.success,
          'img': 'assets/images/card_villager.png',
          'desc': 'يصوت نهاراً لطرد المشتبه بهم'};
      case RoleType.doctor:
        return {'name': 'الطبيب', 'team': 'قرية', 'color': const Color(0xFF2ECC71),
          'img': 'assets/images/card_doctor.png',
          'desc': 'يحمي لاعباً من هجوم الذئاب كل ليلة'};
      case RoleType.thief:
        return {'name': 'السارق', 'team': 'محايد', 'color': const Color(0xFF34495E),
          'img': 'assets/images/card_thief.png',
          'desc': 'يختار تبديل دوره في بداية اللعبة'};
      case RoleType.fox:
        return {'name': 'الثعلب', 'team': 'قرية', 'color': const Color(0xFFE67E22),
          'img': 'assets/images/card_fox.png',
          'desc': 'يكتشف وجود الذئاب في مجموعات اللاعبين'};
      case RoleType.cupid:
        return {'name': 'كيوبيد', 'team': 'قرية', 'color': const Color(0xFFE91E63),
          'img': 'assets/images/card_cupid.png',
          'desc': 'يربط بين قلبين، إذا مات أحدهما مات الآخر'};
      case RoleType.elder:
        return {'name': 'كبير القرية', 'team': 'قرية', 'color': const Color(0xFF7F8C8D),
          'img': 'assets/images/card_elder.png',
          'desc': 'ينجو من أول هجوم للذئاب عليه'};
      case RoleType.idiot:
        return {'name': 'الأحمق', 'team': 'قرية', 'color': const Color(0xFFF1C40F),
          'img': 'assets/images/card_idiot.png',
          'desc': 'يكشف دوره ويبقى حياً عند التصويت ضده'};
      case RoleType.wild_child:
        return {'name': 'الطفل البري', 'team': 'محايد', 'color': const Color(0xFFD35400),
          'img': 'assets/images/card_wild_child.png',
          'desc': 'قد يتحول لمستذئب إذا ماتت قدوته'};
      case RoleType.white_wolf:
        return {'name': 'الذئب الأبيض', 'team': 'منفرد', 'color': Colors.white,
          'img': 'assets/images/card_white_wolf.png',
          'desc': 'يقتل مستذئباً كل ليلتين ليفوز وحيداً'};
      case RoleType.big_bad_wolf:
        return {'name': 'والد الذئاب', 'team': 'ذئاب', 'color': const Color(0xFF7B0000),
          'img': 'assets/images/card_big_wolf.png',
          'desc': 'يقتل ضحيتين كل ليلة طالما لم يمت أي ذئب'};
      case RoleType.crow:
        return {'name': 'الغراب', 'team': 'قرية', 'color': const Color(0xFF2C3E50),
          'img': 'assets/images/card_crow.png',
          'desc': 'يلعن لاعباً ليحصل على صوتين ضده تلقائياً'};
      case RoleType.scapegoat:
        return {'name': 'كبش الفداء', 'team': 'قرية', 'color': const Color(0xFFD35400),
          'img': 'assets/images/card_scapegoat.png',
          'desc': 'يموت عند تعادل الأصوات في التصويت'};
      case RoleType.devoted_maid:
        return {'name': 'الخادمة المخلصة', 'team': 'قرية', 'color': const Color(0xFFF39C12),
          'img': 'assets/images/card_maid.png',
          'desc': 'تضحي بنفسها لتأخذ دور لاعب ميت'};
      case RoleType.black_wolf:
        return {'name': 'الذئب الأسود', 'team': 'ذئاب', 'color': const Color(0xFF121212),
          'img': 'assets/images/card_black_wolf.png',
          'desc': 'ذئب قوي يمكنه تحويل قروي لمستذئب'};
    }
  }
}

class _RoleTile extends StatelessWidget {
  final RoleType roleType;
  final int count;
  final Map<String, dynamic> info;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  const _RoleTile({required this.roleType, required this.count,
    required this.info, required this.onIncrease, required this.onDecrease});

  @override
  Widget build(BuildContext context) {
    final color = info['color'] as Color;
    final isActive = count > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.08) : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? color.withOpacity(0.5) : AppColors.card,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        // صورة البطاقة
        ClipRRect(
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
          child: Image.asset(
            info['img'] as String,
            width: 70, height: 90,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 70, height: 90,
              color: color.withOpacity(0.2),
              child: Icon(Icons.person, color: color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // المعلومات
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(info['name'] as String,
                style: TextStyle(color: color,
                  fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(info['team'] as String,
                  style: TextStyle(color: color, fontSize: 10)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(info['desc'] as String,
              style: const TextStyle(color: AppColors.textSecond, fontSize: 11),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          ]),
        ),
        // أزرار +/-
        Column(children: [
          IconButton(
            icon: Icon(Icons.add_circle, color: color, size: 28),
            onPressed: onIncrease,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? color.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: isActive ? color : AppColors.textSecond,
                fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.remove_circle,
              color: count > 0 ? AppColors.danger : AppColors.textSecond,
              size: 28,
            ),
            onPressed: count > 0 ? onDecrease : null,
          ),
        ]),
        const SizedBox(width: 4),
      ]),
    );
  }
}
