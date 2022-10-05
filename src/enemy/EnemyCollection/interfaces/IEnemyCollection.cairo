// Interface for EnemyCollection contract
// It's an NFT where each token is a enemy, with its associated data.
// Each token is a couple of on-chain and off-chain data usable by any game.
// For the moment there is no concept of token distribution & ownership.

%lang starknet

@contract_interface
namespace IEnemyCollection {
    //
    // Getters:
    //

    // @notice Return the name of the token
    // @return name: the name of the token
    func name() -> (name: felt) {
    }

    // @notice Return the symbol of the token
    // @return symbol: the symbol of the token
    func symbol() -> (symbol: felt) {
    }

    // @notice Return the number of tokens in the collection
    // @return total_supply: the number of tokens in the collection
    func total_supply() -> (total_supply: felt) {
    }

    // @notice Return the URI of the given token
    // @param token_id: the id of the token
    // @return token_uri_len, token_uri: the length of the token URI, the token URI
    func tokenURI(tokenId: felt) -> (token_uri_len: felt, token_uri: felt*) {
    }

    // @notice Get the number of actions defined in the action list
    // @param token_id: the id of the enemy in the collection
    // @return action_list_len: the length of the action list
    func get_action_list_len(token_id: felt) -> (action_list_len: felt) {
    }

    // @notice Get the list of all actions an enemy has
    // @param token_id: the id of the enemy in the collection
    // @return action_list: Tuple of 8 actions that can be defined
    func get_action_list(token_id: felt) -> (
        action_list: (felt, felt, felt, felt, felt, felt, felt, felt)
    ) {
    }

    // @notice Get a specific action of an enemy
    // @param token_id: the id of the enemy in the collection
    // @param action_id: the id of the action to retrieve
    // @return action: the retrieved action packed in a felt
    func get_action(token_id: felt, action_id: felt) -> (packed_action: felt) {
    }

    // @notice Get the armor base coefficient of an enemy
    // @param token_id: the id of the enemy in the collection
    // @return armor_coef: the armor base coefficient
    func get_armor_coef(token_id: felt) -> (armor_coef: felt) {
    }

    // @notice Get the protection point coefficient of an enemy
    // @param token_id: the id of the enemy in the collection
    // @return protection_points_coef: the protection points base coefficient
    func get_protection_points_coef(token_id: felt) -> (protection_points_coef: felt) {
    }

    // @notice Get the damage coefficient of an enemy
    // @param token_id: the id of the enemy in the collection
    // @return damage_coef: the damage base coefficient
    func get_damage_coef(token_id: felt) -> (damage_coef: felt) {
    }

    // @notice Get the based health points of an enemy
    // @param token_id: the id of the enemy in the collection
    // @return max_health_points: the enemy's base health points
    func get_max_health_points(token_id: felt) -> (max_health_points: felt) {
    }
}
