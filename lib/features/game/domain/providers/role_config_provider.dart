import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/role.dart';

// إعدادات الأدوار الافتراضية
final defaultRoleConfig = {
  RoleType.werewolf:   2,
  RoleType.seer:       1,
  RoleType.witch:      1,
  RoleType.hunter:     1,
  RoleType.villager:   4,
  RoleType.doctor:     0,
  RoleType.thief:      0,
  RoleType.fox:        0,
  RoleType.cupid:      0,
  RoleType.elder:      0,
  RoleType.idiot:      0,
  RoleType.wild_child:  0,
  RoleType.white_wolf:  0,
  RoleType.big_bad_wolf: 0,
  RoleType.crow:         0,
  RoleType.scapegoat:    0,
  RoleType.devoted_maid: 0,
  RoleType.black_wolf:   0,
};

final roleConfigProvider =
    StateNotifierProvider<RoleConfigNotifier, Map<RoleType, int>>(
  (ref) => RoleConfigNotifier(),
);

class RoleConfigNotifier extends StateNotifier<Map<RoleType, int>> {
  RoleConfigNotifier() : super(Map.from(defaultRoleConfig));

  void increase(RoleType rt) {
    state = {...state, rt: (state[rt] ?? 0) + 1};
  }

  void decrease(RoleType rt) {
    final cur = state[rt] ?? 0;
    if (cur > 0) state = {...state, rt: cur - 1};
  }

  void reset() => state = Map.from(defaultRoleConfig);

  List<RoleType> get flatList {
    final list = <RoleType>[];
    for (final entry in state.entries) {
      for (int i = 0; i < entry.value; i++) {
        list.add(entry.key);
      }
    }
    return list;
  }
}
