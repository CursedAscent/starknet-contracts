%lang starknet

from src.scene.constants import SceneData

func setup_scene_collection(data_len: felt, data: SceneData*) {
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
