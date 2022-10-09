func setup_card_collection() {
    alloc_locals;
    local name = 'hello';
    local symbol = 'HELL';

    %{
        call_data = []

        call_data.append(ids.name)
        call_data.append(ids.symbol)
        call_data.append(0x84)

        base_uri = "ipfs://bafybeidlakszlrz2xfjca5r4sfj2watoove4vz3oism5ufmc7dxzlxfywm"

        call_data.append(len(base_uri))
        for c in base_uri: call_data.append(ord(c))

        data = [
            (0x1, 0x2, 0x3),
            (0x4, 0x5, 0x6),
            (0x7, 0x8, 0x9)
        ]

        call_data.append(13*4)

        for i in range(13):
            call_data.append(0x1)
            call_data.append(0x1)
            call_data.append(0x1)
        
        for i in range(13):
            call_data.append(0x1)
            call_data.append(0x2)
            call_data.append(0x1)
        
        for i in range(13):
            call_data.append(0x1)
            call_data.append(0x3)
            call_data.append(0x1)

        for i in range(13):
            call_data.append(0x1)
            call_data.append(0x4)
            call_data.append(0x1)

        context.card_collection_address = deploy_contract("./src/card/CardCollection/CardCollection.cairo", call_data).contract_address
    %}

    return ();
}