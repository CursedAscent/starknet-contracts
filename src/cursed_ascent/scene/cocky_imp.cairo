// This scene is the implementation of the Cocky Imp scenario

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from src.scene.SceneLogic.interfaces.ISceneLogic import ISceneLogic
from src.scene.SceneLogic.ASceneLogic import ASceneLogic
from src.utils.constants import TokenRef

//
// Constructor
//
@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    enemy_list_len: felt, enemy_list: TokenRef*, event_list_len: felt, event_list: felt*
) {
    ASceneLogic.initializer(enemy_list_len, enemy_list, event_list_len, event_list);

    return ();
}

//
// Logic
//
// func build_enemies{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
//     session_state: Session
// ) -> {
    
// }

// func initialize_scene{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
//     session_state: Session
// ) -> (scene_state: SceneState) {
//     alloc_locals;

//     let (local enemy_id_list_len, local enemy_id_list) = get_enemy_id_list();

//     build_enemies()

//     return (scene_state=SceneState(
//         enemies_len
//     ));
// }

//
// Getters
//

func get_event_id_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (event_id_list_len: felt, event_id_list: felt*) {
    return ASceneLogic.get_event_id_list();
}

func get_enemy_id_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (enemy_id_list_len: felt, enemy_id_list: TokenRef*) {
    return ASceneLogic.get_enemy_id_list();
}