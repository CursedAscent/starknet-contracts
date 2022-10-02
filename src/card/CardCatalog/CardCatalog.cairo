%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero

from src.utils.constants import TokenRef
from src.catalog.ACatalog import ACatalog
from src.card.CardCollection.interfaces.ICardCollection import ICardCollection

// @notice Get all available tokens in a given game mode.
// @param game_mode: the id of the game mode.
// @return : the list of all available tokens.
@view
func get_tokens{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    game_mode: felt
) -> (token_list_len: felt, token_list: TokenRef*) {
    return ACatalog.get_tokens(game_mode);
}

// @notice Get all collections associated to a game mode.
// @param game_mode: the id of the game mode.
// @return collections: a list of the collections' addresses.
@view
func get_collections{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    game_mode: felt
) -> (collections_list_len: felt, collections_list: felt*) {
    return ACatalog.get_collections(game_mode);
}

// @notice Add a collection to a given game mode.
// If the game mode doesn't exist yet, the caller became the owner of that game_mode.
// If the collection is already there,
// @param game_mode: the id of the game mode.
// @param collection_addr: the address of the collection.
@external
func add_collection{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
    game_mode: felt, collection_addr: felt
) {
    // check if the collection is a CardCollection
    // TODO: find a better check to see if get_class() did not fail
    let (class) = ICardCollection.get_class(collection_addr, 0);
    assert_not_zero(class);

    return ACatalog.add_collection(game_mode, collection_addr);
}
