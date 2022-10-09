%lang starknet

from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_lt
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.memcpy import memcpy

from src.gamemode.AGameMode import AGameMode
from src.cursed_ascent.library import cursed_ascentLibrary
from src.gamemode.constants import GameState
from src.session.Session import Session
from src.session.constants import SessionStateEnum
from src.player.Player import Player
from src.card.Card import Card
from src.scene.Scene import Scene
from src.scene.SceneState import SceneState
from src.scene.SceneLogic.constants import SceneLogicEvents
from src.scene.SceneLogic.interfaces.ISceneLogic import ISceneLogic
from src.utils.constants import TokenRef
from src.action.constants import PackedActionHistory

// @notice: Start a new game and returns a new GameState. You may want to store this GameState as the root hash on-chain for account
// @param adventurer_ref: the id of the adventurer token
// @return the initialized GameState
@external
func start_new_game{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    adventurer_ref: TokenRef
) -> GameState {
    alloc_locals;

    // Check if session manager already store a game for caller
    let (caller_address) = get_caller_address();
    // todo ^

    // build a new Player
    // adventurer_ref.token_id is used as a AdventurerClassEnum
    // todo: should be from the PlayerBuilder library
    let player: Player = cursed_ascentLibrary.build_new_player(adventurer_ref.token_id);

    // generate initial card deck
    let (cards_len, cards) = AGameMode.get_available_cards(player.class);
    let (local card_deck_len, local card_deck) = cursed_ascentLibrary.create_deck(
        player.class, cards_len, cards
    );

    // generate empty SceneState (Player does not start in a scene)
    let scene_state = AGameMode.generate_empty_scene();
    let current_scene_id = -1;

    // todo: rooms library
    let rooms = 0;
    let rooms_paths = 0;

    // todo: PRNG seed
    let seed = 0;

    let session: Session = Session(
        caller_address,
        player,
        scene_state,
        current_scene_id,
        rooms,
        rooms_paths,
        SessionStateEnum.GAME_INITIALIZED,
        seed,
    );

    // todo: save with SessionManager Library

    return (session, card_deck_len, card_deck);
}

// @notice: Stop on-going game and cleans any existing GameState storage for account
@external
func stop_game{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    // todo: SessionManager Library
    return ();
}

// @notice: Let a player pick a room when they're on the map
// @param state: the current GameState (session, card_deck_len, card_deck)
// @param room_id: the index of the room picked by the player
// @return the new GameState
@external
func pick_room{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    session: Session, card_deck_len: felt, card_deck: felt*, room_id: felt
) -> GameState {
    // todo: rooms library

    // check if selected room is connected to actual room (session.current_scene_id)

    // update session

    // save with SessionManager Library

    return (session, card_deck_len, card_deck);
}

// @notice: Let a player pick a prize after they won a fight
// @param state: the current GameState (session, card_deck_len, card_deck)
// @param room_id: the index of the current room
// @param discard_card: indicates if a player picked to discard a card rather than take a prize
// @param id: the id of the prize if discard_card is false, the id in the deck of the card to discard if discard_card is true
// @return state: the new GameState
@external
func pick_prize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    session: Session,
    card_deck_len: felt,
    card_deck: felt*,
    room_id: felt,
    discard_card: felt,
    id: felt,
) -> GameState {
    alloc_locals;
    assert session.current_state = SessionStateEnum.GAME_IN_ROOM;
    assert session.scene_state.is_finished = 1;

    let (local new_deck) = alloc();
    tempvar new_deck_len;
    tempvar seed;

    if (session.scene_state.current_event != SceneLogicEvents.OUTRO) {
        // This is not the classic OUTRO event from SceneLogic, so no rewards
        let (cards_len, cards) = AGameMode.get_available_cards(session.player.class);
        memcpy(new_deck, cards, cards_len * Card.SIZE);

        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        // classic OUTRO event, we have a reward
        if (discard_card == 0) {
            // add a card
            let (cards_len, cards) = AGameMode.get_available_cards(session.player.class);

            // todo: generate prizes based on seed
            let (prizes_len: felt, prizes: felt*, new_seed: felt) = get_prizes(
                session, card_deck_len, card_deck
            );
            assert_lt(id, prizes_len);
            let selected_card_id = [prizes + id];

            // copy previous deck
            memcpy(new_deck, card_deck, card_deck_len);
            // add new card
            memcpy(new_deck + card_deck_len, cards + Card.SIZE * selected_card_id, Card.SIZE);
            new_deck_len = card_deck_len + 1;

            seed = new_seed;

            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            // discard a card
            assert_lt(id, card_deck_len);

            memcpy(new_deck, card_deck, id * Card.SIZE);
            memcpy(
                new_deck + id * Card.SIZE,
                card_deck + (id + 1) * Card.SIZE,
                card_deck_len - (id + 1),
            );
            new_deck_len = card_deck_len - 1;

            seed = session.seed;

            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }
    }

    // todo: change session.current_state to GAME_IN_MAP
    let session: Session = Session(
        session.account_addr,
        session.player,
        session.scene_state,
        session.current_scene_id,
        session.rooms,
        session.rooms_paths,
        SessionStateEnum.GAME_IN_MAP,
        seed,
    );

    return (session, new_deck_len, new_deck);
}

