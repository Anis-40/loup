import 'player.dart';
import 'role.dart';

enum GamePhase { lobby, roleReveal, mayorElection, night, day, voting, gameOver }

class VoteResult {
  final String eliminatedPlayerId;
  final Map<String, String> votes; // voterId -> targetId
  VoteResult({required this.eliminatedPlayerId, required this.votes});
}

class GameState {
  final String roomName;
  final String hostIp;
  final GamePhase phase;
  final List<Player> players;
  final int round;
  final String? nightVictimId;
  final String? protectedPlayerId;
  final String? seerRevealId;
  final String? mayorId;
  final String? gameWinner; // 'wolves' | 'village'
  final Map<String, String> currentVotes; // voterId -> targetId

  const GameState({
    this.roomName = '',
    this.hostIp = '',
    this.phase = GamePhase.lobby,
    this.players = const [],
    this.round = 1,
    this.nightVictimId,
    this.protectedPlayerId,
    this.seerRevealId,
    this.mayorId,
    this.gameWinner,
    this.currentVotes = const {},
  });

  List<Player> get alivePlayers => players.where((p) => p.isAlive).toList();
  List<Player> get wolves => alivePlayers.where(
    (p) => p.role?.team == RoleTeam.wolves).toList();
  List<Player> get villagers => alivePlayers.where(
    (p) => p.role?.team == RoleTeam.village).toList();

  bool get wolvesWin => wolves.length >= villagers.length;
  bool get villageWins => wolves.isEmpty;

  GameState copyWith({
    String? roomName,
    String? hostIp,
    GamePhase? phase,
    List<Player>? players,
    int? round,
    String? nightVictimId,
    String? protectedPlayerId,
    String? seerRevealId,
    String? mayorId,
    String? gameWinner,
    Map<String, String>? currentVotes,
  }) {
    return GameState(
      roomName: roomName ?? this.roomName,
      hostIp: hostIp ?? this.hostIp,
      phase: phase ?? this.phase,
      players: players ?? this.players,
      round: round ?? this.round,
      nightVictimId: nightVictimId ?? this.nightVictimId,
      protectedPlayerId: protectedPlayerId ?? this.protectedPlayerId,
      seerRevealId: seerRevealId ?? this.seerRevealId,
      mayorId: mayorId ?? this.mayorId,
      gameWinner: gameWinner ?? this.gameWinner,
      currentVotes: currentVotes ?? this.currentVotes,
    );
  }

  Map<String, dynamic> toJson() => {
    'roomName': roomName,
    'hostIp': hostIp,
    'phase': phase.name,
    'players': players.map((p) => p.toJson()).toList(),
    'round': round,
    'nightVictimId': nightVictimId,
    'protectedPlayerId': protectedPlayerId,
    'seerRevealId': seerRevealId,
    'mayorId': mayorId,
    'gameWinner': gameWinner,
    'currentVotes': currentVotes,
  };

  factory GameState.fromJson(Map<String, dynamic> j) => GameState(
    roomName: j['roomName'] ?? '',
    hostIp: j['hostIp'] ?? '',
    phase: GamePhase.values.firstWhere(
      (e) => e.name == j['phase'], orElse: () => GamePhase.lobby),
    players: (j['players'] as List? ?? [])
        .map((p) => Player.fromJson(p)).toList(),
    round: j['round'] ?? 1,
    nightVictimId: j['nightVictimId'],
    protectedPlayerId: j['protectedPlayerId'],
    seerRevealId: j['seerRevealId'],
    mayorId: j['mayorId'],
    gameWinner: j['gameWinner'],
    currentVotes: Map<String, String>.from(j['currentVotes'] ?? {}),
  );
}
