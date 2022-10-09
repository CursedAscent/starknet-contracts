%lang starknet

from src.room.library import RoomLib
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin

@external
func test_can_access_next_floor{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    }() {
    alloc_locals;

    local rooms: felt;

    %{
        ids.rooms = (1 << 6) & (3 << 4) & (2 << 2) & (1)
    %}

    let can_access = RoomLib.can_access_next_floor(rooms, 0, 0, 1);

    assert can_access = 1;

    return ();
}