// @notice: Called by a player when they are in a room
// @param state: the current GameState (session, card_deck_len, card_deck)
// @param room_id: the index of the current room
// @param action_id: id of the action entity selected by the player. Entity is a card when in a fight room
// @param target_id: id of the target picked by the player. Only has effect if the selected entity is compatible with picked target
// @return state: the new GameState
@external
func next_action{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(
    session: Session,
    card_deck_len: felt,
    card_deck: felt*,
    room_id: felt,
    action_id: felt,
    target_id: felt,
) -> (
    session: Session,
    card_deck_len: felt,
    card_deck: felt*,
    history_len: felt,
    history: PackedActionHistory*,
) {
    alloc_locals;
    assert session.current_state = SessionStateEnum.GAME_IN_ROOM;
    // todo: if played card is a legendary, turn the drawable boolean to 0
    // turn it back on after the fight

    // get current scene SceneLogic address
    let scene: Scene = AGameMode.get_scene(session.current_scene_id);
    let scene_logic = scene.logic_contract_addr;

    // get player selected card
    let (hand_len: felt, hand: Card*, seed: felt) = draw_cards(session, card_deck_len, card_deck);
    let card: Card = [hand + action_id];

    // compute new state
    let (
        scene_state: SceneState,
        player: Player,
        history_len: felt,
        history: PackedActionHistory*,
        seed: felt,
    ) = ISceneLogic.next_step(
        scene_logic, session.scene_state, seed, session.player, card.action, target_id
    );

    tempvar new_session_state;
    if (scene_state.current_event == SceneLogicEvents.PLAYER_DEAD) {
        assert scene_state.is_finished = 1;
        new_session_state = SessionStateEnum.GAME_LOST;
    } else {
        new_session_state = session.current_state;
    }

    let session: Session = Session(
        session.account_addr,
        player,
        scene_state,
        session.current_scene_id,
        session.rooms,
        session.rooms_paths,
        new_session_state,
        seed,
    );

    return (session, card_deck_len, card_deck, history_len, history);
}

//
// Geters
//

// @notice: Draws random cards from the player's deck
// @param state: the current GameState (session, card_deck_len, card_deck)
// @return hand_len, hand: the hand array lenght, the array of cards drawn
@view
func draw_cards{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    session: Session, card_deck_len: felt, card_deck: felt*
) -> (hand_len: felt, hand: Card*, seed: felt) {
    alloc_locals;
    // todo: apply active_effects.draw_more_cards and active_effects.draw_less_cards
    let (local hand: Card*) = alloc();
    let seed = session.seed;

    // generate cards id randomly with seed

    // fill hand variable

    return (0, hand, seed);
}

// @notice: Generate prizes for a scene completion
// @param state: the current GameState (session, card_deck_len, card_deck)
// @return prizes: the id of the available cards as prizes (id of available_cards)
@view
func get_prizes{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    session: Session, card_deck_len: felt, card_deck: felt*
) -> (prizes_len: felt, prizes: felt*, seed: felt) {
    alloc_locals;
    let (local prizes: felt*) = alloc();
    let seed = session.seed;

    // generate cards ids randomly with seed

    // fill prizes variable

    return (0, prizes, seed);
}

// @notice: get all available cards for a given class
// @param class: the class identifier (AdventurerClassEnum)
// @rturn cards_len, cards: the list of the available cards
@view
func get_available_cards{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    class: felt
) -> (cards_len: felt, cards: Card*) {
    return AGameMode.get_available_cards(class);
}

//
// Internals
//

// // @notice: Saves a new GameState in storage
// // @param cur_state: the current saved GameState available in storage (session, card_deck_len, card_deck)
// // @param new_state: the new GameState to save in storage (session, card_deck_len, card_deck)
// // @return state: the saved GameState
// func _save_state{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
//     curr_session: Session,
//     curr_card_deck_len: felt,
//     curr_card_deck: felt*,
//     new_session: Session,
//     new_card_deck_len: felt,
//     new_card_deck: felt*,
// ) -> GameState {
// }
