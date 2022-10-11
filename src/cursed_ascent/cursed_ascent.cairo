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
from src.player.PlayerBuilder.library import PlayerBuilderLib
from src.card.Card import Card
from src.scene.Scene import Scene
from src.scene.SceneBuilder.library import SceneBuilderLib
from src.scene.SceneState import SceneState
from src.scene.SceneLogic.constants import SceneLogicEvents
from src.scene.SceneLogic.interfaces.ISceneLogic import ISceneLogic
from src.utils.constants import TokenRef
from src.utils.xoshiro128.library import Xoshiro128_ss
from src.action.constants import PackedActionHistory
from src.room.library import RoomLib
from src.room.constants import PackedRooms

const GAME_ID = 'Cursed';

//
// Constructor
//
@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    card_catalog_addr: felt, scene_catalog_addr: felt
) {
    AGameMode.initializer(GAME_ID, card_catalog_addr, scene_catalog_addr);

    return ();
}

// @notice: Start a new game and returns a new GameState. You may want to store this GameState as the root hash on-chain for account
// @param adventurer_ref: the id of the adventurer token
// @return the initialized GameState
@external
func start_new_game{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_ref: TokenRef) -> GameState {
    alloc_locals;

    // Check if session manager already stores a game for caller
    let (caller_address) = get_caller_address();
    let current_game_state = AGameMode.get_saved_game_state(caller_address);
    with_attr error_message(
            "cursed_ascent.start_new_game: There is already a saved game. You should call cursed_ascent.stop_game() before creating a new game...") {
        // assert current_game_state = 0;
    }

    // build a new Player
    let player: Player = PlayerBuilderLib.build_player(adventurer_ref);

    // generate initial card deck
    let (cards_len, cards) = AGameMode.get_available_cards(player.class);
    let (card_deck_len, card_deck) = cursed_ascentLibrary.create_deck(
        player.class, cards_len, cards
    );

    // generate empty SceneState (Player does not start in a scene)
    let scene_state = AGameMode.generate_empty_scene();
    let current_scene_id = -1;

    let rooms = _get_rooms();
    let rooms_paths = 0;  // unused for this game mode
    let floor = 0;

    let (init_seed) = get_block_number();
    let seed: Xoshiro128_ss.XoshiroState = Xoshiro128_ss.init(init_seed);

    let session: Session = Session(
        caller_address,
        player,
        scene_state,
        current_scene_id,
        floor,
        rooms,
        rooms_paths,
        SessionStateEnum.GAME_INITIALIZED,
        seed,
    );

    // save with SessionManager Library
    AGameMode.save_game_state(session, card_deck_len, card_deck);

    return (session, card_deck_len, card_deck);
}

// @notice: Stop on-going game and cleans any existing GameState storage for account
@external
func stop_game{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (caller_address) = get_caller_address();

    AGameMode.erase_game_state(caller_address);
    return ();
}

