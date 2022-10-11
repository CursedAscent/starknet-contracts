%lang starknet

from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.math_cmp import is_nn
from starkware.cairo.common.math import unsigned_div_rem

from src.scene.SceneState import SceneState, EnemyList
from src.enemy.Enemy import Enemy
from src.player.Player import Player

from src.action.constants import (
    Action,
    PackedAction,
    ActionHistory,
    PackedActionHistory,
    AttributeEnum,
    ACTION_SHIFT,
    ACTION_BIT_POSITION,
    ACTION_HISTORY_SHIFT,
    ACTION_HISTORY_BIT_POSITION,
)
from src.utils.data_manipulation import unpack_data, insert_data, inplace_insert_data
from src.utils.xoshiro128.library import Xoshiro128_ss
from src.utils.math import clamp, mul_then_div

namespace ActionLib {
    //
    // Data
    //

    // Private struct that represents either a Player or an Enemy.
    struct Entity {
        damage_coef: felt,
        protection_points_coef: felt,
        armor_coef: felt,  // todo: change armor_coef to armor accross all repo
        max_health_points: felt,
        health_points: felt,
        protection_points: felt,
        active_effects: felt,
    }

    const HEALTH_POINTS_INDEX = 4;
    const PROTECTION_POINTS_INDEX = 5;
    const ACTIVE_EFFECTS_INDEX = 6;

    //
    // Logic
    //

