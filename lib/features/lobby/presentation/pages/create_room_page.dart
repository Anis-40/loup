import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glowing_button.dart';
import '../../../game/domain/models/player.dart';
import '../../../game/domain/providers/game_provider.dart';

class CreateRoomPage extends ConsumerStatefulWidget {
  const CreateRoomPage({super.key});
  @override
  ConsumerState<CreateRoomPage> createState() => _State();
}

class _State extends ConsumerState<CreateRoomPage> {
  final _nameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _roomCtrl = TextEditingController(text: 'غرفة الذئاب');
  bool _loading = false;
  bool _obscure = true;

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _snack('أدخل اسمك'); return;
    }
    if (_passCtrl.text != AppConstants.adminPassword) {
      _snack('wrong_password'.tr()); return;
    }
    setState(() => _loading = true);
    final host = Player(name: _nameCtrl.text.trim(), isHost: true);
    ref.read(isHostProvider.notifier).state = true;
    ref.read(currentPlayerProvider.notifier).state = host;
    try {
      await ref.read(gameStateProvider.notifier).createRoom(_roomCtrl.text.trim(), host);
    } catch(e) {
      setState(() => _loading = false);
      _snack('لا يمكن إنشاء خادم اللعبة على المتصفح! المتصفح لا يدعم هذا. يجب تشغيله على الهاتف لتكون أنت المدير.');
      return;
    }
    if (mounted) context.go('/lobby');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('create_room'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 20),
          _field(_nameCtrl, 'enter_name'.tr(), Icons.person),
          const SizedBox(height: 16),
          _field(_roomCtrl, 'room_name'.tr(), Icons.meeting_room),
          const SizedBox(height: 16),
          TextField(
            controller: _passCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'password'.tr(),
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 40),
          _loading
            ? const CircularProgressIndicator(color: AppColors.primary)
            : GlowingButton(
                label: 'create_room'.tr(),
                icon: Icons.add,
                onTap: _create,
              ),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon) =>
    TextField(controller: c, decoration: InputDecoration(
      labelText: label, prefixIcon: Icon(icon)));

  @override
  void dispose() {
    _nameCtrl.dispose(); _passCtrl.dispose(); _roomCtrl.dispose();
    super.dispose();
  }
}
