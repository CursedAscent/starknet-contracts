// Interface for GameMode contracts
// These contracts are the core contracts of any game mode compatible with Cursed Ascent

%lang starknet

from src.gamemode.constants import GameState
from src.utils.constants import TokenRef
from src.session.Session import Session
from src.action.constants import PackedActionHistory
from src.card.Card import Card

@contract_interface
namespace IGameMode {
    // @notice: Start a new game and returns a new GameState. You may want to store this GameState as the root hash on-chain for account
    // @param adventurer_ref: the id of the adventurer token
    // @return the initialized GameState
    func start_new_game(adventurer_ref: TokenRef) -> GameState {
    }

    // @notice: Stop on-going game and cleans any existing GameState storage for account
    func stop_game() {
    }

    // @notice: Let a player pick a room when they're on the map
    // @param state: the current GameState (session, card_deck_len, card_deck)
    // @param room_id: the index of the room picked by the player
    // @return the new GameState
    func pick_room(
        session: Session, card_deck_len: felt, card_deck: felt*, room_id: felt
    ) -> GameState {
    }

    // @notice: Let a player pick a prize after they won a fight
    // @param state: the current GameState (session, card_deck_len, card_deck)
    // @param room_id: the index of the current room
    // @param discard_card: indicates if a player picked to discard a card rather than take a prize
    // @param id: the id of the prize if discard_card is false, the id in the deck of the card to discard if discard_card is true
    // @return state: the new GameState
    func pick_prize(
        session: Session,
        card_deck_len: felt,
        card_deck: felt*,
        room_id: felt,
        discard_card: felt,
        id: felt,
    ) -> GameState {
    }

    // @notice: Called by a player when they are in a room
    // @param state: the current GameState (session, card_deck_len, card_deck)
    // @param room_id: the index of the current room
    // @param action_id: id of the action entity selected by the player. Entity is a card when in a fight room
    // @param target_id: id of the target picked by the player. Only has effect if the selected entity is compatible with picked target
    // @return state: the new GameState
    func next_action(
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
    }

    // @notice: Saves a new GameState in storage
    // @param cur_state: the current saved GameState available in storage (session, card_deck_len, card_deck)
    // @param new_state: the new GameState to save in storage (session, card_deck_len, card_deck)
    // @return state: the saved GameState
    // func save_state(
    //     curr_session: Session,
    //     curr_card_deck_len: felt,
    //     curr_card_deck: felt*,
    //     new_session: Session,
    //     new_card_deck_len: felt,
    //     new_card_deck: felt*,
    // ) -> GameState {
    // }

    //
    // Getters
    //

    // @notice: Draws random cards from the player's deck
    // @param state: the current GameState (session, card_deck_len, card_deck)
    // @return hand_len, hand: the hand array lenght, the array of cards drawn
    func draw_cards(session: Session, card_deck_len: felt, card_deck: felt*) -> (
        hand_len: felt, hand: Card*
    ) {
    }

    // @notice: Generate prizes for a scene completion
    // @param state: the current GameState (session, card_deck_len, card_deck)
    // @return prizes: the id of the available cards as prizes (id of available_cards)
    func get_prizes(session: Session, card_deck_len: felt, card_deck: felt*) -> (
        prizes_len: felt, prizes: felt*
    ) {
    }

    // @notice: get all available cards for a given class
    // @param class: the class identifier (AdventurerClassEnum)
    // @rturn cards_len, cards: the list of the available cards
    func get_available_cards(class: felt) -> (cards_len: felt, cards: Card*) {
    }
}
