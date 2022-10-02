%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin

from src.tokens.ERC721.AERC721 import AERC721
from src.card.constants import CardData

//
// Storage
//

@storage_var
func action(token_id: felt) -> (packed_action: felt) {
}

@storage_var
func class(token_id: felt) -> (class: felt) {
}

@storage_var
func rarity(token_id: felt) -> (rarity: felt) {
}

//
// Constructor
//

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt,
    symbol: felt,
    total_supply: felt,
    base_uri_len: felt,
    base_uri: felt*,
    data_len: felt,
    data: CardData*,
) {
    AERC721.initializer(name, symbol, total_supply, base_uri_len, base_uri);
    _initializer(data_len - 1, data + (data_len - 1) * CardData.SIZE);

    return ();
}

func _initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    data_len: felt, data: CardData*
) {
    if (data_len == -1) {
        return ();
    }

    let cardData = [data];
    action.write(data_len, cardData.action);
    class.write(data_len, cardData.class);
    rarity.write(data_len, cardData.rarity);

    return _initializer(data_len - 1, data - CardData.SIZE);
}

//
// Getters
//

// @notice Return the name of the token
// @return name: the name of the token
@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
    return AERC721.name();
}

// @notice Return the symbol of the token
// @return symbol: the symbol of the token
@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (symbol: felt) {
    return AERC721.symbol();
}

// @notice Return the number of tokens in the collection
// @return total_supply: the number of tokens in the collection
@view
func total_supply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    total_supply: felt
) {
    return AERC721.total_supply();
}

// @notice Return the formatted URI of the given token
// @param token_id: the id of the token
// @return : a string containing the URI of the token and its length
@view
func tokenURI{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(token_id: felt) -> (token_uri_len: felt, token_uri: felt*) {
    return AERC721.tokenURI(token_id=token_id);
}

// @notice Get the action of the card
// @param token_id: the id of the card in the collection
// @return packed_action: a packed, on-chain description of the card action
@view
func get_action{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: felt
) -> (packed_action: felt) {
    return action.read(token_id);
}

// @notice Get the class associated with the given card
// @param token_id: the id of the card in the collection
// @return class: the identifier of the class (as a AdventurerClassEnum)
@view
func get_class{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(token_id: felt) -> (
    class: felt
) {
    return class.read(token_id);
}

// @notice Get the rarity of the card
// @param token_id: the id of the card in the collection
// @return rarity: the rarity value (as a RarityTypeEnum)
@view
func get_rarity{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: felt
) -> (rarity: felt) {
    return rarity.read(token_id);
}
