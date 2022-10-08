%lang starknet

from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from src.utils.xoshiro128.library import Xoshiro128_ss

@external
func test_xhosiro_next{
    syscall_ptr: felt*, bitwise_ptr: BitwiseBuiltin*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    local seed = 0xDEADBEEF;

    let (local state) = Xoshiro128_ss.init(seed);
    let (local new_state, rnd) = Xoshiro128_ss.next(state);

    assert rnd = 12232861487000265107;

    return ();
}
