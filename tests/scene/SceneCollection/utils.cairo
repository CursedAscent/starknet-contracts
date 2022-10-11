%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc

from tests.cursedascent.scene.utils import deploy_cocky_imp

from src.scene.constants import SceneData

func deploy_scene_collection(data_len: felt, data: SceneData*) {
    alloc_locals;
    local name = 'Cursed Scenes';
    local symbol = 'CURSED';
    local data_len = data_len * SceneData.SIZE;
    local _data: felt* = cast(data, felt*);

    %{
        call_data = []

        call_data.append(ids.name)
        call_data.append(ids.symbol)
        call_data.append(ids.data_len)

        base_uri = "ipfs://bafybeidlakszlrz2xfjca5r4sfj2watoove4vz3oism5ufmc7dxzlxfywm"

        call_data.append(len(base_uri))
        for c in base_uri: call_data.append(ord(c))

        call_data.append(ids.data_len)
        for i in range(ids.data_len):
            call_data.append(memory[ids._data + i])

        context.scene_collection_address = deploy_contract("./src/scene/SceneCollection/SceneCollection.cairo", call_data).contract_address
    %}

    return ();
}

func setup_scene_collection{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    deploy_cocky_imp();
    let (local data: felt*) = alloc();
    %{ memory[ids.data] = context.cocky_imp_address %}
    deploy_scene_collection(1, cast(data, SceneData*));

    return ();
}