    func pack_action{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(unpacked_action: Action) -> (packed_action: PackedAction) {
        let attr1 = unpacked_action.attr1 * ACTION_SHIFT._1;
        let value1 = unpacked_action.value1 * ACTION_SHIFT._2;
        let attr2 = unpacked_action.attr2 * ACTION_SHIFT._3;
        let value2 = unpacked_action.value2 * ACTION_SHIFT._4;
        let attr3 = unpacked_action.attr3 * ACTION_SHIFT._5;
        let value3 = unpacked_action.value3 * ACTION_SHIFT._6;
        let target1 = unpacked_action.target1 * ACTION_SHIFT._7;
        let target_value1 = unpacked_action.target_value1 * ACTION_SHIFT._8;
        let target2 = unpacked_action.target2 * ACTION_SHIFT._9;
        let target_value2 = unpacked_action.target_value2 * ACTION_SHIFT._10;
        let target3 = unpacked_action.target3 * ACTION_SHIFT._11;
        let target_value3 = unpacked_action.target_value3 * ACTION_SHIFT._12;

        return (
            packed_action=attr1 + value1 + attr2 + value2 + attr3 + value3 + target1 + target_value1 + target2 + target_value2 + target3 + target_value3,
        );
    }

    func unpack_action{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(packed_action: PackedAction) -> (action: Action) {
        alloc_locals;
        let (local attr1) = unpack_data(packed_action, ACTION_BIT_POSITION._1, 16777215);  // 3 bytes
        let (local value1) = unpack_data(packed_action, ACTION_BIT_POSITION._2, 65535);  // 2 bytes
        let (local attr2) = unpack_data(packed_action, ACTION_BIT_POSITION._3, 16777215);
        let (local value2) = unpack_data(packed_action, ACTION_BIT_POSITION._4, 65535);
        let (local attr3) = unpack_data(packed_action, ACTION_BIT_POSITION._5, 16777215);
        let (local value3) = unpack_data(packed_action, ACTION_BIT_POSITION._6, 65535);
        let (local target1) = unpack_data(packed_action, ACTION_BIT_POSITION._7, 65535);
        let (local target_value1) = unpack_data(packed_action, ACTION_BIT_POSITION._8, 65535);
        let (local target2) = unpack_data(packed_action, ACTION_BIT_POSITION._9, 65535);
        let (local target_value2) = unpack_data(packed_action, ACTION_BIT_POSITION._10, 65535);
        let (local target3) = unpack_data(packed_action, ACTION_BIT_POSITION._11, 65535);
        let (local target_value3) = unpack_data(packed_action, ACTION_BIT_POSITION._12, 65535);

        return (
            action=Action(attr1, value1, attr2, value2, attr3, value3, target1, target_value1, target2, target_value2, target3, target_value3),
        );
    }

    func pack_action_history{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(
        unpacked_ah1: ActionHistory,
        unpacked_ah2: ActionHistory,
        unpacked_ah3: ActionHistory,
        unpacked_ah4: ActionHistory,
    ) -> (packed_ah: PackedActionHistory) {
        let ah1_attr = unpacked_ah1.attribute * ACTION_HISTORY_SHIFT._1;
        let ah1_val = unpacked_ah1.computed_value * ACTION_HISTORY_SHIFT._2;
        let ah1_sid = unpacked_ah1.source_id * ACTION_HISTORY_SHIFT._3;
        let ah1_tid = unpacked_ah1.target_id * ACTION_HISTORY_SHIFT._4;
        let ah2_attr = unpacked_ah2.attribute * ACTION_HISTORY_SHIFT._5;
        let ah2_val = unpacked_ah2.computed_value * ACTION_HISTORY_SHIFT._6;
        let ah2_sid = unpacked_ah2.source_id * ACTION_HISTORY_SHIFT._7;
        let ah2_tid = unpacked_ah2.target_id * ACTION_HISTORY_SHIFT._8;
        let ah3_attr = unpacked_ah3.attribute * ACTION_HISTORY_SHIFT._9;
        let ah3_val = unpacked_ah3.computed_value * ACTION_HISTORY_SHIFT._10;
        let ah3_sid = unpacked_ah3.source_id * ACTION_HISTORY_SHIFT._11;
        let ah3_tid = unpacked_ah3.target_id * ACTION_HISTORY_SHIFT._12;
        let ah4_attr = unpacked_ah4.attribute * ACTION_HISTORY_SHIFT._13;
        let ah4_val = unpacked_ah4.computed_value * ACTION_HISTORY_SHIFT._14;
        let ah4_sid = unpacked_ah4.source_id * ACTION_HISTORY_SHIFT._15;
        let ah4_tid = unpacked_ah4.target_id * ACTION_HISTORY_SHIFT._16;

        return (
            packed_ah=ah1_attr + ah1_val + ah1_sid + ah1_tid + ah2_attr + ah2_val + ah2_sid + ah2_tid + ah3_attr + ah3_val + ah3_sid + ah3_tid + ah4_attr + ah4_val + ah4_sid + ah4_tid,
        );
    }

    func unpack_action_history{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(packed_ah: PackedActionHistory) -> (
        unpacked_ah1: ActionHistory,
        unpacked_ah2: ActionHistory,
        unpacked_ah3: ActionHistory,
        unpacked_ah4: ActionHistory,
    ) {
        alloc_locals;
        let (local attr1) = unpack_data(packed_ah, ACTION_HISTORY_BIT_POSITION._1, 16777215);  // 3 bytes
        let (local value1) = unpack_data(packed_ah, ACTION_HISTORY_BIT_POSITION._2, 65535);  // 2 bytes
        let (local sid1) = unpack_data(packed_ah, ACTION_HISTORY_BIT_POSITION._3, 255);  // 1 byte
        let (local tid1) = unpack_data(packed_ah, ACTION_HISTORY_BIT_POSITION._4, 255);
        let (local attr2) = unpack_data(packed_ah, ACTION_HISTORY_BIT_POSITION._5, 16777215);
        let (local value2) = unpack_data(packed_ah, ACTION_HISTORY_BIT_POSITION._6, 65535);
        let (local sid2) = unpack_data(packed_ah, ACTION_HISTORY_BIT_POSITION._7, 255);
        let (local tid2) = unpack_data(packed_ah, ACTION_HISTORY_BIT_POSITION._8, 255);
        let (local attr3) = unpack_data(packed_ah, ACTION_HISTORY_BIT_POSITION._9, 16777215);
        let (local value3) = unpack_data(packed_ah, ACTION_HISTORY_BIT_POSITION._10, 65535);
        let (local sid3) = unpack_data(packed_ah, ACTION_HISTORY_BIT_POSITION._11, 255);
        let (local tid3) = unpack_data(packed_ah, ACTION_HISTORY_BIT_POSITION._12, 255);
        let (local attr4) = unpack_data(packed_ah, ACTION_HISTORY_BIT_POSITION._13, 16777215);
        let (local value4) = unpack_data(packed_ah, ACTION_HISTORY_BIT_POSITION._14, 65535);
        let (local sid4) = unpack_data(packed_ah, ACTION_HISTORY_BIT_POSITION._15, 255);
        let (local tid4) = unpack_data(packed_ah, ACTION_HISTORY_BIT_POSITION._16, 255);

        return (
            unpacked_ah1=ActionHistory(attr1, value1, sid1, tid1),
            unpacked_ah2=ActionHistory(attr2, value2, sid2, tid2),
            unpacked_ah3=ActionHistory(attr3, value3, sid3, tid3),
            unpacked_ah4=ActionHistory(attr4, value4, sid4, tid4),
        );
    }

    // @notice Apply an action's effects on the current scene state & player.
    // @param scene_state: the current scene state.
    // @param player: the player state.
    // @param packed_action: the action's attribute (packed in a felt).
    // @param source_id: id of the source Entity of the action (-1 for the player)
    // @param target_id: id of the target Entity of the action (-1 for the player)
    // @param seed: PRNG seed
    // @return the new SceneState & Player.
    func play_action{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(
        scene_state: SceneState,
        player: Player,
        packed_action: PackedAction,
        source_id: felt,
        target_id: felt,
        seed: Xoshiro128_ss.XoshiroState,
    ) -> (
        new_scene: SceneState,
        new_player: Player,
        history_len: felt,
        history: PackedActionHistory*,
        seed: Xoshiro128_ss.XoshiroState,
    ) {
        alloc_locals;
        let (__fp__, _) = get_fp_and_pc();
        let (local action: Action) = unpack_action(packed_action);
        local source_len;
        let (local history: PackedActionHistory*) = alloc();

        // first attribute
        local source1: Entity*;
        if (source_id == -1) {
            tempvar p_addr: felt* = &player;
            source1 = cast(p_addr, Entity*);
            source_len = Player.SIZE;
        } else {
            tempvar tmp = &scene_state + 1 + source_id * Enemy.SIZE;
            source1 = cast(tmp, Entity*);
            source_len = Enemy.SIZE;
        }
        let (
            local enemies1, local player1, local history_len1, local history1, local seed
        ) = _apply_attribute(
            source_len,
            source1,
            source_id,
            scene_state.enemies_len,
            scene_state.enemies,
            player,
            action.attr1,
            action.value1,
            action.target1,
            action.target_value1,
            target_id,
            seed,
        );
        memcpy(history, history1, history_len1);

        // second attribute
        local source2: Entity*;
        if (source_id == -1) {
            tempvar p1_addr = &player1;
            source2 = p1_addr;
            source_len = Player.SIZE;
        } else {
            tempvar tmp1 = &enemies1 + source_id * Enemy.SIZE;
            source2 = tmp1;
            source_len = Enemy.SIZE;
        }
        let (
            local enemies2, local player2, local history_len2, local history2, local seed
        ) = _apply_attribute(
            source_len,
            source2,
            source_id,
            scene_state.enemies_len,
            enemies1,
            player1,
            action.attr2,
            action.value2,
            action.target2,
            action.target_value2,
            target_id,
            seed,
        );
        memcpy(history + history_len1, history2, history_len2);

        // third attribute
        local source3: Entity*;
        if (source_id == -1) {
            tempvar p2_addr = &player2;
            source3 = p2_addr;
            source_len = Player.SIZE;
        } else {
            tempvar tmp2 = &enemies2 + source_id * Enemy.SIZE;
            source3 = tmp2;
            source_len = Enemy.SIZE;
        }
        let (
            local enemies3, local player3, local history_len3, local history3, local seed
        ) = _apply_attribute(
            source_len,
            source3,
            source_id,
            scene_state.enemies_len,
            enemies2,
            player2,
            action.attr3,
            action.value3,
            action.target3,
            action.target_value3,
            target_id,
            seed,
        );
        memcpy(history + history_len1 + history_len2, history3, history_len3);

        return (
            SceneState(scene_state.enemies_len, enemies3, scene_state.current_event, scene_state.is_finished),
            player3,
            history_len1 + history_len2 + history_len3,
            history,
            seed,
        );
    }

    //
    // Internals
    //

    // @notice: Apply one action's attribute to all relevant targets.
    // @param source_len: the size of the source (either Player or Enemy struct)
    // @param source: the source Entity (read_only)
    // @parem enemies_nb: number of enemies in the scene
    // @param enemies: the list of all enemies
    // @param player: the player state
    // @param attribute: which action to apply
    // @param value: value associated to the action
    // @param target: target identifier from action
    // @param target_value: value associated with the target
    // @param target_id: optional target id from player choice
    // @return new_target: the updated target
    func _apply_attribute{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(
        source_len: felt,
        source: Entity*,
        source_id: felt,
        enemies_nb: felt,
        enemies: EnemyList,
        player: Player,
        attribute: felt,
        value: felt,
        target: felt,
        target_value: felt,
        target_id: felt,
        seed: Xoshiro128_ss.XoshiroState,
    ) -> (
        enemies: EnemyList,
        player: Player,
        history_len: felt,
        history: PackedActionHistory*,
        seed: Xoshiro128_ss.XoshiroState,
    ) {
        alloc_locals;
        local targets_id_len;
        local new_seed: Xoshiro128_ss.XoshiroState;
        let (local targets_id: felt*) = alloc();
        let (local history: PackedActionHistory*) = alloc();

        if (attribute == '') {
            return (enemies, player, 0, history, seed);
        }

        if (target == AttributeEnum.SELECTED_TARGET) {
            let (tmp) = _fill_target_with_selection(0, targets_id, target_id, target_value);
            targets_id_len = tmp;
            assert new_seed = seed;

            tempvar syscall_ptr: felt* = syscall_ptr;
            tempvar range_check_ptr = range_check_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar bitwise_ptr = bitwise_ptr;
        } else {
            if (target == AttributeEnum.RANDOM_TARGET) {
                let (tmp, seed) = _fill_target_with_random(
                    0, targets_id, enemies_nb, target_value, seed
                );
                targets_id_len = tmp;
                assert new_seed = seed;

                tempvar syscall_ptr: felt* = syscall_ptr;
                tempvar range_check_ptr = range_check_ptr;
                tempvar pedersen_ptr = pedersen_ptr;
                tempvar bitwise_ptr = bitwise_ptr;
            } else {
                if (target == AttributeEnum.ALL_TARGET) {
                    let (tmp) = _fill_target_with_all_enemies(
                        0, targets_id, enemies_nb, target_value
                    );
                    targets_id_len = tmp;
                    assert new_seed = seed;

                    tempvar syscall_ptr: felt* = syscall_ptr;
                    tempvar range_check_ptr = range_check_ptr;
                    tempvar pedersen_ptr = pedersen_ptr;
                    tempvar bitwise_ptr = bitwise_ptr;
                } else {
                    if (target == AttributeEnum.PLAYER_TARGET) {
                        let (tmp) = _fill_target_with_selection(0, targets_id, -1, target_value);
                        targets_id_len = tmp;
                        assert new_seed = seed;

                        tempvar syscall_ptr: felt* = syscall_ptr;
                        tempvar range_check_ptr = range_check_ptr;
                        tempvar pedersen_ptr = pedersen_ptr;
                        tempvar bitwise_ptr = bitwise_ptr;
                    } else {
                        if (target == AttributeEnum.SELF_TARGET) {
                            let (tmp) = _fill_target_with_selection(
                                0, targets_id, source_id, target_value
                            );
                            assert new_seed = seed;
                            targets_id_len = tmp;

                            tempvar syscall_ptr: felt* = syscall_ptr;
                            tempvar range_check_ptr = range_check_ptr;
                            tempvar pedersen_ptr = pedersen_ptr;
                            tempvar bitwise_ptr = bitwise_ptr;
                        } else {
                            with_attr error_message(
                                    "actionLib._apply_attribute: unknown target attribute parsed.") {
                                assert 1 = 0;
                            }

                            tempvar syscall_ptr: felt* = syscall_ptr;
                            tempvar range_check_ptr = range_check_ptr;
                            tempvar pedersen_ptr = pedersen_ptr;
                            tempvar bitwise_ptr = bitwise_ptr;
                        }
                    }
                }
            }
        }
        let (local enemies, local player, local new_seed) = _apply_attribute_to_targets(
            source_len,
            source,
            source_id,
            enemies,
            player,
            targets_id_len,
            targets_id,
            attribute,
            value,
            0,
            history,
            new_seed,
        );

        return (
            enemies=enemies,
            player=player,
            history_len=targets_id_len,
            history=history,
            seed=new_seed,
        );
    }

    // @notice: Apply one action's attribute to given targets.
    // NB: This algorithm assume that when source and target are the same entity, only target get updated.
    // @param source_len: the size of the source (either Player or Enemy struct)
    // @param source: the source Entity (read_only)
    // @param enemies: the list of all enemies
    // @param player: the player state
    // @param target_id_len: the amount of target_id
    // @param target_id: the target identifiers (-1 for player)
    // @param attribute: which action to apply
    // @param value: value associated to the action
    // @return new_target: the updated target
    func _apply_attribute_to_targets{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(
        source_len: felt,
        source: Entity*,
        source_id: felt,
        _enemies: EnemyList,
        player: Player,
        targets_id_len: felt,
        targets_id: felt*,
        attribute: felt,
        value: felt,
        history_len: felt,
        history: PackedActionHistory*,
        seed: Xoshiro128_ss.XoshiroState,
    ) -> (enemies: EnemyList, player: Player, seed: Xoshiro128_ss.XoshiroState) {
        alloc_locals;
        let (__fp__, _) = get_fp_and_pc();

        if (targets_id_len == 0) {
            return (_enemies, player, seed);
        }

        local target_id = [targets_id];

        // compute action's attribute on one target
        local target_entity_len;
        local target_entity: Entity*;
        if (target_id == -1) {
            target_entity_len = Player.SIZE;
            tempvar p_addr = &player;
            target_entity = cast(p_addr, Entity*);
        } else {
            target_entity_len = Enemy.SIZE;
            tempvar e_addr = &_enemies + Enemy.SIZE * target_id;
            target_entity = cast(e_addr, Entity*);
        }

        let tmp = _apply_attribute_to_target(
            source_len,
            source,
            source_id,
            target_entity_len,
            target_entity,
            target_id,
            attribute,
            value,
            seed,
        );

        local new_s_len = tmp[0];
        local new_s: Entity* = tmp[1];
        local new_t_len = tmp[2];
        local new_t: Entity* = tmp[3];
        [history] = tmp[4];
        local new_seed: Xoshiro128_ss.XoshiroState;
        assert new_seed = tmp[5];

        local tmp_new_player: Player;
        local new_player: Player;
        local tmp_new_enemies: EnemyList;
        local new_enemies: EnemyList;

        // apply source update
        if (source_id == -1) {
            // it's the player
            memcpy(&tmp_new_player, new_s, Player.SIZE);
            memcpy(&tmp_new_enemies, &_enemies, Enemy.SIZE * 8);

            tempvar syscall_ptr = syscall_ptr;
            tempvar range_check_ptr = range_check_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar bitwise_ptr: BitwiseBuiltin* = bitwise_ptr;
        } else {
            // it's an enemy
            memcpy(&tmp_new_player, &player, Player.SIZE);
            inplace_insert_data(
                Enemy.SIZE * source_id,
                Enemy.SIZE,
                new_s,
                Enemy.SIZE * 8,
                &_enemies,
                &tmp_new_enemies,
            );
            tempvar syscall_ptr = syscall_ptr;
            tempvar range_check_ptr = range_check_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar bitwise_ptr: BitwiseBuiltin* = bitwise_ptr;
        }

        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar bitwise_ptr: BitwiseBuiltin* = bitwise_ptr;
        // apply target update
        if (target_id == -1) {
            // it's the player
            memcpy(&new_player, new_t, Player.SIZE);
            memcpy(&new_enemies, &tmp_new_enemies, Enemy.SIZE * 8);

            tempvar syscall_ptr = syscall_ptr;
            tempvar range_check_ptr = range_check_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar bitwise_ptr: BitwiseBuiltin* = bitwise_ptr;
        } else {
            // it's an enemy
            memcpy(&new_player, &tmp_new_player, Player.SIZE);
            inplace_insert_data(
                Enemy.SIZE * target_id,
                Enemy.SIZE,
                new_t,
                Enemy.SIZE * 8,
                &tmp_new_enemies,
                &new_enemies,
            );

            tempvar syscall_ptr = syscall_ptr;
            tempvar range_check_ptr = range_check_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar bitwise_ptr: BitwiseBuiltin* = bitwise_ptr;
        }

        let result = _apply_attribute_to_targets(
            new_s_len,
            new_s,
            source_id,
            new_enemies,
            new_player,
            targets_id_len - 1,
            targets_id + 1,
            attribute,
            value,
            history_len + 1,
            history + 1,
            new_seed,
        );
        return (result);
    }

    // @notice: Apply one action's attribute to a target.
    // @param source_len: the size of the source (either Player or Enemy struct)
    // @param source: the source Entity (read only)
    // @param target_len: the size of the target (either Player or Enemy struct)
    // @param target: the target Entity (read only)
    // @param attribute: which action to apply
    // @param value: value associated to the action
    // @return new_target: the updated target
    func _apply_attribute_to_target{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(
        source_len: felt,
        source: Entity*,
        source_id: felt,
        target_len: felt,
        target: Entity*,
        target_id: felt,
        attribute: felt,
        value: felt,
        seed: Xoshiro128_ss.XoshiroState,
    ) -> (
        new_source_len: felt,
        new_source: Entity*,
        new_target_len: felt,
        new_target: Entity*,
        history: PackedActionHistory,
        seed: Xoshiro128_ss.XoshiroState,
    ) {
        alloc_locals;
        let (__fp__, _) = get_fp_and_pc();
        local s: Entity = [source];
        local t: Entity = [target];
        let (local new_target_state) = alloc();  // hp, pp and active_effects (3 felts)
        let (local new_source_state) = alloc();  // hp, pp and active_effects (3 felts)
        let dummy_ah = ActionHistory(0, 0, 0, 0);
        local ah1: ActionHistory;
        local ah2: ActionHistory;
        let ah3 = dummy_ah;
        let ah4 = dummy_ah;

        if (attribute == AttributeEnum.NO_ATTRIBUTE) {
            no_attribute:
            let (local new_target: Entity*) = alloc();
            let (local new_source: Entity*) = alloc();
            memcpy(new_target, target, target_len);
            memcpy(new_source, source, source_len);
            let (tmp_pah) = pack_action_history(dummy_ah, dummy_ah, dummy_ah, dummy_ah);
            return (source_len, new_source, target_len, new_target, tmp_pah, seed);
        }
        if (attribute == AttributeEnum.DIRECT_HIT) {
            // no source change
            [new_source_state] = s.health_points;
            [new_source_state + 1] = s.protection_points;
            [new_source_state + 2] = s.active_effects;
            // one history only
            assert ah2 = dummy_ah;

            dh:
            local damage = mul_then_div(mul_then_div(value, s.damage_coef, 100), 100, t.armor_coef);
            let new_pp = clamp(0, t.protection_points - damage, t.protection_points);
            local new_hp;
            if (new_pp == 0) {
                let anti_compiler_bug = clamp(
                    0, t.health_points - (damage - t.protection_points), t.max_health_points
                );
                new_hp = anti_compiler_bug;
                tempvar range_check_ptr = range_check_ptr;
            } else {
                new_hp = t.health_points;
                tempvar range_check_ptr = range_check_ptr;
            }

            [new_target_state] = new_hp;
            [new_target_state + 1] = new_pp;
            [new_target_state + 2] = t.active_effects;
            assert ah1 = ActionHistory(attribute, damage, source_id, target_id);
            tempvar range_check_ptr = range_check_ptr;
            jmp end;
        } else {
            tempvar range_check_ptr = range_check_ptr;
        }
        if (attribute == AttributeEnum.ATTACK_HEALTH) {
            // no source change
            [new_source_state] = s.health_points;
            [new_source_state + 1] = s.protection_points;
            [new_source_state + 2] = s.active_effects;

            let damage = mul_then_div(value, s.damage_coef, 100);
            let new_hp = clamp(0, t.health_points - damage, t.max_health_points);

            [new_target_state] = new_hp;
            [new_target_state + 1] = t.protection_points;
            [new_target_state + 2] = t.active_effects;

            assert ah1 = ActionHistory(attribute, damage, source_id, target_id);
            assert ah2 = dummy_ah;
            tempvar range_check_ptr = range_check_ptr;
            jmp end;
        } else {
            tempvar range_check_ptr = range_check_ptr;
        }
        if (attribute == AttributeEnum.BLEEDING_STACKS) {
            // no source change
            [new_source_state] = s.health_points;
            [new_source_state + 1] = s.protection_points;
            [new_source_state + 2] = s.active_effects;

            // local new_active_effect = add_active_effect(target.active_effect, 'BS', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
            assert ah1 = ActionHistory(attribute, value, source_id, target_id);
            assert ah2 = dummy_ah;
            tempvar range_check_ptr = range_check_ptr;
            jmp end;
        } else {
            tempvar range_check_ptr = range_check_ptr;
        }
        if (attribute == AttributeEnum.POISON_STACKS) {
            // no source change
            [new_source_state] = s.health_points;
            [new_source_state + 1] = s.protection_points;
            [new_source_state + 2] = s.active_effects;

            // local new_active_effect = add_active_effect(target.active_effect, 'PS', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
            assert ah1 = ActionHistory(attribute, value, source_id, target_id);
            assert ah2 = dummy_ah;
            tempvar range_check_ptr = range_check_ptr;
            jmp end;
        } else {
            tempvar range_check_ptr = range_check_ptr;
        }
        if (attribute == AttributeEnum.PASSIVE_ATTACK) {
            // no source change
            [new_source_state] = s.health_points;
            [new_source_state + 1] = s.protection_points;
            [new_source_state + 2] = s.active_effects;

            // local new_active_effect = add_active_effect(target.active_effect, 'PA', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
            assert ah1 = ActionHistory(attribute, value, source_id, target_id);
            assert ah2 = dummy_ah;
            tempvar range_check_ptr = range_check_ptr;
            jmp end;
        } else {
            tempvar range_check_ptr = range_check_ptr;
        }
        if (attribute == AttributeEnum.PROTECTION_POINT) {
            // no source change
            [new_source_state] = s.health_points;
            [new_source_state + 1] = s.protection_points;
            [new_source_state + 2] = s.active_effects;

            let add_pp = mul_then_div(value, t.protection_points_coef, 100);
            local new_pp = t.protection_points + add_pp;

            [new_target_state] = t.health_points;
            [new_target_state + 1] = new_pp;
            [new_target_state + 2] = t.active_effects;
            assert ah1 = ActionHistory(attribute, add_pp, source_id, target_id);
            assert ah2 = dummy_ah;
            tempvar range_check_ptr = range_check_ptr;
            jmp end;
        } else {
            tempvar range_check_ptr = range_check_ptr;
        }
        if (attribute == AttributeEnum.HEALTH_POINT) {
            // no source change
            [new_source_state] = s.health_points;
            [new_source_state + 1] = s.protection_points;
            [new_source_state + 2] = s.active_effects;

            // todo: apply s.damage_coef? otherwise there is no scaling
            let new_hp = clamp(0, t.health_points + value, t.max_health_points);

            [new_target_state] = new_hp;
            [new_target_state + 1] = t.protection_points;
            [new_target_state + 2] = t.active_effects;
            assert ah1 = ActionHistory(attribute, value, source_id, target_id);
            assert ah2 = dummy_ah;
            tempvar range_check_ptr = range_check_ptr;
            jmp end;
        } else {
            tempvar range_check_ptr = range_check_ptr;
        }
        if (attribute == AttributeEnum.ADD_ARMOR) {
            // no source change
            [new_source_state] = s.health_points;
            [new_source_state + 1] = s.protection_points;
            [new_source_state + 2] = s.active_effects;

            // let armor = value;  // todo: add to existing armor in active_effect (ONLY IF add_active_effect overwrite instead of adding)
            // let new_active_effect = add_active_effect(target.active_effect, 'AA', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
            assert ah1 = ActionHistory(attribute, value, source_id, target_id);
            assert ah2 = dummy_ah;
            tempvar range_check_ptr = range_check_ptr;
            jmp end;
        } else {
            tempvar range_check_ptr = range_check_ptr;
        }
        if (attribute == AttributeEnum.CLEANSE_DEBUFF) {
            // no source change
            [new_source_state] = s.health_points;
            [new_source_state + 1] = s.protection_points;
            [new_source_state + 2] = s.active_effects;

            cleanse_debuff:
            // NB: value could represent which kind of debuff are cleansed ?
            // local new_active_effect = remove_active_effect(target.active_effect, 'ALL_DEBUFF', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
            assert ah1 = ActionHistory(attribute, value, source_id, target_id);
            assert ah2 = dummy_ah;
            tempvar range_check_ptr = range_check_ptr;
            jmp end;
        } else {
            tempvar range_check_ptr = range_check_ptr;
        }
        if (attribute == AttributeEnum.ATTACK_BONUS) {
            // no source change
            [new_source_state] = s.health_points;
            [new_source_state + 1] = s.protection_points;
            [new_source_state + 2] = s.active_effects;

            // local new_active_effect = add_active_effect(target.active_effect, 'AB', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
            assert ah1 = ActionHistory(attribute, value, source_id, target_id);
            assert ah2 = dummy_ah;
            tempvar range_check_ptr = range_check_ptr;
            jmp end;
        } else {
            tempvar range_check_ptr = range_check_ptr;
        }
        if (attribute == AttributeEnum.PROTECTION_BONUS) {
            // no source change
            [new_source_state] = s.health_points;
            [new_source_state + 1] = s.protection_points;
            [new_source_state + 2] = s.active_effects;

            // local new_active_effect = add_active_effect(target.active_effect, 'PB', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
            assert ah1 = ActionHistory(attribute, value, source_id, target_id);
            assert ah2 = dummy_ah;
            tempvar range_check_ptr = range_check_ptr;
            jmp end;
        } else {
            tempvar range_check_ptr = range_check_ptr;
        }
        if (attribute == AttributeEnum.DOUBLE_DAMAGE) {
            // no source change
            [new_source_state] = s.health_points;
            [new_source_state + 1] = s.protection_points;
            [new_source_state + 2] = s.active_effects;

            // local new_active_effect = add_active_effect(target.active_effect, 'DD', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
            assert ah1 = ActionHistory(attribute, value, source_id, target_id);
            assert ah2 = dummy_ah;
            tempvar range_check_ptr = range_check_ptr;
            jmp end;
        } else {
            tempvar range_check_ptr = range_check_ptr;
        }
        if (attribute == AttributeEnum.DOUBLE_PROTECTION) {
            // no source change
            [new_source_state] = s.health_points;
            [new_source_state + 1] = s.protection_points;
            [new_source_state + 2] = s.active_effects;

            // local new_active_effect = add_active_effect(target.active_effect, 'DP', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
            assert ah1 = ActionHistory(attribute, value, source_id, target_id);
            assert ah2 = dummy_ah;
            tempvar range_check_ptr = range_check_ptr;
            jmp end;
        } else {
            tempvar range_check_ptr = range_check_ptr;
        }
        if (attribute == AttributeEnum.WEAKEN_DEFENSE) {
            // no source change
            [new_source_state] = s.health_points;
            [new_source_state + 1] = s.protection_points;
            [new_source_state + 2] = s.active_effects;
            assert ah2 = dummy_ah;

            wd:
            // local new_active_effect = add_active_effect(target.active_effect, 'WD', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
            assert ah1 = ActionHistory(attribute, value, source_id, target_id);
            tempvar range_check_ptr = range_check_ptr;
            jmp end;
        } else {
            tempvar range_check_ptr = range_check_ptr;
        }
        if (attribute == AttributeEnum.WEAKEN_ATTACK) {
            // no source change
            [new_source_state] = s.health_points;
            [new_source_state + 1] = s.protection_points;
            [new_source_state + 2] = s.active_effects;

            // local new_active_effect = add_active_effect(target.active_effect, 'WA', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
            assert ah1 = ActionHistory(attribute, value, source_id, target_id);
            assert ah2 = dummy_ah;
            tempvar range_check_ptr = range_check_ptr;
            jmp end;
        } else {
            tempvar range_check_ptr = range_check_ptr;
        }
        if (attribute == AttributeEnum.WEAKEN_PROTECTION) {
            // no source change
            [new_source_state] = s.health_points;
            [new_source_state + 1] = s.protection_points;
            [new_source_state + 2] = s.active_effects;

            // local new_active_effect = add_active_effect(target.active_effect, 'WP', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
            assert ah1 = ActionHistory(attribute, value, source_id, target_id);
            assert ah2 = dummy_ah;
            tempvar range_check_ptr = range_check_ptr;
            jmp end;
        } else {
            tempvar range_check_ptr = range_check_ptr;
        }
        if (attribute == AttributeEnum.PERMANENT_PROTECTION) {
            // no source change
            [new_source_state] = s.health_points;
            [new_source_state + 1] = s.protection_points;
            [new_source_state + 2] = s.active_effects;

            // local new_active_effect = add_active_effect(target.active_effect, 'PPS', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
            assert ah1 = ActionHistory(attribute, value, source_id, target_id);
            assert ah2 = dummy_ah;
            tempvar range_check_ptr = range_check_ptr;
            jmp end;
        } else {
            tempvar range_check_ptr = range_check_ptr;
        }
        if (attribute == AttributeEnum.GENERATE_ATTACK_BONUS) {
            // no source change
            [new_source_state] = s.health_points;
            [new_source_state + 1] = s.protection_points;
            [new_source_state + 2] = s.active_effects;

            // local new_active_effect = add_active_effect(target.active_effect, 'GAB', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
            assert ah1 = ActionHistory(attribute, value, source_id, target_id);
            assert ah2 = dummy_ah;
            tempvar range_check_ptr = range_check_ptr;
            jmp end;
        } else {
            tempvar range_check_ptr = range_check_ptr;
        }
        if (attribute == AttributeEnum.DH_IF_TARGET_BLEED) {
            // no source change
            [new_source_state] = s.health_points;
            [new_source_state + 1] = s.protection_points;
            [new_source_state + 2] = s.active_effects;

            // todo: check if target bleed
            tempvar is_bleeding = 1;

            tempvar range_check_ptr = range_check_ptr;
            assert ah2 = dummy_ah;
            jmp dh if is_bleeding != 0;
            jmp no_attribute;
        } else {
            tempvar range_check_ptr = range_check_ptr;
        }
        if (attribute == AttributeEnum.HEAL_BLEED_AMOUNT) {
            // no source change
            [new_source_state] = s.health_points;
            [new_source_state + 1] = s.protection_points;
            [new_source_state + 2] = s.active_effects;

            tempvar target_bleed_stack = 10;  // todo: get bleed stack from target
            let new_hp = clamp(0, t.health_points + target_bleed_stack, t.max_health_points);

            [new_target_state] = new_hp;
            [new_target_state + 1] = t.protection_points;
            [new_target_state + 2] = t.active_effects;
            assert ah1 = ActionHistory(attribute, target_bleed_stack, source_id, target_id);
            assert ah2 = dummy_ah;
            tempvar range_check_ptr = range_check_ptr;
            jmp end;
        } else {
            tempvar range_check_ptr = range_check_ptr;
        }
        if (attribute == AttributeEnum.DH_THEN_PP) {
            let damage = mul_then_div(mul_then_div(value, s.damage_coef, 100), 100, t.armor_coef);
            let remaining = clamp(0, damage - t.protection_points, damage);
            tempvar new_pp = remaining + s.protection_points;

            [new_source_state] = s.health_points;
            [new_source_state + 1] = new_pp;
            [new_source_state + 2] = s.active_effects;

            assert ah2 = ActionHistory(AttributeEnum.PROTECTION_POINT, remaining, source_id, target_id);
            tempvar range_check_ptr = range_check_ptr;
            jmp dh;
        } else {
            tempvar range_check_ptr = range_check_ptr;
        }
        if (attribute == AttributeEnum.DH_THEN_HEAL) {
            let damage = mul_then_div(mul_then_div(value, s.damage_coef, 100), 100, t.armor_coef);
            let bonus_hp = clamp(0, damage - t.protection_points, damage);
            let tmp = clamp(s.health_points, s.health_points + bonus_hp, s.max_health_points);
            tempvar new_hp = tmp;

            [new_source_state] = new_hp;
            [new_source_state + 1] = s.protection_points;
            [new_source_state + 2] = s.active_effects;

            assert ah2 = ActionHistory(AttributeEnum.HEALTH_POINT, bonus_hp, source_id, target_id);
            tempvar range_check_ptr = range_check_ptr;
            jmp dh;
        } else {
            tempvar range_check_ptr = range_check_ptr;
        }
        if (attribute == AttributeEnum.DH_FOR_DEBUFF_COUNT) {
            // no source change
            [new_source_state] = s.health_points;
            [new_source_state + 1] = s.protection_points;
            [new_source_state + 2] = s.active_effects;

            let damage_amount = value * 3;  // todo: replace 3 by nb of debuffs on target
            let damage = mul_then_div(
                mul_then_div(damage_amount, s.damage_coef, 100), 100, t.armor_coef
            );
            let tmp = clamp(0, t.protection_points - damage, t.protection_points);
            local new_hp;
            if (tmp == 0) {
                let anti_compiler_bug = clamp(
                    0, t.health_points - (damage - t.protection_points), t.max_health_points
                );
                new_hp = anti_compiler_bug;
                tempvar range_check_ptr = range_check_ptr;
            } else {
                new_hp = t.health_points;
                tempvar range_check_ptr = range_check_ptr;
            }

            tempvar new_pp = tmp;
            [new_target_state] = new_hp;
            [new_target_state + 1] = new_pp;
            [new_target_state + 2] = t.active_effects;

            assert ah1 = ActionHistory(AttributeEnum.DIRECT_HIT, damage, source_id, target_id);
            assert ah2 = dummy_ah;
            tempvar range_check_ptr = range_check_ptr;
            jmp end;
        } else {
            tempvar range_check_ptr = range_check_ptr;
        }
        if (attribute == AttributeEnum.CLEANSE_OR_HP_PP) {
            // no source change
            [new_source_state] = s.health_points;
            [new_source_state + 1] = s.protection_points;
            [new_source_state + 2] = s.active_effects;

            // todo:if has no debuff
            let add_pp = mul_then_div(value, t.protection_points_coef, 100);
            tempvar new_pp = t.protection_points + add_pp;
            // todo: apply damage_coef? otherwise there is no scaling
            let new_hp = clamp(0, t.health_points + value, t.max_health_points);

            [new_target_state] = new_hp;
            [new_target_state + 1] = new_pp;
            [new_target_state + 2] = t.active_effects;

            assert ah1 = ActionHistory(AttributeEnum.HEALTH_POINT, value, source_id, target_id);
            assert ah2 = ActionHistory(AttributeEnum.PROTECTION_POINT, add_pp, source_id, target_id);
            tempvar range_check_ptr = range_check_ptr;
            jmp end;

            // else
            // tempvar range_check_ptr = range_check_ptr;
            // jmp cleanse_debuff;
        } else {
            tempvar range_check_ptr = range_check_ptr;
        }
        if (attribute == AttributeEnum.LOOSE_HP) {
            // no source change
            [new_source_state] = s.health_points;
            [new_source_state + 1] = s.protection_points;
            [new_source_state + 2] = s.active_effects;

            let new_hp = clamp(0, t.health_points - value, t.health_points);
            [new_target_state] = new_hp;
            [new_target_state + 1] = t.protection_points;
            [new_target_state + 2] = t.active_effects;

            assert ah1 = ActionHistory(attribute, value, source_id, target_id);
            assert ah2 = dummy_ah;
            tempvar range_check_ptr = range_check_ptr;
            jmp end;
        } else {
            tempvar range_check_ptr = range_check_ptr;
        }
        if (attribute == AttributeEnum.WD_IF_TARGET_POISONED) {
            // no source change
            [new_source_state] = s.health_points;
            [new_source_state + 1] = s.protection_points;
            [new_source_state + 2] = s.active_effects;

            // todo: check if target is poisoned
            tempvar is_poisoned = 1;

            tempvar range_check_ptr = range_check_ptr;
            assert ah2 = dummy_ah;
            jmp wd if is_poisoned != 0;
            jmp no_attribute;
        } else {
            tempvar range_check_ptr = range_check_ptr;
        }
        if (attribute == AttributeEnum.PASSIVE_POISON) {
            // no source change
            [new_source_state] = s.health_points;
            [new_source_state + 1] = s.protection_points;
            [new_source_state + 2] = s.active_effects;

            // local new_active_effect = add_active_effect(target.active_effect, 'PO', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;

            assert ah1 = ActionHistory(attribute, value, source_id, target_id);
            assert ah2 = dummy_ah;
            tempvar range_check_ptr = range_check_ptr;
            jmp end;
        } else {
            tempvar range_check_ptr = range_check_ptr;
        }
        if (attribute == AttributeEnum.ATTACK_HEALTH_FOR_POISON_COUNT) {
            // no source change
            [new_source_state] = s.health_points;
            [new_source_state + 1] = s.protection_points;
            [new_source_state + 2] = s.active_effects;

            local damage_amount = value * 3;  // todo: replace 3 by nb of poison on target
            local damage = mul_then_div(mul_then_div(damage_amount, s.damage_coef, 100), 100, t.armor_coef);
            let new_pp = clamp(0, t.protection_points - damage, t.protection_points);
            local new_hp;
            if (new_pp == 0) {
                let anti_compiler_bug = clamp(
                    0, t.health_points - (damage - t.protection_points), t.max_health_points
                );
                new_hp = anti_compiler_bug;
                tempvar range_check_ptr = range_check_ptr;
            } else {
                new_hp = t.health_points;
                tempvar range_check_ptr = range_check_ptr;
            }

            [new_target_state] = new_hp;
            [new_target_state + 1] = new_pp;
            [new_target_state + 2] = t.active_effects;

            assert ah1 = ActionHistory(attribute, damage, source_id, target_id);
            assert ah2 = dummy_ah;
            tempvar range_check_ptr = range_check_ptr;
            jmp end;
        } else {
            tempvar range_check_ptr = range_check_ptr;
        }

        jmp no_attribute;  // unknown attribute

        end:
        let (new_s: Entity*) = insert_data(
            HEALTH_POINTS_INDEX, 3, new_source_state, source_len, source
        );
        let (new_t: Entity*) = insert_data(
            HEALTH_POINTS_INDEX, 3, new_target_state, target_len, target
        );

        let (local pah) = pack_action_history(ah1, ah2, ah3, ah4);
        return (
            new_source_len=source_len,
            new_source=new_s,
            new_target_len=target_len,
            new_target=new_t,
            history=pah,
            seed=seed,
        );
    }

    func _fill_target_with_selection{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(targets_id_len: felt, targets_id: felt*, target_id: felt, value: felt) -> (
        _targets_id_len: felt
    ) {
        if (value == 0) {
            return (_targets_id_len=targets_id_len);
        }

        [targets_id] = target_id;
        return _fill_target_with_selection(
            targets_id_len + 1, targets_id + 1, target_id, value - 1
        );
    }

    func _fill_target_with_random{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
    }(
        targets_id_len: felt,
        targets_id: felt*,
        nb_of_targets: felt,
        value: felt,
        seed: Xoshiro128_ss.XoshiroState,
    ) -> (_targets_id_len: felt, seed: Xoshiro128_ss.XoshiroState) {
        if (value == 0) {
            return (_targets_id_len=targets_id_len, seed=seed);
        }

        let (state: Xoshiro128_ss.XoshiroState, rnd: felt) = Xoshiro128_ss.next(seed);
        let (_, target_id) = unsigned_div_rem(rnd, nb_of_targets);
        [targets_id] = target_id;
        return _fill_target_with_random(
            targets_id_len + 1, targets_id + 1, nb_of_targets, value - 1, state
        );
    }

    func _fill_target_with_all_enemies{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(targets_id_len: felt, targets_id: felt*, enemy_nb: felt, value: felt) -> (
        _targets_id_len: felt
    ) {
        if (enemy_nb == 0) {
            return (_targets_id_len=targets_id_len);
        }

        let (new_targets_id_len) = _fill_target_with_selection(
            targets_id_len, targets_id, enemy_nb, value
        );

        return _fill_target_with_all_enemies(
            new_targets_id_len, targets_id + value, enemy_nb - 1, value
        );
    }
}
