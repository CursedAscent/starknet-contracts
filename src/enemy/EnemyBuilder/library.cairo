// Helper functions to create Enemy instances

%lang starknet

from src.enemy.Enemy import Enemy
from src.utils.constants import TokenRef
from src.enemy.EnemyCollection.interfaces.IEnemyCollection import IEnemyCollection

namespace EnemyBuilderLib {
    // @notice Builds a partial Enemy instance from its token data. Its id must be set downstream
    // as well as all the coefficients that need to be adjusted
    // @param card_ref: The card's token ids
    // @return card: The partial card entity
    func build_partial_enemy{syscall_ptr: felt*, range_check_ptr}(enemy_ref: TokenRef) -> (
        enemy: Enemy
    ) {
        alloc_locals;

        let (local action_list_len) = IEnemyCollection.get_action_list_len(
            contract_address=enemy_ref.collection_addr, token_id=enemy_ref.token_id
        );
        let (local action_list) = IEnemyCollection.get_action_list(
            contract_address=enemy_ref.collection_addr, token_id=enemy_ref.token_id
        );
        let (local armor_coef) = IEnemyCollection.get_armor_coef(
            contract_address=enemy_ref.collection_addr, token_id=enemy_ref.token_id
        );
        let (local protection_points_coef) = IEnemyCollection.get_protection_points_coef(
            contract_address=enemy_ref.collection_addr, token_id=enemy_ref.token_id
        );
        let (local damage_coef) = IEnemyCollection.get_damage_coef(
            contract_address=enemy_ref.collection_addr, token_id=enemy_ref.token_id
        );
        let (local health_points) = IEnemyCollection.get_health_points(
            contract_address=enemy_ref.collection_addr, token_id=enemy_ref.token_id
        );

        local enemy: Enemy = Enemy(
            enemy_ref=enemy_ref,
            id=-1,
            action_list_len=action_list_len,
            action_list=action_list,
            next_action=0,
            previous_action=0,
            armor_coef=armor_coef,
            protection_points_coef=protection_points_coef,
            damage_coef=damage_coef,
            health_points=health_points,
            active_effects=0
            );

        return (enemy=enemy);
    }
}
