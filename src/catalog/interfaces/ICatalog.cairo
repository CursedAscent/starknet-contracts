// Interface of the Catalog contract.
// It's a contrat that list all available collections for a given game mode.
// A "game mode" is represented by a unique identifier (as a felt)
// and is managed by it's owner (the contract that declare the game mode).

%lang starknet

from src.utils.constants import TokenRef

@contract_interface
namespace ICatalog {
    // @notice Get all available tokens in a given game mode.
    // @param game_mode: the id of the game mode.
    // @return : the list of all available tokens.
    func get_tokens(game_mode: felt) -> (token_list_len: felt, token_list: TokenRef*) {
    }

    // @notice Get all collections associated to a game mode.
    // @param game_mode: the id of the game mode.
    // @return collections: a list of the collections' addresses.
    func get_collections(game_mode: felt) -> (collections_list_len: felt, collections_list: felt*) {
    }

    // @notice Add a collection to a given game mode.
    // If the game mode doesn't exist yet, the caller became the owner of that game_mode.
    // If the collection is already there,
    // @param game_mode: the id of the game mode.
    // @param collection_addr: the address of the collection.
    func add_collection(game_mode: felt, collection_addr: felt) {
    }
}
