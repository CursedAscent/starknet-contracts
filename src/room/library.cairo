// Room Library
// Library with helper methods to work with rooms in a game mode

%lang starknet

from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math_cmp import is_le

from src.room.constants import PackedRooms
from src.utils.data_manipulation import unpack_data

namespace RoomLib {
    // Rooms are tightly packed in a felt.
    //   NB: for the moment, there is no 'edges' implementation.
    //   All rooms of a floor is connected to all next floor's rooms.
    //
    // Here is the data layout:
    //   floor_nb_size = 1 byte (up to 255 floors) (stored in the last byte)
    //
    //   floor_size = 2 (bits)
    //   nb_of_room_per_floor = 4 (0b00 = 1 room, 0b11 = 4 room)
    //   nb_of_floor_in_felt = (31 bytes - floor_nb_size) * 8 bits / floor_size = 120
    //
    // (to be implemented:)
    //   nb_of_edges_per_room = nb_of_room_per_floor
    //   edges_size = 4 (bits)
    //   -> 0b0001 means connected to the next floor's first room.
    //   -> 0b1100 means connected to the next floor's third and forth rooms.
    //   -> 0b0000 means connected to no next floor's room.
    //   nb_of_room_connections_in_felt = 31 bytes * 8bits / edges_size = 62
    //
    // Combining these informations, the current limits of our library is (using 2 felts):
    //   max 4 room per floor
    //   max 62 floor

    const ROOM_BIT_SIZE = 2;
    const ROOM_MASK = 3;  // max value for ROOM_BIT_SIZE bits
    const FLOOR_NB_BIT_SIZE = 8;
    const FLOOR_NB_MASK = 255;  // max value for FLOOR_NB_BIT_SIZE bits
    const MAX_FLOOR = 120;

    func can_access_next_floor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(rooms: PackedRooms, current_floor: felt, target_room: felt) -> felt {
        alloc_locals;

        // get total room numbers in current and next floor
        let total_rooms_current = _calculate_total_rooms_floor(rooms, current_floor - 1, 0);
        let nb_rooms_next = _get_room_nb_in_floor(rooms, current_floor);
        let total_rooms_next = total_rooms_current + nb_rooms_next;

        // check if target_room is in the next floor
        let is_not_in_current_floor = is_le(total_rooms_current + 1, target_room);
        let is_not_above_next_floor = is_le(target_room, total_rooms_next);

        let result = is_not_above_next_floor + is_not_in_current_floor;
        if (result == 2) {
            return TRUE;
        } else {
            return FALSE;
        }
    }

    func get_floor_nb{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(rooms: PackedRooms) -> felt {
        let (res) = unpack_data(rooms, MAX_FLOOR * ROOM_BIT_SIZE, FLOOR_NB_MASK);

        return res;
    }

    func get_room_nb{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(rooms: PackedRooms) -> felt {
        let floor_nb = get_floor_nb(rooms);
        let room_nb = _calculate_total_rooms_floor(rooms, floor_nb, 0);

        return room_nb;
    }

    //
    // Internals
    //

    func _get_room_nb_in_floor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(rooms: PackedRooms, current_floor: felt) -> felt {
        let (res) = unpack_data(rooms, current_floor * ROOM_BIT_SIZE, ROOM_MASK);

        return res + 1;
    }

    func _calculate_total_rooms_floor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(rooms: PackedRooms, current_floor: felt, acc: felt) -> felt {
        if (current_floor == -1) {
            return (acc);
        }

        // retrieve the current floor's nb of rooms
        let room_nb = _get_room_nb_in_floor(rooms, current_floor);

        // loop over previous floors
        return _calculate_total_rooms_floor(rooms, current_floor - 1, acc + room_nb);
    }
}
