%lang starknet

from src.utils.constants import TokenRef

// Enemy entity
struct Enemy {
    enemy_ref: TokenRef,
    id: fels,
    action_list_len: felt
    action_list: (felt, felt, felt, felt, felt, felt, felt, felt),
    next_action: felt, // 0x0 if action is hidden
    armor_coef: felt,
    protection_points_coef: felt,
    damage_coef: felt,
    health_points: felt,
    active_effects_len: felt,
    active_effects: felt*
}