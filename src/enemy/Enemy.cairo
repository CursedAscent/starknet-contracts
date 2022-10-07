%lang starknet

from src.utils.constants import TokenRef
from src.enemy.constants import ActionList

// Enemy entity
struct Enemy {
    // Entity data:
    damage_coef: felt,
    protection_points_coef: felt,
    armor_coef: felt,
    max_health_points: felt,
    health_points: felt,
    protection_points: felt,
    active_effects: felt,

    // Enemy-specific data:
    enemy_ref: TokenRef,
    id: felt,
    action_list_len: felt,
    action_list: ActionList,
    next_action_id: felt,  // index in action_list, -1 if action is hidden
    previous_action: felt,  // packed_action with updated value for front
}
