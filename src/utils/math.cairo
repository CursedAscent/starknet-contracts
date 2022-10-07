%lang starknet

from starkware.cairo.common.math import assert_le, assert_lt, unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le

// @notice limit a value to a min and a max.
// @param min: minimum value (returned if value < min)
// @param value: the value to limit
// @param max: maximum value (returned if value > max)
// @return the limited value.
func clamp{range_check_ptr}(min: felt, value: felt, max: felt) -> felt {
    assert_le(min, max);

    let is_min = is_le(value, min);
    let is_not_max = is_le(value, max);
    if (is_min == 1) {
        return (min);
    }
    if (is_not_max == 1) {
        return (value);
    }
    return (max);
}

// @notice Multiply a value by factor, then divide it by divider (reminder is discarded).
// @param value: initial value
// @param factor: multiplier to value
// @param divider: divider
// @return the resulting value
func mul_then_div{range_check_ptr}(value: felt, factor: felt, divider: felt) -> felt {
    let (res, _) = unsigned_div_rem(value * factor, divider);
    return (res);
}
