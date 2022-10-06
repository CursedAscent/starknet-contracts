%lang starknet

from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.memcpy import memcpy

from src.scene.SceneState import SceneState
from src.enemy.Enemy import Enemy
from src.player.Player import Player
from src.card.Card import Card

from src.action.constants import Action, AttributeEnum, ATTRIBUTE_SHIFT, ATTRIBUTE_BIT_POSITION
from src.utils.data_manipulation import unpack_data, insert_data, implace_insert_data
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
    }(unpacked_action: Action) -> (packed_action: felt) {
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
    }(packed_action: felt) -> (action: Action) {
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
        packed_action: felt,
        source_id: felt,
        target_id: felt,
        seed: felt,
    ) -> (new_scene: SceneState, new_player: Player) {
        alloc_locals;
        local scene: SceneState;
        local player: PlayerState;
        let (local action: Action) = unpack(packed_action);
        local source_len = 0;  // unused

        // first attribute
        local source1: Entity*;
        if (source_id == -1) {
            source1 = &player;
        } else {
            source1 = &scene_state + 1 + source_id * Enemy.SIZE;
        }
        let (local enemies1, local player1) = _apply_attribute(
            source_len,
            source1,
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
            source2 = &player1;
        } else {
            source2 = &enemies1 + source_id * Enemy.SIZE;
        }
        let (local enemies2, local player2) = _apply_attribute(
            source_len,
            source2,
            scene_state.enemies_len,
            scene_state.enemies,
            player,
            action.attr2,
            action.value2,
            action.target2,
            action.target_value2,
            target_id,
        );

        // third attribute
        local source3: Entity*;
        if (source_id == -1) {
            source3 = &player2;
        } else {
            source3 = &enemies2 + source_id * Enemy.SIZE;
        }
        let (local enemies3, local player3) = _apply_attribute(
            source_len,
            source3,
            scene_state.enemies_len,
            scene_state.enemies,
            player,
            action.attr3,
            action.value3,
            action.target3,
            action.target_value3,
            target_id,
        );

        return (SceneState(scene_state.enemy_len, enemies3, scene_state.current_event, scene_state.is_finished));
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
        enemies_nb: felt,
        enemies: (Enemy, Enemy, Enemy, Enemy, Enemy, Enemy, Enemy, Enemy),
        player: Player,
        attribute: felt,
        value: felt,
        target: felt,
        target_value: felt,
        target_id: felt,
    ) -> (enemies: (Enemy, Enemy, Enemy, Enemy, Enemy, Enemy, Enemy, Enemy), player: Player) {
        alloc_locals;
        local targets_id_len;
        local targets_id: felt* = alloc();

        if (attribute == '') {
            return (enemies, player);
        }

        if (target == AttributeEnum.SELECTED_TARGET) {
            targets_id_len = _fill_target_with_selection(target_value, targets_id, target_id, target_value);
        } else {
            if (target == AttributeEnum.RANDOM_TARGET) {
                targets_id_len = _fill_target_with_random(target_value, targets_id, target_value);
            } else {
                if (target == AttributeEnum.ALL_TARGET) {
                    targets_id_len = _fill_target_with_all_enemies(target_value, enemies_nb, target_value);
                } else {
                    if (target == AttributeEnum.PLAYER_TARGET) {
                        targets_id_len = _fill_target_with_player(target_value, targets_id, target_value);
                    } else {
                        assert 1 = 0;  // Unknown target identifier
                    }
                }
            }
        }

        return (_apply_attribute_to_targets(source_len, source, enemies, player, targets_id_len, targets_id, attribute, value));
    }

    // @notice: Apply one action's attribute to given targets.
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
        enemies: (Enemy, Enemy, Enemy, Enemy, Enemy, Enemy, Enemy, Enemy),
        player: Player,
        targets_id_len: felt,
        targets_id: felt*,
        attribute: felt,
        value: felt,
    ) -> (enemies: (Enemy, Enemy, Enemy, Enemy, Enemy, Enemy, Enemy, Enemy), player: Player) {
        alloc_locals;
        let (__fp__, _) = get_fp_and_pc();

        if (targets_id_len == 0) {
            return (enemies, player);
        }

        local target_id = [targets_id];
        if (target_id == -1) {
            // it's the player
            local new_player = _apply_attribute_to_target(source_len, source, Player.SIZE, &player, attribute, value);

            return (_apply_attribute_to_targets(source_len, source, enemies, new_player, targets_id_len - 1, targets_id + 1, attribute, value));
        } else {
            local new_enemies: (Enemy, Enemy, Enemy, Enemy, Enemy, Enemy, Enemy, Enemy);
            local enemy_ptr: Enemy* = &enemies;
            local new_enemy = _apply_attribute_to_target(source_len, source, Enemy.SIZE, enemy_ptr + Enemy.SIZE * target_id, attribute, value);
            // todo; it may fail because we give a tuple through a ptr
            implace_insert_data(
                Enemy.SIZE * target_id, Enemy.SIZE, &new_enemy, enemies.SIZE, enemies, new_enemies
            );

            return (_apply_attribute_to_targets(source_len, source, new_enemies, player, targets_id_len - 1, targets_id + 1, attribute, value));
        }
    }

    // @notice: Apply one action's attribute to a target.
    // @param source_len: the size of the source (either Player or Enemy struct)
    // @param source: the source Entity (read_only)
    // @param target_len: the size of the target (either Player or Enemy struct)
    // @param target: the target Entity (base of the return value)
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
    ) -> (new_target: Entity) {
        alloc_locals;
        let (__fp__, _) = get_fp_and_pc();
        local s = [source];
        local t = [target];
        local new_target_state = alloc();  // hp, pp and active_effects (3 felts)
        // local new_source_state = alloc();  // hp, pp and active_effects (3 felts)

        if (attribute == AttributeEnum.NO_ATTRIBUTE) {
            no_attribute:
            local new_target = alloc();
            memcpy(new_target, target, target_len);
            return new_target;
        }
        if (attribute == AttributeEnum.DIRECT_HIT) {
            // todo: update source here (NOT AFTER dh LABEL)
            dh:
            local damage = mul_then_div(mul_then_div(value, s.damage_coef, 100), 100, t.armor_coef);
            tempvar new_pp = clamp(0, t.protection_point - damage, t.protection_point);
            tempvar new_hp;
            if (new_pp == 0) {
                new_hp = clamp(0, t.health_points - (damage - t.protection_point), t.max_health_point);
            } else {
                new_hp = t.health_points;
            }

            [new_target_state] = new_hp;
            [new_target_state + 1] = new_pp;
            [new_target_state + 2] = t.active_effects;
            jmp end;
        }
        if (attribute == AttributeEnum.ATTACK_HEALTH) {
            local damage = mul_then_div(value, s.damage_coef);
            local new_hp = clamp(0, t.health_points - damage, t.max_health_point);

            [new_target_state] = new_hp;
            [new_target_state + 1] = t.protection_points;
            [new_target_state + 2] = t.active_effects;
            jmp end;
        }
        if (attribute == AttributeEnum.BLEEDING_STACKS) {
            // local new_active_effect = add_active_effect(target.active_effect, 'BS', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
            // jmp end;
        }
        if (attribute == AttributeEnum.POISON_STACKS) {
            // local new_active_effect = add_active_effect(target.active_effect, 'PS', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
            // jmp end;
        }
        if (attribute == AttributeEnum.PASSIVE_ATTACK) {
            // local new_active_effect = add_active_effect(target.active_effect, 'PA', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
            // jmp end;
        }
        if (attribute == AttributeEnum.PROTECTION_POINT) {
            local new_pp = mul_then_div(value, t.protection_coef, 100) + t.protection_point;

            [new_target_state] = t.health_points;
            [new_target_state + 1] = new_pp;
            [new_target_state + 2] = t.active_effects;
            jmp end;
        }
        if (attribute == AttributeEnum.HEALTH_POINT) {
            // todo: apply damage_coef? otherwise there is no scaling
            local new_hp = clamp(0, t.health_points + value, t.max_health_point);

            [new_target_state] = new_hp;
            [new_target_state + 1] = t.protection_points;
            [new_target_state + 2] = t.active_effects;
            jmp end;
        }
        if (attribute == AttributeEnum.ADD_ARMOR) {
            // local armor = value;  // todo: add to existing armor in active_effect (ONLY IF add_active_effect overwrite instead of adding)
            // local new_active_effect = add_active_effect(target.active_effect, 'AA', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
            // jmp end;
        }
        if (attribute == AttributeEnum.CLEANSE_DEBUFF) {
            cleanse_debuff:
            // local new_active_effect = remove_active_effect(target.active_effect, 'ALL_DEBUFF', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
            // jmp end;
        }
        if (attribute == AttributeEnum.ATTACK_BONUS) {
            // local new_active_effect = add_active_effect(target.active_effect, 'AB', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
            // jmp end;
        }
        if (attribute == AttributeEnum.PROTECTION_BONUS) {
            // local new_active_effect = add_active_effect(target.active_effect, 'PB', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
            // jmp end;
        }
        if (attribute == AttributeEnum.DOUBLE_DAMAGE) {
            // local new_active_effect = add_active_effect(target.active_effect, 'DD', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
            // jmp end;
        }
        if (attribute == AttributeEnum.DOUBLE_PROTECTION) {
            // local new_active_effect = add_active_effect(target.active_effect, 'DP', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
            // jmp end;
        }
        if (attribute == AttributeEnum.WEAKEN_DEFENSE) {
            wd:
            // local new_active_effect = add_active_effect(target.active_effect, 'WD', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
            // jmp end;
        }
        if (attribute == AttributeEnum.WEAKEN_ATTACK) {
            // local new_active_effect = add_active_effect(target.active_effect, 'WA', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
            // jmp end;
        }
        if (attribute == AttributeEnum.WEAKEN_PROTECTION) {
            // local new_active_effect = add_active_effect(target.active_effect, 'WP', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
            // jmp end;
        }
        if (attribute == AttributeEnum.PERMANENT_PROTECTION) {
            // local new_active_effect = add_active_effect(target.active_effect, 'PPS', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
            // jmp end;
        }
        if (attribute == AttributeEnum.GENERATE_ATTACK_BONUS) {
            // local new_active_effect = add_active_effect(target.active_effect, 'GAB', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
            // jmp end;
        }
        if (attribute == AttributeEnum.DH_IF_TARGET_BLEED) {
            // todo: check if target bleed
            tempvar is_bleeding = 1;

            jmp dh if is_bleeding != 0;
            jmp no_attribute;
        }
        if (attribute == AttributeEnum.HEAL_BLEED_AMOUNT) {
            tempvar target_bleed_stack = 10;  // todo: get bleed stack from target
            local new_hp = clamp(0, s.health_points + target_bleed_stack, t.max_health_point);

            [new_target_state] = new_hp;
            [new_target_state + 1] = t.protection_points;
            [new_target_state + 2] = t.active_effects;
            jmp end;
        }
        if (attribute == AttributeEnum.DH_THEN_PP) {
            local damage = mul_then_div(mul_then_div(value, s.damage_coef, 100), 100, t.armor_coef);
            local new_pp = clamp(0, damage - t.protection_point, damage);
            // todo: source has s.protection_points + new_pp

            jmp dh;
        }
        if (attribute == AttributeEnum.DH_THEN_HEAL) {
            local damage = mul_then_div(mul_then_div(value, s.damage_coef, 100), 100, t.armor_coef);
            local new_hp = clamp(0, damage - t.protection_point, damage);
            // todo: source has s.health_point + new_hp

            jmp dh;
        }
        if (attribute == AttributeEnum.DH_FOR_DEBUFF_COUNT) {
            local damage_amount = value * 3;  // todo: replace 3 by nb of debuffs on target
            local damage = mul_then_div(mul_then_div(damage_amount, s.damage_coef, 100), 100, t.armor_coef);
            tempvar new_pp = clamp(0, t.protection_point - damage, t.protection_point);
            tempvar new_hp;
            if (new_pp == 0) {
                new_hp = clamp(0, t.health_points - (damage - t.protection_point), t.max_health_point);
            } else {
                new_hp = t.health_points;
            }

            [new_target_state] = new_hp;
            [new_target_state + 1] = new_pp;
            [new_target_state + 2] = t.active_effects;
            jmp end;
        }
        if (attribute == AttributeEnum.LOOSE_HP_THEN_DH) {
            // todo: check if target bleed
            tempvar is_bleeding = 1;

            jmp dh if is_bleeding != 0;
            jmp no_attribute;
        }
        if (attribute == AttributeEnum.CLEANSE_OR_HP_PP) {
            // if has no debuff
            local new_pp = mul_then_div(value, t.protection_coef, 100) + t.protection_point;
            // todo: apply damage_coef? otherwise there is no scaling
            local new_hp = clamp(0, t.health_points + value, t.max_health_point);

            [new_target_state] = new_hp;
            [new_target_state + 1] = new_pp;
            [new_target_state + 2] = t.active_effects;
            jmp end;

            // else
            jmp cleanse_debuff;
        }
        if (attribute == AttributeEnum.LOOSE_HP) {
            // todo: source loose 'value' hp

            [new_target_state] = t.health_points;
            [new_target_state + 1] = t.protection_points;
            [new_target_state + 2] = t.active_effects;
            jmp end;
        }
        if (attribute == AttributeEnum.WD_IF_TARGET_POISONED) {
            // todo: check if target is poisoned
            tempvar is_poisoned = 1;

            jmp wd if is_poisoned != 0;
            jmp no_attribute;
        }
        if (attribute == AttributeEnum.PASSIVE_POISON) {
            // local new_active_effect = add_active_effect(target.active_effect, 'PO', value);

            // [new_target_state] = t.health_points;
            // [new_target_state + 1] = t.protection_points;
            // [new_target_state + 2] = new_active_effect;
            // jmp end;
        }
        if (attribute == AttributeEnum.ATTACK_HEALTH_FOR_POISON_COUNT) {
            local damage_amount = value * 3;  // todo: replace 3 by nb of poison on target
            local damage = mul_then_div(mul_then_div(damage_amount, s.damage_coef, 100), 100, t.armor_coef);
            tempvar new_pp = clamp(0, t.protection_point - damage, t.protection_point);
            tempvar new_hp;
            if (new_pp == 0) {
                new_hp = clamp(0, t.health_points - (damage - t.protection_point), t.max_health_point);
            } else {
                new_hp = t.health_points;
            }

            [new_target_state] = new_hp;
            [new_target_state + 1] = new_pp;
            [new_target_state + 2] = t.active_effects;
            jmp end;
        }

        assert 0 = 1;  // unknown attribute

        end:
        return (
            new_target=insert_data(HEALTH_POINTS_INDEX, 3, new_target_state, target_len, target)
        );
    }

    func _fill_target_with_selection{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(targets_id_len: felt, targets_id: felt*, target_id: felt, value: felt) {
        if (value == 0) {
            return ();
        }

        [targets_id] = target_id;
        return _fill_target_with_selection(targets_id_len, targets_id + 1, target_id, value - 1);
    }

    func _fill_target_with_random{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        targets_id_len: felt, targets_id: felt*, value: felt
    ) {
        if (value == 0) {
            return ();
        }

        [targets_id] = 0;  // todo: random
        return _fill_target_with_random(targets_id_len, targets_id + 1, value - 1);
    }

    func _fill_target_with_all_enemies{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(targets_id_len: felt, targets_id: felt*, enemy_nb: felt, value: felt) {
        if (enemy_nb == 0) {
            return ();
        }

        _fill_target_with_selection(targets_id_len, targets_id, enemy_nb, value);

        return _fill_target_with_all_enemies(
            targets_id_len, targets_id + value, enemy_nb - 1, value
        );
    }

    func _fill_target_with_player{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        targets_id_len: felt, targets_id: felt*, value: felt
    ) {
        if (value == 0) {
            return ();
        }

        [targets_id] = -1;
        return _fill_target_with_player(targets_id_len, targets_id + 1, value - 1);
    }
}
