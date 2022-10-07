// This scene is the implementation of the Cocky Imp scenario

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin

from src.scene.SceneLogic.ASceneLogic import ASceneLogic
from src.session.Session import Session
from src.scene.SceneState import SceneState
from src.enemy.Enemy import Enemy
from src.enemy.EnemyCollection.interfaces.IEnemyCollection import IEnemyCollection
from src.enemy.EnemyBuilder.library import EnemyBuilderLib
from src.player.Player import Player
from src.card.Card import Card
from src.utils.constants import TokenRef
from src.action.library import ActionLib

//
// Constants
//

const IMP_INDEX = 0;

// indices are event ids (todo: cant do tuple as const)
// const EVENT_LIST = (
//     'IN_COMBAT',
//     'IN_INTRO'
//     );

//
// Constructor
//

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    enemy_list_len: felt, enemy_list: TokenRef*
) {
    tempvar event_list: felt*;
    ASceneLogic.initializer(enemy_list_len, enemy_list, 0, event_list);

    return ();
}

//
// Logic
//

// @notice Initialize the scene and return a SceneState struct containing its context
// @return scene_state: the scene's context
@view
func initialize_scene{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    session_state: Session
) -> (scene_state: SceneState) {
    alloc_locals;
    local empty_enemy: Enemy;

    let (local enemy_id_list_len, local enemy_id_list) = get_enemy_id_list();

    let (imp_ref) = ASceneLogic.get_enemy(IMP_INDEX);
    let (imp) = _build_imp(0);

    imp.next_action_id = 0;

    return (
        scene_state=SceneState(1, (imp, empty_enemy, empty_enemy, empty_enemy, empty_enemy, empty_enemy, empty_enemy, empty_enemy), 1, 0),
    );
}

// @notice Computes the next action from a player
// @param scene_state: the scene's context
// @param seed: seed to initialize PRNG
// @param player_len: UNUSED (pointer to single value)
// @param player: a pointer to the player's instance
// @param player_action: the action of the card picked by the player (packed)
// @param target_ids_len: the length of target_ids array
// @param target_ids: array containing all the targetted enemies computed by the game mode
// @return scene_state: the scene's context
@view
func next_step{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(
    scene_state: SceneState,
    seed: felt,
    player: Player,
    player_action: felt,
    target_ids_len: felt,
    target_ids: felt*,
) -> (scene_state: SceneState, player: Player, seed: felt) {
    let (scene_state, player, seed) = ActionLib.play_action(scene_state, player, 0, 0, -1, seed);
    return (scene_state, player, seed);
}

//
// Getters
//

func get_event_id_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    event_id_list_len: felt, event_id_list: felt*
) {
    return ASceneLogic.get_event_id_list();
}

func get_enemy_id_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    enemy_id_list_len: felt, enemy_id_list: TokenRef*
) {
    return ASceneLogic.get_enemy_id_list();
}

//
// Internals
//

func _build_imp{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(id: felt) -> (
    enemy: Enemy
) {
    let (imp_ref) = ASceneLogic.get_enemy(IMP_INDEX);
    let (imp) = EnemyBuilderLib.build_partial_enemy(imp_ref);
    imp.id = id;

    return (enemy=imp);
}
