// Interface for all the scene logic implementation contracts
// It is a contract that is linked to a scene NFT and implements all its logic to be called by a game mode

%lang starknet

from src.scene.SceneState import SceneState
from src.session.Session import Session
from src.player.Player import Player
from src.card.Card import Card

from src.utils.constants import TokenRef

@contract_interface
namespace ISceneLogic {
    //
    // Logic:
    //

    // @notice Initialize the scene and return a SceneState struct containing its context
    // @return scene_state: the scene's context
    func initialize_scene() -> (scene_state: SceneState) {
    }

    // @notice Computes the next action from a player
    // @param scene_state: the scene's context
    // @param seed: seed to initialize PRNG
    // @param player_len: UNUSED (pointer to single value)
    // @param player: a pointer to the player's instance
    // @param card_picked: the card picked by the player
    // @param target_ids_len: the length of target_ids array
    // @param target_ids: array containing all the targetted enemies computed by the game mode
    // @return scene_state: the scene's context
    func next_step(
        scene_state: SceneState,
        seed: felt,
        player_len: felt,
        player: Player*,
        card_picked: Card,
        target_ids_len: felt,
        target_ids: felt*,
    ) -> (scene_state: SceneState) {
    }

    //
    // Getters:
    //

    // @notice Get the list of event ids declared in the contract
    // @return event_id_list_len, event_id_list: the length of the event id list, the list of event ids
    func get_event_id_list() -> (event_id_list_len: felt, event_id_list: felt*) {
    }

    // @notice Get the list of enemy ids declared in the contract
    // @return enemy_id_list_len, enemy_id_list: the length of the enemy id list, the list of enemy ids
    func get_enemy_id_list() -> (enemy_id_list_len: felt, enemy_id_list: TokenRef*) {
    }
}
