// Interface for all the scene logic implementation contracts
// It is a contract that is linked to a scene NFT and implements all its logic to be called by a game mode

%lang starknet

from src.scene.SceneState import SceneState
from src.player.Player import Player
from src.card.Card import Card
from src.action.constants import PackedActionHistory, PackedAction

from src.utils.constants import TokenRef

@contract_interface
namespace ISceneLogic {
    //
    // Logic:
    //

    // @notice Initialize the scene and return a SceneState struct containing its context
    // @return scene_state: the scene's context
    func initialize_scene(player: Player) -> (scene_state: SceneState) {
    }

    // @notice Computes the next action from a player and the scene actions
    // @param scene_state: the scene's context
    // @param seed: seed to initialize PRNG
    // @param player: a pointer to the player's instance
    // @param player_action: the action of the card picked by the player (packed)
    // @param target_id: the id of the target selected by player (if relevant)
    // @return the computed new scene state, player state, action history & seed
    func next_step(
        scene_state: SceneState,
        seed: felt,
        player: Player,
        player_action: PackedAction,
        target_id: felt,
    ) -> (
        scene_state: SceneState,
        player: Player,
        history_len: felt,
        history: PackedActionHistory*,
        seed: felt,
    ) {
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
