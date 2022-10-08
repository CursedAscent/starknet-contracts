%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.registers import get_fp_and_pc

from src.scene.SceneLogic.interfaces.ISceneLogic import ISceneLogic
from src.player.Player import Player
from src.utils.constants import TokenRef

from tests.enemy.EnemyCollection.test_EnemyCollection import deploy_EnemyCollection

@external
func __setup__{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    deploy_cocky_imp();
    return ();
}

//
// Setup
//

func deploy_cocky_imp{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;
    let (__fp__, _) = get_fp_and_pc();
    local contract_address;

    // EnemyCollection
    deploy_EnemyCollection();

    // cocky_imp
    local enemy_list_len = 1;
    local token_id = 0;

    %{
        call_data = []
        call_data.append(ids.enemy_list_len)
        call_data.append(context.EnemyCollection_address)
        call_data.append(ids.token_id)

        context.cocky_imp_address = deploy_contract("./src/cursed_ascent/scene/cocky_imp.cairo", call_data).contract_address
    %}

    return ();
}

@external
func test_initialize_scene{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    deploy_cocky_imp();

    let empty_player = Player(
        damage_coef=0,
        protection_points_coef=0,
        armor_coef=0,
        max_health_points=0,
        health_points=0,
        protection_points=0,
        active_effects=0,
        player_ref=TokenRef(0, 0),
        class=0,
        luck=0,
    );

    local contract_address;
    %{ ids.contract_address = context.cocky_imp_address %}

    let (local scene_state) = ISceneLogic.initialize_scene(
        contract_address=contract_address, player=empty_player
    );

    assert scene_state.enemies_len = 1; 
    assert scene_state.enemies[0].damage_coef = 100;
    assert scene_state.current_event = 0x1;
    assert scene_state.is_finished = 0;

    return ();
}
