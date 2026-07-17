import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/lobby/presentation/pages/home_page.dart';
import 'features/lobby/presentation/pages/create_room_page.dart';
import 'features/lobby/presentation/pages/join_room_page.dart';
import 'features/lobby/presentation/pages/lobby_page.dart';
import 'features/lobby/presentation/pages/offline_distributor_page.dart';
import 'features/lobby/presentation/pages/offline_deck_picker_page.dart';
import 'features/game/presentation/pages/game_page.dart';
import 'features/game/presentation/pages/game_over_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await EasyLocalization.ensureInitialized();

  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [Locale('ar')],
        path: 'assets/translations',
        fallbackLocale: const Locale('ar'),
        startLocale: const Locale('ar'), // Arabic as default
        child: const LoupGarouApp(),
      ),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/',         builder: (_, __) => const HomePage()),
    GoRoute(path: '/create-room', builder: (_, __) => const CreateRoomPage()),
    GoRoute(path: '/join-room',   builder: (_, __) => const JoinRoomPage()),
    GoRoute(path: '/offline-distributor', builder: (_, __) => const OfflineDistributorPage()),
    GoRoute(path: '/offline-deck',        builder: (_, __) => const OfflineDeckPickerPage()),
    GoRoute(path: '/lobby',       builder: (_, __) => const LobbyPage()),
    GoRoute(path: '/game',        builder: (_, __) => const GamePage()),
    GoRoute(path: '/game-over',   builder: (_, __) => const GameOverPage()),
  ],
);

class LoupGarouApp extends ConsumerWidget {
  const LoupGarouApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'لعبة المستذئبين',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}
