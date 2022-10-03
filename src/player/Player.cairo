%lang starknet

from src.utils.constants import TokenRef

// Player entity built from an Adventurer entity and its loot
struct Player {
    player_ref: TokenRef,
    class: felt, // AdventurerClassEnum
    damage_coef: felt,
    protection_points_coef: felt,
    armor: felt,
    luck: felt,  // NOT IMPLEMENTED
    max_health_points: felt,
    health_points: felt,
    active_effects: felt,
}
