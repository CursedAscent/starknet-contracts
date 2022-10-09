%lang starknet

from starkware.starknet.common.syscalls import get_caller_address, get_block_number
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_lt, unsigned_div_rem
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
from src.utils.xoshiro128.library import Xoshiro128_ss
from src.action.constants import PackedActionHistory

// @notice: Start a new game and returns a new GameState. You may want to store this GameState as the root hash on-chain for account
// @param adventurer_ref: the id of the adventurer token
// @return the initialized GameState
@external
func start_new_game{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_ref: TokenRef) -> GameState {
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

    let (init_seed) = get_block_number();
    let seed: Xoshiro128_ss.XoshiroState = Xoshiro128_ss.init(init_seed);

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
func pick_prize{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(
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
    tempvar seed: Xoshiro128_ss.XoshiroState;

    if (session.scene_state.current_event != SceneLogicEvents.OUTRO) {
        // This is not the classic OUTRO event from SceneLogic, so no rewards
        let (cards_len, cards) = AGameMode.get_available_cards(session.player.class);
        memcpy(new_deck, cards, cards_len * Card.SIZE);

        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar bitwise_ptr = bitwise_ptr;
    } else {
        // classic OUTRO event, we have a reward
        if (discard_card == 0) {
            // add a card
            let (cards_len, cards) = AGameMode.get_available_cards(session.player.class);
            let (prizes_len, prizes, new_seed) = get_prizes(session, card_deck_len, card_deck);
            assert_lt(id, prizes_len);
            let selected_card_id = [prizes + id];

            // copy previous deck
            memcpy(new_deck, card_deck, card_deck_len);
            // add new card
            memcpy(new_deck + card_deck_len, cards + Card.SIZE * selected_card_id, Card.SIZE);
            new_deck_len = card_deck_len + 1;

            assert seed = new_seed;

            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
            tempvar bitwise_ptr = bitwise_ptr;
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

            assert seed = session.seed;

            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
            tempvar bitwise_ptr = bitwise_ptr;
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
    let (hand_len, hand, seed) = draw_cards(session, card_deck_len, card_deck);
    let card: Card = [hand + action_id];

    // compute new state
    let (
        scene_state: SceneState,
        player: Player,
        history_len: felt,
        history: PackedActionHistory*,
        seed: Xoshiro128_ss.XoshiroState,
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
func draw_cards{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(session: Session, card_deck_len: felt, card_deck: felt*) -> (
    hand_len: felt, hand: Card*, seed: Xoshiro128_ss.XoshiroState
) {
    alloc_locals;
    // todo: apply active_effects.draw_more_cards and active_effects.draw_less_cards
    let (local hand_ids: felt*) = alloc();
    let (local hand: Card*) = alloc();
    let seed = session.seed;

    // generate cards id randomly with seed
    let seed = _draw_cards(card_deck_len, 3, hand_ids, seed);

    // fill hand variable
    let card: Card = AGameMode.get_available_card(session.player.class, [hand_ids]);
    assert [hand] = card;
    let card: Card = AGameMode.get_available_card(session.player.class, [hand_ids + 1]);
    assert [hand + Card.SIZE] = card;
    let card: Card = AGameMode.get_available_card(session.player.class, [hand_ids + 2]);
    assert [hand + Card.SIZE * 2] = card;

    return (3, hand, seed);
}

// @notice: Generate prizes for a scene completion
// @param state: the current GameState (session, card_deck_len, card_deck)
// @return prizes: the id of the available cards as prizes (id of available_cards)
@view
func get_prizes{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(session: Session, card_deck_len: felt, card_deck: felt*) -> (
    prizes_len: felt, prizes: felt*, seed: Xoshiro128_ss.XoshiroState
) {
    alloc_locals;
    let (local prizes: felt*) = alloc();
    let seed = session.seed;

    // todo: toggle legendary drop? (boolean in parameter for example)

    // generate cards ids randomly with seed
    let (seed, rnd) = Xoshiro128_ss.next(seed);
    let (_, id) = unsigned_div_rem(rnd, 10);  // 10 available cards, + 3 to skip starting cards
    assert [prizes] = id + 3;

    let (seed, rnd) = Xoshiro128_ss.next(seed);
    let (_, id) = unsigned_div_rem(rnd, 10);  // 10 available cards, + 3 to skip starting cards
    assert [prizes + 1] = id + 3;

    let (seed, rnd) = Xoshiro128_ss.next(seed);
    let (_, id) = unsigned_div_rem(rnd, 10);  // 10 available cards, + 3 to skip starting cards
    assert [prizes + 2] = id + 3;

    return (3, prizes, seed);
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

func _draw_cards{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(
    card_deck_len: felt, card_ids_len: felt, card_ids: felt*, seed: Xoshiro128_ss.XoshiroState
) -> Xoshiro128_ss.XoshiroState {
    if (card_ids_len == 0) {
        return seed;
    }

    let (seed, rnd) = Xoshiro128_ss.next_unique(
        seed, card_ids_len - 1, card_ids + 1, card_deck_len
    );
    let (_, id) = unsigned_div_rem(rnd, card_deck_len);
    [card_ids] = id;

    return _draw_cards(card_deck_len, card_ids_len - 1, card_ids + 1, seed);
}

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
