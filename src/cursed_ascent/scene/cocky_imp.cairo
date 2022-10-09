// This scene is the implementation of the Cocky Imp scenario

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import unsigned_div_rem

from starkware.cairo.common.registers import get_fp_and_pc
from src.scene.SceneLogic.ASceneLogic import ASceneLogic
from src.scene.constants import SceneTypeEnum
from src.scene.SceneState import SceneState, EnemyList
from src.scene.SceneLogic.constants import SceneLogicEvents
from src.session.Session import Session
from src.enemy.Enemy import Enemy
from src.enemy.EnemyCollection.interfaces.IEnemyCollection import IEnemyCollection
from src.enemy.EnemyBuilder.library import EnemyBuilderLib
from src.player.Player import Player
from src.card.Card import Card
from src.utils.constants import TokenRef
from src.utils.data_manipulation import insert_data
from src.action.library import ActionLib
from src.action.constants import PackedActionHistory, PackedAction

//
// Constants
//

const IMP_INDEX = 0;

namespace EVENT_LIST {
    const NO_EVENT = SceneLogicEvents.NO_EVENT;
    const INTRO = SceneLogicEvents.INTRO;
    const OUTRO = SceneLogicEvents.OUTRO;
    const PLAYER_DEAD = SceneLogicEvents.PLAYER_DEAD;
}

//
// Constructor
//

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    enemy_list_len: felt, enemy_list: TokenRef*
) {
    ASceneLogic.initializer(enemy_list_len, enemy_list);

    return ();
}

//
// Logic
//

// @notice Initialize the scene and return a SceneState struct containing its context
// @return scene_state: the scene's context
@view
func initialize_scene{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    player: Player
) -> (scene_state: SceneState) {
    alloc_locals;

    let (local enemy_id_list_len, local enemy_id_list) = get_enemy_id_list();

    let (imp) = _build_imp(0);

    let EMPTY_ENEMY = Enemy(
        damage_coef=0,
        protection_points_coef=0,
        armor_coef=0,
        max_health_points=0,
        health_points=0,
        protection_points=0,
        active_effects=0,
        enemy_ref=TokenRef(0, 0),
        id=-1,
        action_list_len=0,
        action_list=(0, 0, 0, 0, 0, 0, 0, 0),
        next_action_id=0,
    );

    return (
        scene_state=SceneState(1, (imp, EMPTY_ENEMY, EMPTY_ENEMY, EMPTY_ENEMY, EMPTY_ENEMY, EMPTY_ENEMY, EMPTY_ENEMY, EMPTY_ENEMY), EVENT_LIST.INTRO, 0),
    );
}

