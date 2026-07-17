import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../models/role.dart';
import '../../data/network/tcp_server.dart';
import '../../data/network/tcp_client.dart';
import '../../data/network/discovery_service.dart';
import '../../../../core/constants/app_constants.dart';
import 'role_config_provider.dart';

// ─── Session Info ─────────────────────────────────────────────────────────────
final isHostProvider        = StateProvider<bool>((ref) => false);
final currentPlayerProvider = StateProvider<Player?>((ref) => null);

// ─── Game State ───────────────────────────────────────────────────────────────
final gameStateProvider =
    StateNotifierProvider<GameNotifier, GameState>((ref) => GameNotifier(ref));

class GameNotifier extends StateNotifier<GameState> {
  final Ref _ref;
  LocalGameServer? _server;
  GameClient?      _client;
  final DiscoveryService _discovery = DiscoveryService();

  GameNotifier(this._ref) : super(const GameState());

  // ─── HOST: Create Room ──────────────────────────────────────────────────────
  Future<void> createRoom(String roomName, Player host) async {
    await _server?.stop();
    _server = null;

    final ip = await DiscoveryService.getLocalIp();
    state = state.copyWith(roomName: roomName, hostIp: ip, players: [host]);

    _server = LocalGameServer();
    _server!.onMessage = _handleClientMessage;
    await _server!.start(roomName);

    if (ip != '127.0.0.1') {
      await _discovery.startBroadcasting(roomName);
    }
  }

  void _handleClientMessage(Socket socket, Map<String, dynamic> data) {
    final type = data['type'] as String?;
    if (type == 'JOIN') {
      final player = Player.fromJson(data['player']);
      _server!.setPlayerIdForSocket(socket, player.id);
      _addPlayer(player);
      _broadcastState();
    } else if (type == 'VOTE') {
      _recordVote(data['voterId'], data['targetId']);
    } else if (type == 'NIGHT_ACTION') {
      _handleNightAction(data);
    }
  }

  // ─── PLAYER: Join Room ──────────────────────────────────────────────────────
  Future<bool> joinRoom(String ip, Player player) async {
    _client?.dispose();
    _client = GameClient(
      onMessage: (data) {
        if (data['type'] == 'STATE') {
          final newState = GameState.fromJson(data['state']);
          final me = newState.players.firstWhere(
            (p) => p.id == player.id, orElse: () => player);
          final myRole = data['myRole'] != null
              ? Role.fromJson(data['myRole']) : me.role;
          if (myRole != null) {
            _ref.read(currentPlayerProvider.notifier).state =
                me.copyWith(role: myRole);
          }
          state = newState;
        }
      },
      onDisconnected: () {},
    );
    final ok = await _client!.connect(ip);
    if (ok) {
      _client!.send({'type': 'JOIN', 'player': player.toJson()});
    }
    return ok;
  }

  // ─── HOST: Start Game ───────────────────────────────────────────────────────
  void startGame() {
    if (state.players.length < AppConstants.minPlayers) return;
    final players = _assignRoles(List.from(state.players));
    state = state.copyWith(players: players, phase: GamePhase.roleReveal);

    for (final p in players) {
      _server!.sendToPlayer(p.id, {
        'type': 'STATE',
        'state': state.toJson(),
        'myRole': p.role?.toJson(),
      });
    }
    _broadcastState();
  }

  List<Player> _assignRoles(List<Player> players) {
    final roleList = _ref.read(roleConfigProvider.notifier).flatList;
    roleList.shuffle();
    players.shuffle();

    for (int i = 0; i < players.length; i++) {
      final rt = i < roleList.length ? roleList[i] : RoleType.villager;
      players[i] = players[i].copyWith(role: Role.all[rt]);
    }
    return players;
  }

  // ─── Phase Control ───────────────────────────────────────────────────────────
  void startMayorElection() {
    state = state.copyWith(phase: GamePhase.mayorElection, currentVotes: {});
    _broadcastState();
  }

  void resolveMayorElection() {
    final votes = state.currentVotes;
    if (votes.isEmpty) return;
    final tally = <String, int>{};
    for (final t in votes.values) tally[t] = (tally[t] ?? 0) + 1;
    final winnerId = tally.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final players = state.players.map((p) =>
        p.id == winnerId ? p.copyWith(isMayor: true) : p.copyWith(isMayor: false)).toList();
    state = state.copyWith(players: players, mayorId: winnerId, phase: GamePhase.day);
    _broadcastState();
  }

  void goToNight() {
    state = state.copyWith(
      phase: GamePhase.night,
      currentVotes: {},
      nightVictimId: null,
      protectedPlayerId: null,
      seerRevealId: null,
    );
    _broadcastState();
  }

