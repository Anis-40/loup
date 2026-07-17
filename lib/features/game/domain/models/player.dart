import 'dart:math';
import 'role.dart';

class Player {
  final String id;
  final String name;
  final bool isHost;
  final bool isMayor;
  Role? role;
  bool isAlive;
  bool roleRevealed;

  Player({
    String? id,
    required this.name,
    this.isHost = false,
    this.isMayor = false,
    this.role,
    this.isAlive = true,
    this.roleRevealed = false,
  }) : id = id ?? _genId();

  static String _genId() =>
      DateTime.now().millisecondsSinceEpoch.toString() +
      Random().nextInt(9999).toString();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isHost': isHost,
    'isMayor': isMayor,
    'isAlive': isAlive,
    'role': role?.toJson(),
    'roleRevealed': roleRevealed,
  };

  factory Player.fromJson(Map<String, dynamic> j) => Player(
    id: j['id'],
    name: j['name'],
    isHost: j['isHost'] ?? false,
    isMayor: j['isMayor'] ?? false,
    isAlive: j['isAlive'] ?? true,
    roleRevealed: j['roleRevealed'] ?? false,
    role: j['role'] != null ? Role.fromJson(j['role']) : null,
  );

  Player copyWith({bool? isAlive, Role? role, bool? roleRevealed, bool? isMayor}) => Player(
    id: id,
    name: name,
    isHost: isHost,
    isMayor: isMayor ?? this.isMayor,
    isAlive: isAlive ?? this.isAlive,
    role: role ?? this.role,
    roleRevealed: roleRevealed ?? this.roleRevealed,
  );
}
