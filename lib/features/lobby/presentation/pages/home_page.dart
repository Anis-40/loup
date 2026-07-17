import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glowing_button.dart';
import '../../../../core/utils/updater.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // نتحقق من التحديثات بمجرد فتح الشاشة الرئيسية
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdater.checkForUpdates(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0D2B), Color(0xFF1A0A2E), Color(0xFF0D0D1A)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Wolf Icon
                  Container(
                    width: 170, height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withOpacity(0.5),
                            blurRadius: 40, spreadRadius: 5),
                      ],
                      border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 3),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/wolf_icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.nightlight_round, size: 70, color: AppColors.gold),
                      ),
                    ),
                  ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 28),

                  Text(
                    'app_title'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.w900,
                      color: AppColors.text,
                      shadows: [Shadow(color: AppColors.primary, blurRadius: 20)],
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 6),
                  const Text(
                    'الغرفة المحلية بدون إنترنت 🐺',
                    style: TextStyle(color: AppColors.textSecond, fontSize: 14),
                  ),

                  const SizedBox(height: 50),

                  GlowingButton(
                    label: 'create_room'.tr(),
                    icon: Icons.add_circle_outline,
                    color: AppColors.primary,
                    onTap: () => context.push('/create-room'),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),

                  const SizedBox(height: 18),

                  GlowingButton(
                    label: 'join_room'.tr(),
                    icon: Icons.login_rounded,
                    color: AppColors.accent,
                    onTap: () => context.push('/join-room'),
                  ).animate().fadeIn(delay: 750.ms).slideY(begin: 0.3),

                  const SizedBox(height: 18),

                  GlowingButton(
                    label: 'توزيع أدوار (بدون إنترنت)',
                    icon: Icons.people_outline,
                    color: AppColors.card,
                    onTap: () => context.push('/offline-distributor'),
                  ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.3),

                  const SizedBox(height: 18),

                  GlowingButton(
                    label: 'اختيار بطاقات (Deck Mode)',
                    icon: Icons.grid_view_rounded,
                    color: AppColors.primary.withOpacity(0.5),
                    onTap: () => context.push('/offline-deck'),
                  ).animate().fadeIn(delay: 1050.ms).slideY(begin: 0.3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
