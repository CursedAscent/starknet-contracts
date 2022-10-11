%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin

from tests.card.CardCollection.utils import setup_card_collection

from src.card.CardCollection.interfaces.ICardCollection import ICardCollection
from src.action.library import ActionLib
from src.action.constants import Action
from src.player.constants import AdventurerClassEnum

//
// Setup
//

@external
func __setup__() {
    return ();
}

//
// Tests
//

@external
func test_name{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;
    setup_card_collection();

    local contract_address;
    %{ ids.contract_address = context.card_collection_address %}

    let (name) = ICardCollection.name(contract_address=contract_address);

    assert name = 'Cursed';

    return ();
}

@external
func test_symbol{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;
    setup_card_collection();

    local contract_address;
    %{ ids.contract_address = context.card_collection_address %}

    let (symbol) = ICardCollection.symbol(contract_address=contract_address);

    assert symbol = 'CURSE';

    return ();
}

@external
func test_total_supply{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;
    setup_card_collection();

    local contract_address;
    %{ ids.contract_address = context.card_collection_address %}

    let (total_supply) = ICardCollection.total_supply(contract_address=contract_address);

    assert total_supply = 52;

    return ();
}

@external
func test_get_action{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;
    setup_card_collection();

    local contract_address;
    %{ ids.contract_address = context.card_collection_address %}

    let (packed_action) = ICardCollection.get_action(contract_address=contract_address, token_id=0);

    local action1: Action = Action('DH', 10, 0, 0, 0, 0, 'TS', 1, 0, 0, 0, 0);
    let (local pa1) = ActionLib.pack_action(action1);
    assert packed_action = pa1;

    return ();
}

@external
func test_get_class{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;
    setup_card_collection();

    local contract_address;
    %{ ids.contract_address = context.card_collection_address %}

    let (class) = ICardCollection.get_class(contract_address=contract_address, token_id=14);

    assert class = AdventurerClassEnum.HUNTER;

    return ();
}

@external
func test_get_rarity{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;
    setup_card_collection();

    local contract_address;
    %{ ids.contract_address = context.card_collection_address %}

    let (rarity) = ICardCollection.get_rarity(contract_address=contract_address, token_id=27);

    assert rarity = 0x1;

    return ();
}

@external
func test_tokenURI{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;
    setup_card_collection();

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
