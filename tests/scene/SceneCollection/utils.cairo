func setup_scene_collection() {
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

        context.scene_collection_address = deploy_contract("./src/scene/SceneCollection/SceneCollection.cairo", call_data).contract_address
    %}

    return ();
}