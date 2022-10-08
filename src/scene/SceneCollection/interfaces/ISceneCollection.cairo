// Interface for SceneCollection contract
// It's an NFT where each token is a scene pointing to a ISceneLogic implementation contract
// Each token is a couple of on-chain and off-chain data usable by any game.
// For the moment there is no concept of token distribution & ownership.

%lang starknet

from src.utils.constants import TokenRef

@contract_interface
namespace ISceneCollection {
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

    // @notice Get the address of the ISceneLogic implementation contract tied to this NFT
    // @param token_id: the id of the scene in the collection
    // @return logic_contract_addr: the address of the ISceneLogic implementation contract
    func get_logic_contract_addr(token_id: felt) -> (logic_contract_addr: felt) {
    }

    // @notice Get the type of the scene tied to this NFT
    // @param token_id: the id of the scene in the collection
    // @return scene_type: the type of the scene (SceneTypeEnum)
    func get_scene_type(token_id: felt) -> (scene_type: felt) {
    }

    // @notice Get the list of event ids from the logic contract
    // @param token_id: the id of the scene in the collection
    // @return event_id_list_len, event_id_list: the length of the event id list, the list of event ids
    func get_event_id_list(token_id: felt) -> (event_id_list_len: felt, event_id_list: felt*) {
    }

    // @notice Get the list of enemy ids declared by the logic contract
    // @param token_id: the id of the scene in the collection
    // @return enemy_id_list_len, enemy_id_list: the length of the enemy id list, the list of enemy ids
    func get_enemy_id_list(token_id: felt) -> (enemy_id_list_len: felt, enemy_id_list: TokenRef*) {
    }
}
