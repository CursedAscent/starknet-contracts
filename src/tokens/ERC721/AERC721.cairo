// SPDX-License-Identifier: MIT
// Custom implementation of the ERC721 standard.
// For the moment there is no concept of token distribution & ownership.
// Inspired by ImmutableX implementation.
// TODO: add ERC165 support for fully implemented standard (IERC721_METADATA)

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from lib.cairopen_contracts.src.cairopen.string.ASCII import StringCodec
from starkware.cairo.common.math import assert_lt_felt
from lib.cairopen_contracts.src.cairopen.string.libs.conversion import (
    conversion_felt_to_string,
    conversion_ss_to_string,
    conversion_ss_arr_to_string,
)
from lib.cairopen_contracts.src.cairopen.string.libs.manipulation import (
    manipulation_concat,
    manipulation_append_char,
)
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

    func tokenURI{
        bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(token_id: felt) -> (token_uri_len: felt, token_uri: felt*) {
        alloc_locals;
        local cs = StringCodec.CHAR_SIZE;
        local clcm = StringCodec.LAST_CHAR_MASK;
        local offset = StringCodec.NUMERICAL_OFFSET;

        // ensure token with token_id exists
        let (local total_supply) = AERC721.total_supply();
        with_attr error_message("AERC721: URI query for nonexistent token") {
            assert_lt_felt(token_id, total_supply);
        }

        // get base URI
        let (base_uri_len, base_uri) = AERC721.get_base_uri();
        let (base_uri_string) = conversion_ss_arr_to_string{
            codec_char_size=cs, codec_last_char_mask=clcm
        }(base_uri_len, base_uri);

        // append '/' to base URI
        let (uri_string) = manipulation_append_char(base_uri_string, '/');
        let (extension_string) = conversion_ss_to_string{codec_char_size=cs, codec_last_char_mask=clcm}(
            '.json'
        );

        // append token ID to base URI
        let (token_id_string) = conversion_felt_to_string{codec_numerical_offset=offset}(token_id);
        let (token_uri) = manipulation_concat(uri_string, token_id_string);

        // append file extension
        let (uri) = manipulation_concat(token_uri, extension_string);

        return (uri.len, uri.data);
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