// @notice: Let a player pick a room when they're on the map
// @param state: the current GameState (session, card_deck_len, card_deck)
// @param room_id: the index of the room picked by the player
// @return the new GameState
@external
func pick_room{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(session: Session, card_deck_len: felt, card_deck: Card*, room_id: felt) -> GameState {
    alloc_locals;

    // check if received GameState is valid
    let (caller_address) = get_caller_address();
    with_attr error_message("cursed_ascent.pick_room: caller is not the owner of this session.") {
        assert caller_address = session.account_addr;
    }
    let is_game_state_valid = AGameMode.check_stored_game_state(session, card_deck_len, card_deck);
    with_attr error_message(
            "cursed_ascent.pick_room: received game state doesn't match with the saved hash. You should start a new game...") {
        assert is_game_state_valid = 1;
    }

    // check if player is not in room
    let session_state = session.current_state;
    if (session_state != SessionStateEnum.GAME_INITIALIZED) {
        if (session_state != SessionStateEnum.GAME_IN_MAP) {
            with_attr error_message(
                    "cursed_ascent.pick_room: Session.current_state must be either SessionStateEnum.GAME_INITIALIZED or SessionStateEnum.GAME_IN_MAP.") {
                assert 0 = 1;
            }
        }
    }

    // check if the room is accessible
    let is_accessible = RoomLib.can_access_next_floor(session.rooms, session.floor, room_id - 1);
    assert is_accessible = 1;

    // Initialize the scene
    let (scenes_len, scenes: Scene*) = get_scene_list();
    let scene = [scenes + (room_id - 1) * Scene.SIZE];
    let scene_state: SceneState = ISceneLogic.initialize_scene(
        scene.logic_contract_addr, session.player
    );

    // Update Session
    let session: Session = Session(
        session.account_addr,
        session.player,
        scene_state,
        room_id - 1,
        session.floor + 1,
        session.rooms,
        session.rooms_paths,
        SessionStateEnum.GAME_IN_ROOM,
        session.seed,
    );

    // save with SessionManager Library
    AGameMode.save_game_state(session, card_deck_len, card_deck);

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
    card_deck: Card*,
    room_id: felt,
    discard_card: felt,
    id: felt,
) -> GameState {
    alloc_locals;

    // check if received GameState is valid
    let (caller_address) = get_caller_address();
    with_attr error_message("cursed_ascent.pick_prize: caller is not the owner of this session.") {
        assert caller_address = session.account_addr;
    }
    let is_game_state_valid = AGameMode.check_stored_game_state(session, card_deck_len, card_deck);
    with_attr error_message(
            "cursed_ascent.pick_prize: received game state doesn't match with the saved hash. You should start a new game...") {
        assert is_game_state_valid = 1;
    }

    // check if we are in a finished scene
    assert session.current_state = SessionStateEnum.GAME_IN_ROOM;
    assert session.scene_state.is_finished = 1;

    let (local new_deck: Card*) = alloc();
    local new_deck_len;
    local seed: Xoshiro128_ss.XoshiroState;

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
            memcpy(new_deck, card_deck, card_deck_len * Card.SIZE);
            // add new card
            // todo: change id of new card
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

    let session: Session = Session(
        session.account_addr,
        session.player,
        session.scene_state,
        session.current_scene_id,
        session.floor,
        session.rooms,
        session.rooms_paths,
        SessionStateEnum.GAME_IN_MAP,
        seed,
    );

    tempvar syscall_ptr = syscall_ptr;
    tempvar pedersen_ptr = pedersen_ptr;
    tempvar range_check_ptr = range_check_ptr;
    tempvar bitwise_ptr = bitwise_ptr;

    // save with SessionManager Library
    AGameMode.save_game_state(session, new_deck_len, new_deck);

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
    card_deck: Card*,
    room_id: felt,
    action_id: felt,
    target_id: felt,
) -> (
    session: Session,
    card_deck_len: felt,
    card_deck: Card*,
    history_len: felt,
    history: PackedActionHistory*,
) {
    alloc_locals;

    // check if received GameState is valid
    let (caller_address) = get_caller_address();
    with_attr error_message("cursed_ascent.next_action: caller is not the owner of this session.") {
        assert caller_address = session.account_addr;
    }
    let is_game_state_valid = AGameMode.check_stored_game_state(session, card_deck_len, card_deck);
    with_attr error_message(
            "cursed_ascent.next_action: received game state doesn't match with the saved hash. You should start a new game...") {
        assert is_game_state_valid = 1;
    }

    // check if we are in an ongoing scene
    assert session.current_state = SessionStateEnum.GAME_IN_ROOM;
    assert session.scene_state.is_finished = 0;
    // todo: if played card is a legendary, turn the drawable boolean to 0
    // turn it back on after the fight

    // get current scene SceneLogic address
    let scene: Scene = AGameMode.get_scene(session.current_scene_id);
    let scene_logic = scene.logic_contract_addr;

    // get player selected card
    let (hand_len, hand, seed) = draw_cards(session, card_deck_len, card_deck);
    let card: Card = [hand + action_id * Card.SIZE];

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

    local new_session_state;
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
        session.floor,
        session.rooms,
        session.rooms_paths,
        new_session_state,
        seed,
    );

    // save with SessionManager Library
    AGameMode.save_game_state(session, card_deck_len, card_deck);

    return (session, card_deck_len, card_deck, history_len, history);
}

//
// Geters
//

@view
func get_saved_game_state{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    player_addr: felt
) -> (game_state_hash: felt) {
    let (caller_address) = get_caller_address();
    let game_state_hash = AGameMode.get_saved_game_state(player_addr);

    return (game_state_hash=game_state_hash);
}

// @notice: Draws random cards from the player's deck
// @param state: the current GameState (session, card_deck_len, card_deck)
// @return hand_len, hand: the hand array lenght, the array of cards drawn
@view
func draw_cards{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(session: Session, card_deck_len: felt, card_deck: Card*) -> (
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
    let id = [hand_ids];
    let card: Card = [card_deck + id * Card.SIZE];
    assert [hand] = card;
    let id = [hand_ids + 1];
    let card: Card = [card_deck + id * Card.SIZE];
    assert [hand + Card.SIZE] = card;
    let id = [hand_ids + 2];
    let card: Card = [card_deck + id * Card.SIZE];
    assert [hand + Card.SIZE * 2] = card;

    return (3, hand, seed);
}

// @notice: Generate prizes for a scene completion
// @param state: the current GameState (session, card_deck_len, card_deck)
// @return prizes: the id of the available cards as prizes (id of available_cards)
@view
func get_prizes{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(session: Session, card_deck_len: felt, card_deck: Card*) -> (
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

// @notice: get all scenes available in the game mode
// @returns the scene list and its length
@view
func get_scene_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    scene_list_len: felt, scene_list: Scene*
) {
    alloc_locals;

    let (local scene_list: Scene*) = alloc();
    let scene = AGameMode.get_scene(0);
    assert [scene_list] = scene;

    return (1, scene_list);
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

    let seed = _draw_cards(card_deck_len, card_ids_len - 1, card_ids + 1, seed);

    let (seed, rnd) = Xoshiro128_ss.next_unique(
        seed, card_ids_len - 1, card_ids + 1, card_deck_len
    );
    let (_, id) = unsigned_div_rem(rnd, card_deck_len);
    assert [card_ids] = id;

    return seed;
}

// static room generation
func _get_rooms{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() -> PackedRooms {
    let floor1 = 1;
    let floor_nb = 1;

    // todo: write a generic function for packing rooms
    let packed_rooms: PackedRooms = floor1 + (floor_nb * 2 ** 240);

    return packed_rooms;
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
