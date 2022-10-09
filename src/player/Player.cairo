%lang starknet

from src.utils.constants import TokenRef

// Player entity built from an Adventurer entity and its loot
struct Player {
    // Entity data:
    damage_coef: felt,
    protection_points_coef: felt,
    armor_coef: felt,
    max_health_points: felt,
    health_points: felt,
    protection_points: felt,
    active_effects: felt,

    // Player-specific data:
    adventurer_ref: TokenRef,
    class: felt,  // AdventurerClassEnum
    luck: felt,  // NOT IMPLEMENTED
}
