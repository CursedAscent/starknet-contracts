%lang starknet

from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.math_cmp import is_nn

from src.scene.SceneState import SceneState, EnemyList
from src.enemy.Enemy import Enemy
from src.player.Player import Player
from src.card.Card import Card

from src.action.constants import (
    Action,
    PackedAction,
    AttributeEnum,
    ATTRIBUTE_SHIFT,
    ATTRIBUTE_BIT_POSITION,
)
from src.utils.data_manipulation import unpack_data, insert_data, inplace_insert_data
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

    func pack{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(unpacked_action: Action) -> (packed_action: PackedAction) {
        let attr1 = unpacked_action.attr1 * ATTRIBUTE_SHIFT._1;
        let value1 = unpacked_action.value1 * ATTRIBUTE_SHIFT._2;
        let attr2 = unpacked_action.attr2 * ATTRIBUTE_SHIFT._3;
        let value2 = unpacked_action.value2 * ATTRIBUTE_SHIFT._4;
        let attr3 = unpacked_action.attr3 * ATTRIBUTE_SHIFT._5;
        let value3 = unpacked_action.value3 * ATTRIBUTE_SHIFT._6;
        let target1 = unpacked_action.target1 * ATTRIBUTE_SHIFT._7;
        let target_value1 = unpacked_action.target_value1 * ATTRIBUTE_SHIFT._8;
        let target2 = unpacked_action.target2 * ATTRIBUTE_SHIFT._9;
        let target_value2 = unpacked_action.target_value2 * ATTRIBUTE_SHIFT._10;
        let target3 = unpacked_action.target3 * ATTRIBUTE_SHIFT._11;
        let target_value3 = unpacked_action.target_value3 * ATTRIBUTE_SHIFT._12;

        return (
            packed_action=attr1 + value1 + attr2 + value2 + attr3 + value3 + target1 + target_value1 + target2 + target_value2 + target3 + target_value3,
        );
    }

    func unpack{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(packed_action: PackedAction) -> (action: Action) {
        alloc_locals;
        let (local attr1) = unpack_data(packed_action, ATTRIBUTE_BIT_POSITION._1, 16777215);  // 3 bytes
        let (local value1) = unpack_data(packed_action, ATTRIBUTE_BIT_POSITION._2, 65535);  // 2 bytes
        let (local attr2) = unpack_data(packed_action, ATTRIBUTE_BIT_POSITION._3, 16777215);
        let (local value2) = unpack_data(packed_action, ATTRIBUTE_BIT_POSITION._4, 65535);
        let (local attr3) = unpack_data(packed_action, ATTRIBUTE_BIT_POSITION._5, 16777215);
        let (local value3) = unpack_data(packed_action, ATTRIBUTE_BIT_POSITION._6, 65535);
        let (local target1) = unpack_data(packed_action, ATTRIBUTE_BIT_POSITION._7, 65535);
        let (local target_value1) = unpack_data(packed_action, ATTRIBUTE_BIT_POSITION._8, 65535);
        let (local target2) = unpack_data(packed_action, ATTRIBUTE_BIT_POSITION._9, 65535);
        let (local target_value2) = unpack_data(packed_action, ATTRIBUTE_BIT_POSITION._10, 65535);
        let (local target3) = unpack_data(packed_action, ATTRIBUTE_BIT_POSITION._11, 65535);
        let (local target_value3) = unpack_data(packed_action, ATTRIBUTE_BIT_POSITION._12, 65535);

        return (
            action=Action(attr1, value1, attr2, value2, attr3, value3, target1, target_value1, target2, target_value2, target3, target_value3),
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
        seed: felt,
    ) -> (new_scene: SceneState, new_player: Player, seed: felt) {
        alloc_locals;
        let (__fp__, _) = get_fp_and_pc();
        let (local action: Action) = unpack(packed_action);
        local source_len;

        // first attribute
        local source1: Entity*;
        if (source_id == -1) {
            tempvar p_addr: felt* = &player;
            source1 = p_addr;
            source_len = Player.SIZE;
        } else {
            tempvar tmp = cast(&scene_state, felt) + 1 + source_id * Enemy.SIZE;
            source1 = tmp;
            source_len = Enemy.SIZE;
        }
        let (local enemies1, local player1) = _apply_attribute(
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
        );

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
        let (local enemies2, local player2) = _apply_attribute(
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
        );

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
        let (local enemies3, local player3) = _apply_attribute(
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
        );

        return (
            SceneState(scene_state.enemies_len, enemies3, scene_state.current_event, scene_state.is_finished),
            player3,
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
    ) -> (enemies: EnemyList, player: Player) {
        alloc_locals;
        local targets_id_len;
        let (local targets_id: felt*) = alloc();

        // insane optimization
        if (attribute == '') {
            return (enemies, player);
        }

        if (target == AttributeEnum.SELECTED_TARGET) {
            let (tmp1) = _fill_target_with_selection(0, targets_id, target_id, target_value);
            targets_id_len = tmp1;

            tempvar syscall_ptr: felt* = syscall_ptr;
            tempvar range_check_ptr = range_check_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
        } else {
            if (target == AttributeEnum.RANDOM_TARGET) {
                let (tmp2) = _fill_target_with_random(0, targets_id, target_value);
                targets_id_len = tmp2;

                tempvar syscall_ptr: felt* = syscall_ptr;
                tempvar range_check_ptr = range_check_ptr;
                tempvar pedersen_ptr = pedersen_ptr;
            } else {
                if (target == AttributeEnum.ALL_TARGET) {
                    let (tmp3) = _fill_target_with_all_enemies(
                        0, targets_id, enemies_nb, target_value
                    );
                    targets_id_len = tmp3;

                    tempvar syscall_ptr: felt* = syscall_ptr;
                    tempvar range_check_ptr = range_check_ptr;
                    tempvar pedersen_ptr = pedersen_ptr;
                } else {
                    if (target == AttributeEnum.PLAYER_TARGET) {
                        let (tmp4) = _fill_target_with_player(0, targets_id, target_value);
                        targets_id_len = tmp4;

                        tempvar syscall_ptr: felt* = syscall_ptr;
                        tempvar range_check_ptr = range_check_ptr;
                        tempvar pedersen_ptr = pedersen_ptr;
                    } else {
                        assert 1 = 0;  // Unknown target identifier

                        tempvar syscall_ptr: felt* = syscall_ptr;
                        tempvar range_check_ptr = range_check_ptr;
                        tempvar pedersen_ptr = pedersen_ptr;
                    }
                }
            }
        }
        let result = _apply_attribute_to_targets(
            source_len,
            source,
            source_id,
            enemies,
            player,
            targets_id_len,
            targets_id,
            attribute,
            value,
        );

        return (result);
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
    ) -> (enemies: EnemyList, player: Player) {
        alloc_locals;
        let (__fp__, _) = get_fp_and_pc();

        if (targets_id_len == 0) {
            return (_enemies, player);
        }

        local target_id = [targets_id];

        local tmp_new_player: Player;
        local new_player: Player;
        local tmp_new_enemies: EnemyList;
        local new_enemies: EnemyList;
        local new_s_len;
        local new_s: Entity*;
        local new_t_len;
        local new_t: Entity*;

        if (target_id == -1) {
            let tmp1 = _apply_attribute_to_target(
                source_len, source, Player.SIZE, cast(&player, Entity*), attribute, value
            );
            new_s_len = tmp1[0];
            new_s = tmp1[1];
            new_t_len = tmp1[2];
            new_t = tmp1[3];

            tempvar syscall_ptr = syscall_ptr;
            tempvar range_check_ptr = range_check_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar bitwise_ptr: BitwiseBuiltin* = bitwise_ptr;
        } else {
            let tmp2 = _apply_attribute_to_target(
                source_len,
                source,
                Enemy.SIZE,
                cast(&_enemies + Enemy.SIZE * target_id, Entity*),
                attribute,
                value,
            );
            new_s_len = tmp2[0];
            new_s = tmp2[1];
            new_t_len = tmp2[2];
            new_t = tmp2[3];

            tempvar syscall_ptr = syscall_ptr;
            tempvar range_check_ptr = range_check_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar bitwise_ptr: BitwiseBuiltin* = bitwise_ptr;
        }

        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar bitwise_ptr: BitwiseBuiltin* = bitwise_ptr;
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
            // todo: it may fail because we give a tuple through a ptr
            inplace_insert_data(
                Enemy.SIZE * target_id,
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
            // todo: it may fail because we give a tuple through a ptr
            inplace_insert_data(
                Enemy.SIZE * target_id, Enemy.SIZE, new_t, Enemy.SIZE * 8, &_enemies, &new_enemies
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
        target_len: felt,
        target: Entity*,
        attribute: felt,
        value: felt,
    ) -> (new_source_len: felt, new_source: Entity*, new_target_len: felt, new_target: Entity*) {
        alloc_locals;
        let (__fp__, _) = get_fp_and_pc();
        local s: Entity = [source];
        local t: Entity = [target];
        let (local new_target_state) = alloc();  // hp, pp and active_effects (3 felts)
        let (local new_source_state) = alloc();  // hp, pp and active_effects (3 felts)

        if (attribute == AttributeEnum.NO_ATTRIBUTE) {
            no_attribute:
            let (local new_target: Entity*) = alloc();
            let (local new_source: Entity*) = alloc();
            memcpy(new_target, target, target_len);
            memcpy(new_source, source, source_len);
            return (source_len, new_source, target_len, new_target);
        }
        if (attribute == AttributeEnum.DIRECT_HIT) {
            // no source change
            [new_source_state] = s.health_points;
            [new_source_state + 1] = s.protection_points;
            [new_source_state + 2] = s.active_effects;

            dh:
            local damage = mul_then_div(mul_then_div(value, s.damage_coef, 100), 100, t.armor_coef);
            let new_pp = clamp(0, t.protection_points - damage, t.protection_points);
            tempvar new_hp;
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

            local new_pp = mul_then_div(value, t.protection_points_coef, 100) + t.protection_points;

            [new_target_state] = t.health_points;
            [new_target_state + 1] = new_pp;
            [new_target_state + 2] = t.active_effects;
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
            // local new_active_effect = remove_active_effect(target.active_effect, 'ALL_DEBUFF', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
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

            wd:
            // local new_active_effect = add_active_effect(target.active_effect, 'WD', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
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
            // jmp dh if is_bleeding != 0;
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

            tempvar range_check_ptr = range_check_ptr;
            // jmp dh;
            jmp end;
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

            tempvar range_check_ptr = range_check_ptr;
            // jmp dh;
            jmp end;
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
            tempvar new_hp;
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
            tempvar new_pp = mul_then_div(value, t.protection_points_coef, 100) + t.protection_points;
            // todo: apply damage_coef? otherwise there is no scaling
            let new_hp = clamp(0, t.health_points + value, t.max_health_points);

            [new_target_state] = new_hp;
            [new_target_state + 1] = new_pp;
            [new_target_state + 2] = t.active_effects;

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
            // jmp wd if is_poisoned != 0;
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
            tempvar new_hp;
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
        return (
            new_source_len=source_len, new_source=new_s, new_target_len=target_len, new_target=new_t
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

    func _fill_target_with_random{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        targets_id_len: felt, targets_id: felt*, value: felt
    ) -> (_targets_id_len: felt) {
        if (value == 0) {
            return (_targets_id_len=targets_id_len);
        }

        tempvar rand = 0;  // todo: random
        [targets_id] = rand;
        return _fill_target_with_random(targets_id_len + 1, targets_id + 1, value - 1);
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

    func _fill_target_with_player{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        targets_id_len: felt, targets_id: felt*, value: felt
    ) -> (_targets_id_len: felt) {
        if (value == 0) {
            return (_targets_id_len=targets_id_len);
        }

        tempvar player_index = -1;
        [targets_id] = player_index;
        return _fill_target_with_player(targets_id_len + 1, targets_id + 1, value - 1);
    }
}
