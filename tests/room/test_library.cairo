%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bool import FALSE, TRUE

from src.room.library import RoomLib

@external
func test_can_access_next_floor{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local rooms: felt;

    // layout:
    // 4         room7
    // 3 room4   room5   room6
    // 2     room2    room3
    // 1         room1
    %{
        RoomsIn1 = 1
        RoomsIn2 = 2
        RoomsIn3 = 3
        RoomsIn4 = 1
        ids.rooms = (4 << 240) | (RoomsIn4-1 << 6) | (RoomsIn3-1 << 4) | (RoomsIn2-1 << 2) | (RoomsIn1-1)
    %}

    let floor_nb = RoomLib.get_floor_nb(rooms);
    assert floor_nb = 4;

    // floor 0 (in no room)
    // there is no check in library for non existant room
    // let can_access = RoomLib.can_access_next_floor(rooms, 0, -1);
    // assert can_access = FALSE;
    let can_access = RoomLib.can_access_next_floor(rooms, 0, 0);
    assert can_access = FALSE;
    let can_access = RoomLib.can_access_next_floor(rooms, 0, 1);
    assert can_access = TRUE;
    let can_access = RoomLib.can_access_next_floor(rooms, 0, 2);
    assert can_access = FALSE;
    let can_access = RoomLib.can_access_next_floor(rooms, 0, 3);
    assert can_access = FALSE;
    let can_access = RoomLib.can_access_next_floor(rooms, 1, 4);
    assert can_access = FALSE;
    let can_access = RoomLib.can_access_next_floor(rooms, 1, 5);
    assert can_access = FALSE;
    let can_access = RoomLib.can_access_next_floor(rooms, 1, 6);
    assert can_access = FALSE;
    let can_access = RoomLib.can_access_next_floor(rooms, 0, 7);
    assert can_access = FALSE;

    // floor 1
    let can_access = RoomLib.can_access_next_floor(rooms, 1, 1);
    assert can_access = FALSE;
    let can_access = RoomLib.can_access_next_floor(rooms, 1, 2);
    assert can_access = TRUE;
    let can_access = RoomLib.can_access_next_floor(rooms, 1, 3);
    assert can_access = TRUE;
    let can_access = RoomLib.can_access_next_floor(rooms, 1, 4);
    assert can_access = FALSE;
    let can_access = RoomLib.can_access_next_floor(rooms, 1, 5);
    assert can_access = FALSE;
    let can_access = RoomLib.can_access_next_floor(rooms, 1, 6);
    assert can_access = FALSE;
    let can_access = RoomLib.can_access_next_floor(rooms, 1, 7);
    assert can_access = FALSE;

    // floor 2
    let can_access = RoomLib.can_access_next_floor(rooms, 2, 1);
    assert can_access = FALSE;
    let can_access = RoomLib.can_access_next_floor(rooms, 2, 2);
    assert can_access = FALSE;
    let can_access = RoomLib.can_access_next_floor(rooms, 2, 3);
    assert can_access = FALSE;
    let can_access = RoomLib.can_access_next_floor(rooms, 2, 4);
    assert can_access = TRUE;
    let can_access = RoomLib.can_access_next_floor(rooms, 2, 5);
    assert can_access = TRUE;
    let can_access = RoomLib.can_access_next_floor(rooms, 2, 6);
    assert can_access = TRUE;
    let can_access = RoomLib.can_access_next_floor(rooms, 2, 7);
    assert can_access = FALSE;

    // floor 3
    let can_access = RoomLib.can_access_next_floor(rooms, 3, 1);
    assert can_access = FALSE;
    let can_access = RoomLib.can_access_next_floor(rooms, 3, 2);
    assert can_access = FALSE;
    let can_access = RoomLib.can_access_next_floor(rooms, 3, 3);
    assert can_access = FALSE;
    let can_access = RoomLib.can_access_next_floor(rooms, 3, 4);
    assert can_access = FALSE;
    let can_access = RoomLib.can_access_next_floor(rooms, 3, 5);
    assert can_access = FALSE;
    let can_access = RoomLib.can_access_next_floor(rooms, 3, 6);
    assert can_access = FALSE;
    let can_access = RoomLib.can_access_next_floor(rooms, 3, 7);
    assert can_access = TRUE;

    // floor 4
    let can_access = RoomLib.can_access_next_floor(rooms, 4, 1);
    assert can_access = FALSE;
    let can_access = RoomLib.can_access_next_floor(rooms, 4, 2);
    assert can_access = FALSE;
    let can_access = RoomLib.can_access_next_floor(rooms, 4, 3);
    assert can_access = FALSE;
    let can_access = RoomLib.can_access_next_floor(rooms, 4, 4);
    assert can_access = FALSE;
    let can_access = RoomLib.can_access_next_floor(rooms, 4, 5);
    assert can_access = FALSE;
    let can_access = RoomLib.can_access_next_floor(rooms, 4, 6);
    assert can_access = FALSE;
    let can_access = RoomLib.can_access_next_floor(rooms, 4, 7);
    assert can_access = FALSE;

    // there is no check in library for non existant room
    // let can_access = RoomLib.can_access_next_floor(rooms, 4, 8);
    // assert can_access = FALSE;

    return ();
}
