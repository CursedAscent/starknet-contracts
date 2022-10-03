%lang starknet

from src.scene.SceneCollection.interfaces.ISceneCollection import ISceneCollection
from src.utils.constants import TokenRef
from src.scene.Scene import Scene
from src.scene.SceneBuilder.library import SceneBuilderLib

@external
func __setup__() {
    alloc_locals;
    local name = 'Cursed Scenes';
    local symbol = 'CURSED';

    %{
        call_data = []

        call_data.append(ids.name)
        call_data.append(ids.symbol)
        call_data.append(0x84)

        base_uri = "ipfs://bafybeidlakszlrz2xfjca5r4sfj2watoove4vz3oism5ufmc7dxzlxfywm"

        call_data.append(len(base_uri))
        for c in base_uri: call_data.append(ord(c))

        data = [
            0x42,
            0x84
        ]

        call_data.append(len(data))
        for d in data:
            call_data.append(d)

        context.contract_address = deploy_contract("./src/scene/SceneCollection/SceneCollection.cairo", call_data).contract_address
    %}

    return ();
}

@external
func test_build_partial_scene{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local contract_address;
    %{ ids.contract_address = context.contract_address %}

    let scene_ref = TokenRef(collection_addr=contract_address, token_id=0);
    let (local scene) = SceneBuilderLib.build_partial_scene(scene_ref);

    assert scene.logic_contract_addr = 0x42;

    return ();
}
