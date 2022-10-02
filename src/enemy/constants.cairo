%lang starknet

// On-chain data (used by constructor)
struct EnemyData {
    action_list_len: felt,
    action_list: (felt, felt, felt, felt, felt, felt, felt, felt),
    armor_coef: felt,
    protection_points_coef: felt,
    damage_coef: felt,
    health_points: felt,
}