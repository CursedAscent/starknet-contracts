// Library with helper methods to work with rooms in a game mode

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math_cmp import is_le_felt
from src.utils.data_manipulation import unpack_data

namespace RoomLib {
    const ROOM_BYTE_SIZE = 2;

    func calculate_total_rooms_floor{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    }(rooms: felt, current_floor: felt, acc: felt) -> felt {
        alloc_locals;

        if (current_floor == -1) {
            return (acc);
        }

        let (local retrieved) = unpack_data(rooms, current_floor * ROOM_BYTE_SIZE, ROOM_BYTE_SIZE);

        return calculate_total_rooms_floor(rooms, current_floor - 1, acc + retrieved);
    }

    func can_access_next_floor{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
    }(rooms: felt, current_room: felt, current_floor: felt, target_room: felt) -> felt {
        alloc_locals;

        let total_rooms_current = calculate_total_rooms_floor(rooms, current_floor - 1, 0);
        let total_rooms_current_floor = total_rooms_current + current_floor;
        let total_rooms_next = calculate_total_rooms_floor(rooms, current_floor, 0);
        local total_rooms_next_floor = total_rooms_next + current_floor + 1;

        return is_le_felt(total_rooms_current_floor + 1, target_room) + is_le_felt(target_room, total_rooms_next_floor - 1) - 1;
    }
}