// @notice Computes the next action from a player and the scene actions
// @param scene_state: the scene's context
// @param seed: seed to initialize PRNG
// @param player: a pointer to the player's instance
// @param player_action: the action of the card picked by the player (packed)
// @param target_id: the id of the target selected by player (if relevant)
// @return the computed new scene state, player state, action history & seed
@view
func next_step{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(
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
    alloc_locals;
    let (__fp__, _) = get_fp_and_pc();
    let imp = scene_state.enemies[0];

    // player action
    let (local scene_state, player, history_len, history, seed) = ActionLib.play_action(
        scene_state, player, player_action, -1, target_id, seed
    );

    if (player.health_points == 0) {
        // player is dead :(
        local scene_state: SceneState = SceneState(scene_state.enemies_len, scene_state.enemies, EVENT_LIST.PLAYER_DEAD, 1);
        return (scene_state, player, history_len, history, seed);
    }

    let imp = scene_state.enemies[0];
    if (imp.health_points == 0) {
        // all enemies are dead ; the scene is finished
        local scene_state: SceneState = SceneState(scene_state.enemies_len, scene_state.enemies, EVENT_LIST.OUTRO, 1);
        return (scene_state, player, history_len, history, seed);
    }

    // todo: active effects for the player

    // imp action
    tempvar imp_action_list: felt* = &(imp.action_list);
    tempvar imp_action: PackedAction = [imp_action_list + imp.next_action_id];
    let imp_target = -1;  // NB: if it should target one enemy ('TS' in target attribute), change this value accordingly
    let (local scene_state, player, history_len, history, seed) = ActionLib.play_action(
        scene_state, player, imp_action, 0, -1, seed
    );

    if (player.health_points == 0) {
        // player is dead :(
        local scene_state: SceneState = SceneState(scene_state.enemies_len, scene_state.enemies, EVENT_LIST.PLAYER_DEAD, 1);
        return (scene_state, player, history_len, history, seed);
    }

    let imp = scene_state.enemies[0];
    if (imp.health_points == 0) {
        // all enemies are dead ; the scene is finished
        local scene_state: SceneState = SceneState(scene_state.enemies_len, scene_state.enemies, EVENT_LIST.OUTRO, 1);
        return (scene_state, player, history_len, history, seed);
    }

    // todo: active effects for the enemies

    // set imp next action
    let (_, next_action_id) = unsigned_div_rem(imp.next_action_id + 1, 3);  // modulo 3 (it's a loop over the 3 available actions)
    let imp = _update_enemy_next_action(next_action_id, imp);
    let scene_state = _update_scene_state_enemy_list(imp, scene_state, EVENT_LIST.NO_EVENT);

    return (scene_state, player, history_len, history, seed);
}

//
// Getters
//

// @notice Get the type of the scene tied to this NFT
// @param token_id: the id of the scene in the collection
// @return scene_type: the type of the scene (SceneTypeEnum)
@view
func get_scene_type(token_id: felt) -> (scene_type: felt) {
    return (scene_type=SceneTypeEnum.FIGHT);
}

func get_event_id_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    event_id_list_len: felt, event_id_list: felt*
) {
    // todo: not from ASceneLogic anymore
    return ASceneLogic.get_event_id_list();
}

func get_enemy_id_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    enemy_id_list_len: felt, enemy_id_list: TokenRef*
) {
    // todo: not from ASceneLogic anymore
    return ASceneLogic.get_enemy_id_list();
}

//
// Internals
//

func _build_imp{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(id: felt) -> (
    enemy: Enemy
) {
    alloc_locals;
    let (imp_ref) = ASceneLogic.get_enemy(IMP_INDEX);
    let (partial_imp) = EnemyBuilderLib.build_partial_enemy(imp_ref);

    local imp: Enemy = Enemy(
        partial_imp.damage_coef,
        partial_imp.protection_points_coef,
        partial_imp.armor_coef,
        partial_imp.max_health_points,
        partial_imp.max_health_points,
        0,
        0,
        imp_ref,
        id,
        partial_imp.action_list_len,
        partial_imp.action_list,
        0,
        );

    return (enemy=imp);
}

// as much enemy parameters as there are in the scene
func _update_scene_state_enemy_list{syscall_ptr: felt*, range_check_ptr}(
    imp: Enemy, scene_state: SceneState, new_event: felt
) -> SceneState {
    alloc_locals;
    let (__fp__, _) = get_fp_and_pc();

    // update scene_state.enemy_list with imp at index 0
    let (enemy_list: EnemyList*) = insert_data(
        0, Enemy.SIZE, &imp, Enemy.SIZE * 8, &scene_state.enemies
    );

    let list: EnemyList = [enemy_list];
    let result: SceneState = SceneState(
        1,
        (list[0], list[1], list[2], list[3], list[4], list[5], list[6], list[7]),
        new_event,
        scene_state.is_finished,
    );

    return result;
}

func _update_enemy_next_action(next_action_id: felt, enemy: Enemy) -> Enemy {
    alloc_locals;
    local result: Enemy = Enemy(
        enemy.damage_coef,
        enemy.protection_points_coef,
        enemy.armor_coef,
        enemy.max_health_points,
        enemy.health_points,
        enemy.protection_points,
        enemy.active_effects,
        enemy.enemy_ref,
        enemy.id,
        enemy.action_list_len,
        enemy.action_list,
        next_action_id,
        );

    return result;
}
