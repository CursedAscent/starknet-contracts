%lang starknet

from src.card.CardCollection.interfaces.ICardCollection import ICardCollection
from tests.card.CardCollection.utils import setup_card_collection

//
// Setup
//

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

    let (class) = ICardCollection.get_class(contract_address=contract_address, token_id=14);

    assert class = 0x2;

    return ();
}

@external
func test_get_rarity{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local contract_address;
    %{ ids.contract_address = context.card_collection_address %}

    let (rarity) = ICardCollection.get_rarity(contract_address=contract_address, token_id=27);

    assert rarity = 0x1;

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
