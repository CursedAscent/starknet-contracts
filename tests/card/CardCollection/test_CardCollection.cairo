%lang starknet

from src.card.CardCollection.interfaces.ICardCollection import ICardCollection

//
// Setup
//

@external
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

        call_data.append(len(data))
        for d in data:
            for e in d:
                call_data.append(e)

        context.card_collection_address = deploy_contract("./src/card/CardCollection/CardCollection.cairo", call_data).contract_address
    %}

    return ();
}

@external
func __setup__() {
    setup_card_collection();

    return ();
}

//
// Tests
//

@external
func test_name{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local contract_address;
    %{ ids.contract_address = context.card_collection_address %}

    let (name) = ICardCollection.name(contract_address=contract_address);

    assert name = 'hello';

    return ();
}

@external
func test_symbol{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local contract_address;
    %{ ids.contract_address = context.card_collection_address %}

    let (symbol) = ICardCollection.symbol(contract_address=contract_address);

    assert symbol = 'HELL';

    return ();
}

@external
func test_total_supply{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local contract_address;
    %{ ids.contract_address = context.card_collection_address %}

    let (total_supply) = ICardCollection.total_supply(contract_address=contract_address);

    assert total_supply = 0x84;

    return ();
}

@external
func test_get_action{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local contract_address;
    %{ ids.contract_address = context.card_collection_address %}

    let (packed_action) = ICardCollection.get_action(contract_address=contract_address, token_id=0);

    assert packed_action = 0x1;

    return ();
}

@external
func test_get_class{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local contract_address;
    %{ ids.contract_address = context.card_collection_address %}

    let (class) = ICardCollection.get_class(contract_address=contract_address, token_id=1);

    assert class = 0x5;

    return ();
}

@external
func test_get_rarity{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local contract_address;
    %{ ids.contract_address = context.card_collection_address %}

    let (rarity) = ICardCollection.get_rarity(contract_address=contract_address, token_id=2);

    assert rarity = 0x9;

    return ();
}

@external
func test_tokenURI{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local contract_address;
    %{ ids.contract_address = context.card_collection_address %}

    let (token_uri_len, token_uri) = ICardCollection.tokenURI(
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
