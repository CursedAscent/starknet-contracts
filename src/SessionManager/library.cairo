// Definition of the SessionManager Library, that allow one to hash and compare the game state.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.hash_chain import hash_chain
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.alloc import alloc

from src.gamemode.constants import GameState
from src.session.Session import Session
from src.card.Card import Card

namespace SessionManagerLib {
    func hash_state{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        session: Session, card_deck_len: felt, card_deck: Card*
    ) -> felt {
        alloc_locals;
        let (__fp__, _) = get_fp_and_pc();
        let (local flattened_game_state) = alloc();

        // cpy session
        memcpy(flattened_game_state + 1, &session, Session.SIZE);

        // cpy card_deck_len
        assert [flattened_game_state + 1 + Session.SIZE] = card_deck_len;
        // cpy card_deck
        memcpy(flattened_game_state + 1 + Session.SIZE + 1, card_deck, card_deck_len * Card.SIZE);
        let flattened_game_state_len = Session.SIZE + 1 + card_deck_len * Card.SIZE;

        // add data len at the beginning
        assert [flattened_game_state] = flattened_game_state_len;

        let (hash) = hash_chain{hash_ptr=pedersen_ptr}(flattened_game_state);

        return hash;
    }
}
