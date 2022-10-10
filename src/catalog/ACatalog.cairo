// Note: For the moment, collections cannot be removed of a game mode.

%lang starknet

from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_equal
from starkware.cairo.common.alloc import alloc

from src.utils.constants import TokenRef
from src.catalog.library import ACatalogLib

//
// Storage
//

@storage_var
func owner(game_mode: felt) -> (owner: felt) {
}

@storage_var
func catalog_len(game_mode: felt) -> (length: felt) {
}

@storage_var
func catalog(game_mode: felt, index: felt) -> (collection_addr: felt) {
}

namespace ACatalog {
    //
    // Getters
    //

    // @notice Get all available tokens in a given game mode.
    // @param game_mode: the id of the game mode.
    // @return : the list of all available tokens.
    func get_tokens{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
        game_mode: felt
    ) -> (token_list_len: felt, token_list: TokenRef*) {
        alloc_locals;
        let (collections_len, collections) = get_collections(game_mode);
        let (local tokens: TokenRef*) = alloc();

        let (local tokens_len) = _get_tokens(game_mode, collections_len, collections, tokens, 0);

        return (tokens_len, tokens);
    }

    // @notice Get all collections associated to a game mode.
    // @param game_mode: the id of the game mode.
    // @return collections: a list of the collections' addresses.
    func get_collections{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
        game_mode: felt
    ) -> (collections_list_len: felt, collections_list: felt*) {
        alloc_locals;
        let (collections: felt*) = alloc();
        let (local collections_len) = catalog_len.read(game_mode);
        _retrieve_collections_list(game_mode, collections_len, collections + collections_len);

        return (collections_list_len=collections_len, collections_list=collections);
    }

    //
    // Setters
    //

    // @notice Add a collection to a given game mode.
    // If the game mode doesn't exist yet, the caller became the owner of that game_mode.
    // If the collection is already there, this function does nothing.
    // @param game_mode: the id of the game mode.
    // @param collection_addr: the address of the collection.
    func add_collection{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
        game_mode: felt, collection_addr: felt
    ) {
        let (nb_of_collection) = catalog_len.read(game_mode);
        let (caller) = get_caller_address();

        // check if the game_mode has already been registered
        if (nb_of_collection == 0) {
            // register the caller as the owner of this game mode
            owner.write(game_mode, caller);

            tempvar syscall_ptr = syscall_ptr;
            tempvar range_check_ptr = range_check_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
        } else {
            // check that the caller is the owner
            let (_owner) = owner.read(game_mode);
            assert caller = _owner;

            tempvar syscall_ptr = syscall_ptr;
            tempvar range_check_ptr = range_check_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
        }

        // check if the collection is not already registered for this game mode
        let (collection) = _get_collection_by_addr(game_mode, collection_addr);

        if (collection == 0x0) {
            let (collections_len) = catalog_len.read(game_mode);
            catalog.write(game_mode, collections_len, collection_addr);
            catalog_len.write(game_mode, collections_len + 1);

            return ();
        }

        return ();
    }

    //
    // Internals
    //

    // @notice Get the collection address if it is registered for a given game mode.
    // @param game_mode: the id of the game mode.
    // @param collection_addr: the address of the collection in the catalog.
    // @return collection_addr: the address of the collection (or 0x0 if it is not registered yet).
    func _get_collection_by_addr{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
        game_mode: felt, collection_addr: felt
    ) -> (collection_addr: felt) {
        let (collections_len) = catalog_len.read(game_mode);

        return _find_collection_by_addr(game_mode, collection_addr, collections_len);
    }

    // @notice helper internal functions for _get_collection_by_addr.
    // @param game_mode: the id of the game mode.
    // @param collection_addr: the address of the collection in the catalog.
    // @param collections_len: the number of collections to browse.
    // @return collection_addr: the address of the collection (or 0x0 if it is not registered yet).
    func _find_collection_by_addr{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
        game_mode: felt, collection_addr: felt, collections_len: felt
    ) -> (collection_addr: felt) {
        if (collections_len == 0) {
            return (collection_addr=0x0);
        }

        let (addr) = catalog.read(game_mode, collections_len - 1);
        if (addr == collection_addr) {
            return (collection_addr=addr);
        } else {
            return _find_collection_by_addr(game_mode, collection_addr, collections_len - 1);
        }
    }

    func _retrieve_collections_list{
        syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
    }(game_mode: felt, collections_len: felt, collections: felt*) {
        if (collections_len == 0) {
            return ();
        }

        let (addr) = catalog.read(game_mode, collections_len - 1);
        [collections - 1] = addr;

        return _retrieve_collections_list(game_mode, collections_len - 1, collections - 1);
    }

    func _get_tokens{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
        game_mode: felt,
        collection_list_len: felt,
        collection_list: felt*,
        tokens: TokenRef*,
        tokens_accumulator: felt,
    ) -> (token_len: felt) {
        if (collection_list_len == 0) {
            return (token_len=tokens_accumulator);
        }

        let (token_count) = ACatalogLib.get_tokens_from_collection([collection_list], tokens);

        return _get_tokens(
            game_mode,
            collection_list_len - 1,
            collection_list + 1,
            tokens + TokenRef.SIZE * token_count,
            tokens_accumulator + token_count,
        );
    }
}
