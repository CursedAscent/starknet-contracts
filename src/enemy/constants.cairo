%lang starknet

from src.action.constants import PackedAction

using ActionList = (PackedAction, PackedAction, PackedAction, PackedAction, PackedAction, PackedAction, PackedAction, PackedAction);

// On-chain data (used by constructor)
struct EnemyData {
    action_list_len: felt,
    action_list: ActionList,
    armor_coef: felt,
    protection_points_coef: felt,
    damage_coef: felt,
    max_health_points: felt,
}
