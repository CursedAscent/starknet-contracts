%lang starknet

from src.scene.SceneCollection.interfaces.ISceneCollection import ISceneCollection

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
func test_name{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local contract_address;
    %{ ids.contract_address = context.contract_address %}

    let (name) = ISceneCollection.name(contract_address=contract_address);

    assert name = 'Cursed Scenes';

    return ();
}

@external
func test_symbol{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local contract_address;
    %{ ids.contract_address = context.contract_address %}

    let (symbol) = ISceneCollection.symbol(contract_address=contract_address);

    assert symbol = 'CURSED';

    return ();
}

@external
func test_total_supply{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local contract_address;
    %{ ids.contract_address = context.contract_address %}

    let (total_supply) = ISceneCollection.total_supply(contract_address=contract_address);

    assert total_supply = 0x84;

    return ();
}

@external
func test_tokenURI{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local contract_address;
    %{ ids.contract_address = context.contract_address %}

    let (token_uri_len, token_uri) = ISceneCollection.tokenURI(
        contract_address=contract_address, tokenId=0
    );

    local test_success;
    %{
        full_uri = "ipfs://bafybeidlakszlrz2xfjca5r4sfj2watoove4vz3oism5ufmc7dxzlxfywm/0.json"
        raw_bytes = []
        i = 0

        while i < ids.token_uri_len:
            raw_bytes.append(memory[ids.token_uri + i])
            i += 1

        decoded_string = bytearray(raw_bytes).decode("ascii")
        ids.test_success = 1 if full_uri == decoded_string else 0
    %}

    assert test_success = 1;

    return ();
}

@external
func test_get_logic_contract_addr{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local contract_address;
    %{ ids.contract_address = context.contract_address %}

    let (logic_contract_addr) = ISceneCollection.get_logic_contract_addr(
        contract_address=contract_address, token_id=0
    );

    assert logic_contract_addr = 0x42;

    return ();
}
