%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.registers import get_fp_and_pc

from src.enemy.EnemyCollection.interfaces.IEnemyCollection import IEnemyCollection
from src.enemy.constants import EnemyData, ActionList

from src.action.constants import Action, PackedAction, AttributeEnum
from src.action.library import ActionLib

@external
func __setup__{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    deploy_EnemyCollection();
    return ();
}

//
// Setup
//

func deploy_EnemyCollection{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() -> felt {
    alloc_locals;
    let (__fp__, _) = get_fp_and_pc();

    local contract_address;
    local name = 'COLL1';
    local symbol = 'C1';
    local total_supply = 1;
    local base_uri_len = 1;
    // local base_uri: felt* = cast(0, felt*);
    local data_len = 1;
    let enemy_action_list = _get_actions_list();
    let (
        local a, local b, local c, local d, local e, local f, local g, local h
    ) = _get_actions_list();
    local data: EnemyData* = new EnemyData(
        3,
        enemy_action_list,
        100,
        100,
        100,
        30,
        );

    %{
        call_data = []
        call_data.append(ids.name)
        call_data.append(ids.symbol)
        call_data.append(ids.total_supply)
        call_data.append(ids.base_uri_len)
        call_data.append(ord('a'))

        # EnemyData array:
        call_data.append(ids.data_len)
        call_data.append(3)
        call_data.append(ids.a)
        call_data.append(ids.b)
        call_data.append(ids.c)
        call_data.append(ids.d)
        call_data.append(ids.e)
        call_data.append(ids.f)
        call_data.append(ids.g)
        call_data.append(ids.h)
        call_data.append(100)
        call_data.append(100)
        call_data.append(100)
        call_data.append(30)
        context.EnemyCollection_address = deploy_contract("./src/enemy/EnemyCollection/EnemyCollection.cairo", call_data).contract_address
        contract_address = context.EnemyCollection_address
    %}

    return contract_address;
}

//
// Internals
//

func _get_actions_list{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() -> ActionList {
    alloc_locals;
    local action1: Action = Action(AttributeEnum.DIRECT_HIT, 10, 0, 0, 0, 0, AttributeEnum.PLAYER_TARGET, 1, 0, 0, 0, 0);
    local action2: Action = Action(AttributeEnum.PROTECTION_POINT, 20, 0, 0, 0, 0, AttributeEnum.SELF_TARGET, 1, 0, 0, 0, 0);
    local action3: Action = Action(AttributeEnum.ATTACK_BONUS, 5, 0, 0, 0, 0, AttributeEnum.SELF_TARGET, 1, 0, 0, 0, 0);

    let (pack1) = ActionLib.pack_action(action1);
    let (pack2) = ActionLib.pack_action(action2);
    let (pack3) = ActionLib.pack_action(action3);

    let action_list: ActionList = (
        pack1,
        pack2,
        pack3,
        0,
        0,
        0,
        0,
        0,
        );

    return action_list;
}