  void goToDay() {
    var players = List<Player>.from(state.players);
    String? deadId;
    if (state.nightVictimId != null && state.nightVictimId != state.protectedPlayerId) {
      deadId = state.nightVictimId;
    }
    if (deadId != null) {
      players = players.map((p) =>
        p.id == deadId ? p.copyWith(isAlive: false, roleRevealed: true) : p).toList();
    }
    state = state.copyWith(phase: GamePhase.day, players: players);
    _checkWinCondition();
    _checkMayorDeath(deadId);
    _broadcastState();
  }

  void _checkMayorDeath(String? deadId) {
    if (deadId == state.mayorId) state = state.copyWith(mayorId: null);
  }

  void startVoting() {
    state = state.copyWith(phase: GamePhase.voting, currentVotes: {});
    _broadcastState();
  }

  void resolveVotes() {
    final votes = state.currentVotes;
    if (votes.isEmpty) { goToNight(); return; }

    final tally = <String, double>{};
    for (final entry in votes.entries) {
      final isMayor = state.players.any((p) => p.id == entry.key && p.isMayor);
      tally[entry.value] = (tally[entry.value] ?? 0) + (isMayor ? 2.0 : 1.0);
    }
    final eliminated = tally.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    var players = state.players.map((p) =>
        p.id == eliminated ? p.copyWith(isAlive: false, roleRevealed: true) : p).toList();
    state = state.copyWith(players: players, round: state.round + 1);
    _checkWinCondition();
    _checkMayorDeath(eliminated);
    if (state.phase != GamePhase.gameOver) goToNight();
    _broadcastState();
  }

  void eliminatePlayer(String playerId) {
    final players = state.players.map((p) =>
        p.id == playerId ? p.copyWith(isAlive: false, roleRevealed: true) : p).toList();
    state = state.copyWith(players: players);
    _checkWinCondition();
    _checkMayorDeath(playerId);
    _broadcastState();
  }

  void kickPlayer(String playerId) {
    _server?.kickPlayer(playerId);
    _removePlayer(playerId);
    _broadcastState();
  }

  void _handleNightAction(Map<String, dynamic> data) {
    final action = data['action'] as String;
    if (action == 'WOLF_KILL') {
      state = state.copyWith(nightVictimId: data['targetId']);
    } else if (action == 'DOCTOR_SAVE') {
      state = state.copyWith(protectedPlayerId: data['targetId']);
    } else if (action == 'SEER_REVEAL') {
      state = state.copyWith(seerRevealId: data['targetId']);
      final seer = state.players.firstWhere(
        (p) => p.role?.type == RoleType.seer, orElse: () => state.players.first);
      final target = state.players.firstWhere(
        (p) => p.id == data['targetId'], orElse: () => state.players.first);
      _server!.sendToPlayer(seer.id, {
        'type': 'SEER_RESULT',
        'targetName': target.name,
        'isWolf': target.role?.team == RoleTeam.wolves,
      });
    }
  }

  void sendVote(String voterId, String targetId) {
    if (_ref.read(isHostProvider)) {
      _recordVote(voterId, targetId);
      _broadcastState();
    } else {
      _client?.send({'type': 'VOTE', 'voterId': voterId, 'targetId': targetId});
    }
  }

  void sendNightAction(String action, String targetId, String actorId) {
    if (_ref.read(isHostProvider)) {
      _handleNightAction({'action': action, 'targetId': targetId, 'actorId': actorId});
    } else {
      _client?.send({'type': 'NIGHT_ACTION', 'action': action,
          'targetId': targetId, 'actorId': actorId});
    }
  }

  void _addPlayer(Player player) {
    if (!state.players.any((p) => p.id == player.id)) {
      state = state.copyWith(players: [...state.players, player]);
    }
  }

  void _removePlayer(String id) {
    state = state.copyWith(players: state.players.where((p) => p.id != id).toList());
  }

  void _recordVote(String voterId, String targetId) {
    final votes = Map<String, String>.from(state.currentVotes);
    votes[voterId] = targetId;
    state = state.copyWith(currentVotes: votes);
    _broadcastState();
  }

  void _checkWinCondition() {
    if (state.villageWins) {
      state = state.copyWith(phase: GamePhase.gameOver, gameWinner: 'village');
    } else if (state.wolvesWin) {
      state = state.copyWith(phase: GamePhase.gameOver, gameWinner: 'wolves');
    }
  }

  void _broadcastState() {
    _server?.broadcast({'type': 'STATE', 'state': state.toJson()});
  }

  Stream<DiscoveredRoom> get discoveryStream => _discovery.listenForRooms();
  void stopDiscovery() => _discovery.stopListening();

  @override
  void dispose() {
    _server?.stop();
    _client?.dispose();
    _discovery.stopBroadcasting();
    _discovery.stopListening();
    super.dispose();
  }
}
