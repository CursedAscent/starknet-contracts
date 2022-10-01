// SPDX-License-Identifier: MIT
// Custom implementation of the ERC721 standard.
// For the moment there is no concept of token distribution & ownership.
// Inspired by ImmutableX implementation.
// TODO: add ERC165 support for fully implemented standard (IERC721_METADATA)

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc

//
// Storage
//

@storage_var
func ERC721_name() -> (name: felt) {
}

@storage_var
func ERC721_symbol() -> (symbol: felt) {
}

@storage_var
func ERC721_total_supply() -> (total_supply: felt) {
}

@storage_var
func ERC721_base_uri(index: felt) -> (base_uri: felt) {
}

@storage_var
func ERC721_base_uri_len() -> (res: felt) {
}

namespace AERC721 {
    //
    // Constructor
    //

    func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        name: felt, symbol: felt, total_supply: felt, base_uri_len: felt, base_uri: felt*
    ) {
        ERC721_name.write(name);
        ERC721_symbol.write(symbol);
        ERC721_total_supply.write(total_supply);
        set_base_uri(base_uri_len, base_uri);

        return ();
    }

    //
    // Getters
    //

    func total_supply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        total_supply: felt
    ) {
        return ERC721_total_supply.read();
    }

    func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
        return ERC721_name.read();
    }

    func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        symbol: felt
    ) {
        return ERC721_symbol.read();
    }

    func get_base_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        base_uri_len: felt, base_uri: felt*
    ) {
        alloc_locals;
        let (local base_uri: felt*) = alloc();
        let (local base_uri_len: felt) = ERC721_base_uri_len.read();
        _get_base_uri(base_uri_len, base_uri);

        return (base_uri_len, base_uri);
    }

    //
    // Setters
    //

    func set_base_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        base_uri_len: felt, base_uri: felt*
    ) {
        _set_base_uri(base_uri_len, base_uri);
        ERC721_base_uri_len.write(base_uri_len);

        return ();
    }

    //
    // Internals
    //

    func _get_base_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        base_uri_len: felt, base_uri: felt*
    ) {
        if (base_uri_len == 0) {
            return ();
        }
        let (base) = ERC721_base_uri.read(base_uri_len);
        assert [base_uri] = base;
        _get_base_uri(base_uri_len - 1, base_uri + 1);

        return ();
    }

    func _set_base_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        base_uri_len: felt, base_uri: felt*
    ) {
        if (base_uri_len == 0) {
            return ();
        }

        ERC721_base_uri.write(base_uri_len, [base_uri]);
        _set_base_uri(base_uri_len - 1, base_uri + 1);

        return ();
    }
}
