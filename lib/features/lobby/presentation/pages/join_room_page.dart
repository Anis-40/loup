import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../game/data/network/discovery_service.dart';
import '../../../game/domain/models/player.dart';
import '../../../game/domain/providers/game_provider.dart';

class JoinRoomPage extends ConsumerStatefulWidget {
  const JoinRoomPage({super.key});
  @override
  ConsumerState<JoinRoomPage> createState() => _State();
}

class _State extends ConsumerState<JoinRoomPage> {
  final _nameCtrl = TextEditingController();
  final _ipCtrl   = TextEditingController();
  final List<DiscoveredRoom> _rooms = [];
  bool _loading   = false;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _startSearch();
  }

  void _startSearch() {
    setState(() { _searching = true; _rooms.clear(); });
    ref.read(gameStateProvider.notifier).discoveryStream.listen(
      (room) {
        if (mounted && !_rooms.any((r) => r.hostIp == room.hostIp)) {
          setState(() => _rooms.add(room));
        }
      },
      onDone: () { if (mounted) setState(() => _searching = false); },
      onError: (_) => setState(() => _searching = false),
    );
  }

  Future<void> _join(String ip) async {
    if (_nameCtrl.text.trim().isEmpty) {
      _snack('أدخل اسمك أولاً'); return;
    }
    final cleanIp = ip.trim();
    if (cleanIp.isEmpty) {
      _snack('أدخل عنوان IP'); return;
    }

    setState(() => _loading = true);
    final player = Player(name: _nameCtrl.text.trim());
    ref.read(currentPlayerProvider.notifier).state = player;

    try {
      final ok = await ref.read(gameStateProvider.notifier)
          .joinRoom(cleanIp, player)
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      if (ok) {
        ref.read(gameStateProvider.notifier).stopDiscovery();
        context.go('/lobby');
      } else {
        setState(() => _loading = false);
        _snack('❌ تعذّر الاتصال. تأكد من صحة العنوان وأن الغرفة مفتوحة');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _snack('❌ انتهت مهلة الاتصال. تأكد من العنوان والشبكة');
      }
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
    .showSnackBar(SnackBar(content: Text(msg),
      backgroundColor: AppColors.danger,
      duration: const Duration(seconds: 3)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('join_room'.tr())),
      body: Column(children: [

        // ─── الاسم ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: AppColors.text, fontSize: 18),
            decoration: InputDecoration(
              labelText: 'enter_name'.tr(),
              prefixIcon: const Icon(Icons.person, color: AppColors.primary),
            ),
          ),
        ),

        // ─── إدخال IP يدوياً ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ipCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.text, fontSize: 16, letterSpacing: 1.5),
                decoration: const InputDecoration(
                  labelText: 'أدخل IP يدوياً',
                  prefixIcon: Icon(Icons.lan_outlined, color: AppColors.accent),
                  hintText: '192.168.x.x',
                  hintStyle: TextStyle(color: AppColors.textSecond, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _loading ? null : () => _join(_ipCtrl.text),
              child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.login_rounded, color: Colors.white),
            ),
          ]),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(children: [
            Expanded(child: Divider(color: AppColors.card, thickness: 1.5)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('أو اختر من الغرف المكتشفة تلقائياً',
                style: TextStyle(color: AppColors.textSecond, fontSize: 12)),
            ),
            Expanded(child: Divider(color: AppColors.card, thickness: 1.5)),
          ]),
        ),

        // ─── قائمة الغرف ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            const Icon(Icons.search, color: AppColors.gold, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('rooms_found'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold,
                  color: AppColors.gold, fontSize: 16))),
            if (_searching)
              const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)),
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.gold),
              onPressed: _startSearch,
            ),
          ]),
        ),

        Expanded(
          child: _rooms.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.wifi_find, color: AppColors.textSecond.withOpacity(0.3), size: 60),
                const SizedBox(height: 16),
                Text(_searching ? '🔍 البحث عن غرف...' : 'لم تُعثر على غرف',
                  style: const TextStyle(color: AppColors.textSecond),
                  textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text('يمكنك إدخال IP المدير يدوياً بالأعلى',
                  style: TextStyle(color: AppColors.textSecond, fontSize: 11),
                  textAlign: TextAlign.center),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _rooms.length,
                itemBuilder: (ctx, i) {
                  final room = _rooms[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 4,
                    shadowColor: AppColors.primary.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle),
                        child: const Icon(Icons.meeting_room, color: AppColors.primary)),
                      title: Text(room.roomName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: Text(room.hostIp,
                        style: const TextStyle(color: AppColors.textSecond, fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          color: AppColors.accent, size: 18),
                      onTap: _loading ? null : () {
                        _ipCtrl.text = room.hostIp;
                        _join(room.hostIp);
                      },
                    ),
                  ).animate().fadeIn(delay: (i * 100).ms).slideX(begin: 0.1);
                }),
        ),
      ]),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ipCtrl.dispose();
    super.dispose();
  }
}
