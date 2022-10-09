// Helper functions to create a Player from an Adventurer

%lang starknet

from starkware.cairo.common.math import assert_le_felt, assert_not_zero

from src.player.Player import Player
from src.player.constants import AdventurerClassEnum
from src.utils.constants import TokenRef
from contracts.loot.adventurer.library import AdventurerLib
from contracts.loot.constants.adventurer import AdventurerState

namespace PlayerBuilderLib {

    func _build_tutorial_warrior{syscall_ptr: felt*, range_check_ptr}() -> (player: Player) {
        alloc_locals;
        let (local warrior: AdventurerState) = AdventurerLib.birth(0, 0, 'Warrior', 0, 0);

        return (player=Player(100, 120, 100, warrior.Health, warrior.Health, 0, 0, TokenRef(0, AdventurerClassEnum.WARRIOR), 0, 0));
    }

    func _build_tutorial_hunter{syscall_ptr: felt*, range_check_ptr}() -> (player: Player) {
        alloc_locals;
        let (local warrior: AdventurerState) = AdventurerLib.birth(0, 0, 'Warrior', 0, 0);

        return (player=Player(0, 0, 0, 0, 0, 0, 0, TokenRef(0, AdventurerClassEnum.HUNTER), 0, 0));
    }

    func _build_tutorial_lightmage{syscall_ptr: felt*, range_check_ptr}() -> (player: Player) {
        alloc_locals;
        let (local warrior: AdventurerState) = AdventurerLib.birth(0, 0, 'Warrior', 0, 0);

        return (player=Player(0, 0, 0, 0, 0, 0, 0, TokenRef(0, AdventurerClassEnum.LIGHT_MAGE), 0, 0));
    }

    func _build_tutorial_darkmage{syscall_ptr: felt*, range_check_ptr}() -> (player: Player) {
        alloc_locals;
        let (local warrior: AdventurerState) = AdventurerLib.birth(0, 0, 'Warrior', 0, 0);

        return (player=Player(0, 0, 0, 0, 0, 0, 0, TokenRef(0, AdventurerClassEnum.DARK_MAGE), 0, 0));
    }

    func _build_tutorial_player{syscall_ptr: felt*, range_check_ptr}(adventurer_id: felt) -> (player: Player) {
        if (adventurer_id == AdventurerClassEnum.WARRIOR) {
            return _build_tutorial_warrior();
        }
        if (adventurer_id == AdventurerClassEnum.HUNTER) {
            return _build_tutorial_hunter();
        }
        if (adventurer_id == AdventurerClassEnum.LIGHT_MAGE) {
            return _build_tutorial_lightmage();
        }
        if (adventurer_id == AdventurerClassEnum.DARK_MAGE) {
            return _build_tutorial_darkmage();
        }

        return (player=Player(0, 0, 0, 0, 0, 0, 0, TokenRef(0, adventurer_id), 0, 0));
    }

    func build_player{syscall_ptr: felt*, range_check_ptr}(adventurer_ref: TokenRef) -> (player: Player) {
        assert adventurer_ref.collection_addr = 0;
        assert_not_zero(adventurer_ref.token_id);
        assert_le_felt(adventurer_ref.token_id, AdventurerClassEnum.DARK_MAGE);

        return _build_tutorial_player(adventurer_ref.token_id);
    }
}