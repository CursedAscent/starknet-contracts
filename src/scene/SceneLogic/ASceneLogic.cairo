// Abstract partial implementation of ISceneLogic

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc

from src.utils.constants import TokenRef
from src.enemy.Enemy import Enemy

//
// Storage
//

@storage_var
func enemy_list_len() -> (enemy_list_len: felt) {
}

@storage_var
func enemy_list(enemy_id: felt) -> (enemy_ref: TokenRef) {
}

@storage_var
func event_list_len() -> (event_list_len: felt) {
}

@storage_var
func event_list(event_id: felt) -> (event: felt) {
}

namespace ASceneLogic {
    //
    // Constructor
    //
    func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _enemy_list_len: felt, _enemy_list: TokenRef*, _event_list_len: felt, _event_list: felt*
    ) {
        event_list_len.write(_event_list_len);
        _initialize_event_id_list(_event_list_len - 1, _event_list + (_event_list_len - 1));
        enemy_list_len.write(_enemy_list_len);
        _initialize_enemy_id_list(
            _enemy_list_len - 1, _enemy_list + (_enemy_list_len - 1) * TokenRef.SIZE
        );

        return ();
    }

    func _initialize_event_id_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        data_len: felt, data: felt*
    ) {
        if (data_len == -1) {
            return ();
        }

        event_list.write(data_len, [data]);

        return _initialize_event_id_list(data_len - 1, data - 1);
    }

    func _initialize_enemy_id_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        data_len: felt, data: TokenRef*
    ) {
        if (data_len == -1) {
            return ();
        }

        enemy_list.write(data_len, [data]);

        return _initialize_enemy_id_list(data_len - 1, data - TokenRef.SIZE);
    }

    //
    // Getters
    //

    func get_enemy{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        enemy_id: felt
    ) -> (enemy: TokenRef) {
        let (token_ref) = enemy_list.read(enemy_id);

        return (enemy=token_ref);
    }

    func get_event_id_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        event_id_list_len: felt, event_id_list: felt*
    ) {
        alloc_locals;

        let (local event_id_list_len) = event_list_len.read();
        let (local event_id_list: felt*) = alloc();

        _fill_event_id_list(event_id_list_len, event_id_list);

        return (event_id_list_len, event_id_list);
    }

    func get_enemy_id_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        enemy_id_list_len: felt, enemy_id_list: TokenRef*
    ) {
        alloc_locals;

        let (local enemy_id_list_len) = event_list_len.read();
        let (local enemy_id_list: TokenRef*) = alloc();

        _fill_event_id_list(enemy_id_list_len, enemy_id_list);

        return (enemy_id_list_len, enemy_id_list);
    }

    //
    // Internals
    //

    func _fill_event_id_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        event_id_list_len: felt, event_id_list: felt*
    ) {
        if (event_id_list_len == -1) {
            return ();
        }

        let (tempVar) = event_list.read(event_id_list_len);
        [event_id_list] = tempVar;

        return _fill_event_id_list(event_id_list_len - 1, event_id_list - 1);
    }

    func _fill_enemy_id_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        enemy_id_list_len: felt, enemy_id_list: TokenRef*
    ) {
        if (enemy_id_list_len == -1) {
            return ();
        }

        let (tempVar: TokenRef) = enemy_list.read(enemy_id_list_len);

        [enemy_id_list] = tempVar.collection_addr;
        [enemy_id_list + 1] = tempVar.token_id;

        return _fill_enemy_id_list(enemy_id_list_len - 1, enemy_id_list - 1);
    }
}
