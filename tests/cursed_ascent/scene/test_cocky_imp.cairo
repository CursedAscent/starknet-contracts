%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.registers import get_fp_and_pc

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
}() -> felt {
    alloc_locals;
    let (__fp__, _) = get_fp_and_pc();
    local contract_address;

    // EnemyCollection
    let enemy_collection_addr = deploy_EnemyCollection();

    // cocky_imp
    local enemy_list_len = 1;
    local coll_addr = enemy_collection_addr;
    local token_id = 0;

    %{
        call_data = []
        call_data.append(ids.enemy_list_len)
        call_data.append(ids.coll_addr)
        call_data.append(ids.token_id)

        context.cocky_imp_address = deploy_contract("./src/cursed_ascent/scene/cocky_imp.cairo", call_data).contract_address
        contract_address = context.cocky_imp_address
    %}

    return contract_address;
}

@external
func test_name() {
    return ();
}
