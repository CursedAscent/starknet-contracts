%lang starknet

from src.enemy.EnemyCollection.interfaces.IEnemyCollection import IEnemyCollection
from src.utils.constants import TokenRef
from src.enemy.Enemy import Enemy
from src.enemy.EnemyBuilder.library import EnemyBuilderLib

@external
func __setup__() {
    alloc_locals;
    local name = 'Cursed Enemies';
    local symbol = 'CURSE';

    %{
        call_data = []

        call_data.append(ids.name)
        call_data.append(ids.symbol)
        call_data.append(0x1)

        base_uri = "ipfs://bafybeidlakszlrz2xfjca5r4sfj2watoove4vz3oism5ufmc7dxzlxfywm"

        call_data.append(len(base_uri))
        for c in base_uri: call_data.append(ord(c))

        data = [
            (0x1, 0x2, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0xA, 0xB, 0xC, 0xA1)
        ]

        call_data.append(len(data))
        for d in data:
            for e in d:
                call_data.append(e)

        context.contract_address = deploy_contract("./src/enemy/EnemyCollection/EnemyCollection.cairo", call_data).contract_address
    %}

    return ();
}

@external
func test_build_partial_enemy{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local contract_address;
    %{ ids.contract_address = context.contract_address %}

    let enemy_ref = TokenRef(collection_addr=contract_address, token_id=0);
    let (local enemy) = EnemyBuilderLib.build_partial_enemy(enemy_ref);

    assert enemy.id = -1;
    assert enemy.action_list[0] = 0x2;
    assert enemy.armor_coef = 0xA;
    assert enemy.protection_points_coef = 0xB;
    assert enemy.damage_coef = 0xC;
    assert enemy.max_health_points = 0xA1;

    return ();
}
