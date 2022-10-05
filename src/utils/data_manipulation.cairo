// SPDX-License-Identifier: MIT
// Upgraded function unpack_data from loaf (Thx <3)
// https://github.com/BibliothecaForAdventurers/realms-contracts/blob/main/contracts/settling_game/utils/general.cairo

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.pow import pow
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.math import unsigned_div_rem, split_felt, assert_le
from starkware.cairo.common.math_cmp import is_le_felt
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.memset import memset

// @notice generic unpack data
// @param data: The packed data
// @param index: starting bit position
// @param mask_size: size of the mask
// @return score: the extracted data
func unpack_data{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(data: felt, index: felt, mask_size: felt) -> (score: felt) {
    alloc_locals;

    // Optional setup: if index >= 128, we use the upper half only
    // This is required because unsigned_div_rem() doesn't like values above 2^128.
    let is_high_bits = is_le_felt(128, index);
    if (is_high_bits == 1) {
        let (high, _) = split_felt(data);
        let (_score) = unpack_data(high, index - 128, mask_size);
        return (score=_score);
    }

    // 1. Create a 8-bit mask at and to the left of the index
    // E.g., 000111100 = 2**2 + 2**3 + 2**4 + 2**5
    // E.g.,  2**(i) + 2**(i+1) + 2**(i+2) + 2**(i+3) = (2**i)(15)
    let (power) = pow(2, index);
    // 1 + 2 + 4 + 8 + 16 + 32 + 64 + 128 + 256 + 512 + 1024 + 2048 = 15
    let mask = mask_size * power;

    // 2. Apply mask using bitwise operation: mask AND data.
    let (masked) = bitwise_and(mask, data);

    // 3. Shift element right by dividing by the order of the mask.
    let (result, _) = unsigned_div_rem(masked, power);

    return (score=result);
}

// @notice modify data in an already set array.
// Under the hood it's just a copy of the inital data.
// generic version of Loaf's cast_state from Adventurer module
// @param index: starting position of the data to be modified
// @param value_len: length of the new data
// @param value: the new data
// @param data_len: the length of the data to modify
// @param data: the data to modify
func insert_data{syscall_ptr: felt*, range_check_ptr}(
    index: felt, value_len: felt, value: felt*, data_len: felt, data: felt*
) -> (new_data: felt*) {
    alloc_locals;

    assert_le(index + value_len, data_len);

    let (a) = alloc();

    memcpy(a, data, index);
    memcpy(a + index, value, value_len);
    memcpy(a + (index + value_len), data + index + value_len, data_len - (index + value_len));

    return (new_data=a);
}

// @notice modify data in an already set array.
// the destination array is passed as an argument.
// generic version of Loaf's cast_state from Adventurer module
// @param index: starting position of the data to be modified
// @param value_len: length of the new data
// @param value: the new data
// @param data_len: the length of the data to modify
// @param data: the data to modify
func implace_insert_data{syscall_ptr: felt*, range_check_ptr}(
    index: felt, value_len: felt, value: felt*, data_len: felt, data: felt*, dest: felt*
) -> (new_data: felt*) {
    alloc_locals;
    local range_check_ptr = range_check_ptr;
    assert_le(index + value_len, data_len);

    memcpy(dest, data, index);
    memcpy(dest + index, value, value_len);
    memcpy(dest + (index + value_len), data + index + value_len, data_len - (index + value_len));

    return (new_data=dest);
}
