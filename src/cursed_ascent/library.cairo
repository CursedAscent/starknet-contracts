%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.registers import get_fp_and_pc

from src.player.Player import Player
from src.player.constants import AdventurerClassEnum
from src.card.Card import Card
from src.utils.constants import TokenRef
from src.utils.data_manipulation import inplace_insert_data

namespace cursed_ascentLibrary {
    //
    // Constructors
    //

    func create_deck{syscall_ptr: felt*, range_check_ptr}(
        adventurer_class: felt, cards_len: felt, cards: Card*
    ) -> (card_deck_len: felt, card_deck: Card*) {
        if (adventurer_class == AdventurerClassEnum.WARRIOR) {
            return _create_warrior_deck(cards_len, cards);
        }
        if (adventurer_class == AdventurerClassEnum.HUNTER) {
            return _create_hunter_deck(cards_len, cards);
        }
        if (adventurer_class == AdventurerClassEnum.LIGHT_MAGE) {
            return _create_light_mage_deck(cards_len, cards);
        }
        if (adventurer_class == AdventurerClassEnum.DARK_MAGE) {
            return _create_dark_mage_deck(cards_len, cards);
        }

        with_attr error_message("cursed_ascentLibrary.create_deck: unknown adventurer class.") {
            assert 1 = 0;
        }
        return (0, cast(0, Card*));
    }

    //
    // Internals
    //

    func _empty_player() -> Player {
        let player_ref = TokenRef(0, 0);
        let player = Player(0, 0, 0, 0, 0, 0, 0, player_ref, 0, 0);

        return player;
    }

    func _create_warrior_deck{syscall_ptr: felt*, range_check_ptr}(
        cards_len: felt, cards: Card*
    ) -> (card_deck_len: felt, card_deck: Card*) {
        alloc_locals;
        let (__fp__, _) = get_fp_and_pc();
        assert cards_len = 13;

        // todo: check if these match the wanted cards (may be not doable)
        let smash = [cards];
        let defend = [cards + Card.SIZE];
        let warrior_stance = [cards + Card.SIZE * 2];

        let (local card_deck: Card*) = alloc();
        local indices: (felt, felt, felt, felt, felt) = (0, 1, 2, 3, 4);
        inplace_insert_data(Card.id, 1, &indices, Card.SIZE, &smash, card_deck);
        inplace_insert_data(Card.id, 1, &indices + 1, Card.SIZE, &smash, card_deck + Card.SIZE);
        inplace_insert_data(
            Card.id, 1, &indices + 2, Card.SIZE, &defend, card_deck + Card.SIZE * 2
        );
        inplace_insert_data(
            Card.id, 1, &indices + 3, Card.SIZE, &defend, card_deck + Card.SIZE * 3
        );
        inplace_insert_data(
            Card.id, 1, &indices + 4, Card.SIZE, &warrior_stance, card_deck + Card.SIZE * 4
        );

        return (5, card_deck);
    }

    func _create_hunter_deck{syscall_ptr: felt*, range_check_ptr}(
        cards_len: felt, cards: Card*
    ) -> (card_deck_len: felt, card_deck: Card*) {
        alloc_locals;
        let (__fp__, _) = get_fp_and_pc();
        assert cards_len = 13;

        // todo: check if these match the wanted cards (may be not doable)
        let slash = [cards];
        let dodge = [cards + Card.SIZE];
        let stab = [cards + Card.SIZE * 2];

        let (local card_deck: Card*) = alloc();
        local indices: (felt, felt, felt, felt, felt) = (0, 1, 2, 3, 4);
        inplace_insert_data(Card.id, 1, &indices, Card.SIZE, &slash, card_deck);
        inplace_insert_data(Card.id, 1, &indices + 1, Card.SIZE, &slash, card_deck + Card.SIZE);
        inplace_insert_data(Card.id, 1, &indices + 2, Card.SIZE, &dodge, card_deck + Card.SIZE * 2);
        inplace_insert_data(Card.id, 1, &indices + 3, Card.SIZE, &dodge, card_deck + Card.SIZE * 3);
        inplace_insert_data(Card.id, 1, &indices + 4, Card.SIZE, &stab, card_deck + Card.SIZE * 4);

        return (5, card_deck);
    }

    func _create_light_mage_deck{syscall_ptr: felt*, range_check_ptr}(
        cards_len: felt, cards: Card*
    ) -> (card_deck_len: felt, card_deck: Card*) {
        alloc_locals;
        let (__fp__, _) = get_fp_and_pc();
        assert cards_len = 13;

        // todo: check if these match the wanted cards (may be not doable)
        let light_beam = [cards];
        let barrier_of_light = [cards + Card.SIZE];
        let divine_halo = [cards + Card.SIZE * 2];

        let (local card_deck: Card*) = alloc();
        local indices: (felt, felt, felt, felt, felt) = (0, 1, 2, 3, 4);
        inplace_insert_data(Card.id, 1, &indices, Card.SIZE, &light_beam, card_deck);
        inplace_insert_data(
            Card.id, 1, &indices + 1, Card.SIZE, &light_beam, card_deck + Card.SIZE
        );
        inplace_insert_data(
            Card.id, 1, &indices + 2, Card.SIZE, &barrier_of_light, card_deck + Card.SIZE * 2
        );
        inplace_insert_data(
            Card.id, 1, &indices + 3, Card.SIZE, &barrier_of_light, card_deck + Card.SIZE * 3
        );
        inplace_insert_data(
            Card.id, 1, &indices + 4, Card.SIZE, &divine_halo, card_deck + Card.SIZE * 4
        );

        return (5, card_deck);
    }

    func _create_dark_mage_deck{syscall_ptr: felt*, range_check_ptr}(
        cards_len: felt, cards: Card*
    ) -> (card_deck_len: felt, card_deck: Card*) {
        alloc_locals;
        let (__fp__, _) = get_fp_and_pc();
        assert cards_len = 13;

        // todo: check if these match the wanted cards (may be not doable)
        let soul_burn = [cards];
        let shadow_veil = [cards + Card.SIZE];
        let pestilence = [cards + Card.SIZE * 2];

        let (local card_deck: Card*) = alloc();
        local indices: (felt, felt, felt, felt, felt) = (0, 1, 2, 3, 4);
        inplace_insert_data(Card.id, 1, &indices, Card.SIZE, &soul_burn, card_deck);
        inplace_insert_data(Card.id, 1, &indices + 1, Card.SIZE, &soul_burn, card_deck + Card.SIZE);
        inplace_insert_data(
            Card.id, 1, &indices + 2, Card.SIZE, &shadow_veil, card_deck + Card.SIZE * 2
        );
        inplace_insert_data(
            Card.id, 1, &indices + 3, Card.SIZE, &shadow_veil, card_deck + Card.SIZE * 3
        );
        inplace_insert_data(
            Card.id, 1, &indices + 4, Card.SIZE, &pestilence, card_deck + Card.SIZE * 4
        );

        return (5, card_deck);
    }
}
