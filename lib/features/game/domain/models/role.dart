enum RoleType { villager, werewolf, seer, witch, hunter, doctor, thief, fox, cupid, elder, idiot, wild_child, white_wolf, big_bad_wolf, crow, scapegoat, devoted_maid, black_wolf }
enum RoleTeam { village, wolves, neutral, solo }

class Role {
  final RoleType type;
  final RoleTeam team;

  const Role({required this.type, required this.team});

  static const Map<RoleType, Role> all = {
    RoleType.villager:      Role(type: RoleType.villager,      team: RoleTeam.village),
    RoleType.werewolf:      Role(type: RoleType.werewolf,      team: RoleTeam.wolves),
    RoleType.seer:          Role(type: RoleType.seer,          team: RoleTeam.village),
    RoleType.witch:         Role(type: RoleType.witch,         team: RoleTeam.village),
    RoleType.hunter:        Role(type: RoleType.hunter,        team: RoleTeam.village),
    RoleType.doctor:        Role(type: RoleType.doctor,        team: RoleTeam.village),
    RoleType.thief:         Role(type: RoleType.thief,         team: RoleTeam.neutral),
    RoleType.fox:           Role(type: RoleType.fox,           team: RoleTeam.village),
    RoleType.cupid:         Role(type: RoleType.cupid,         team: RoleTeam.village),
    RoleType.elder:         Role(type: RoleType.elder,         team: RoleTeam.village),
    RoleType.idiot:         Role(type: RoleType.idiot,         team: RoleTeam.village),
    RoleType.wild_child:    Role(type: RoleType.wild_child,    team: RoleTeam.neutral),
    RoleType.white_wolf:    Role(type: RoleType.white_wolf,    team: RoleTeam.solo),
    RoleType.big_bad_wolf:  Role(type: RoleType.big_bad_wolf, team: RoleTeam.wolves),
    RoleType.crow:          Role(type: RoleType.crow,          team: RoleTeam.village),
    RoleType.scapegoat:     Role(type: RoleType.scapegoat,     team: RoleTeam.village),
    RoleType.devoted_maid:  Role(type: RoleType.devoted_maid,  team: RoleTeam.village),
    RoleType.black_wolf:    Role(type: RoleType.black_wolf,    team: RoleTeam.wolves),
  };

  static Role fromString(String s) =>
      all[RoleType.values.firstWhere((e) => e.name == s, orElse: () => RoleType.villager)]!;

  String get assetKey {
    switch (type) {
      case RoleType.werewolf:      return 'werewolf';
      case RoleType.seer:          return 'seer';
      case RoleType.witch:         return 'witch';
      case RoleType.hunter:        return 'hunter';
      case RoleType.villager:      return 'villager';
      // Others use programmatic cards
      default:                     return 'custom';
    }
  }

  String nameKey() => 'role_${type.name}';
  String descKey() => 'role_${type.name}_desc';

  String toJson() => type.name;
  factory Role.fromJson(String s) => fromString(s);
}
