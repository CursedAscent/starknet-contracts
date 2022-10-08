// Interface for GameMode contracts
// These contracts are the core contracts of any game mode compatible with Cursed Ascent

%lang starknet

from src.gamemode.constants import GameState
from src.utils.constants import TokenRef

@contract_interface
namespace IGameMode {
    // @notice: Start a new game and returns a new GameState. You may want to store this GameState as the root hash on-chain for account
    // @param adventurer_ref: the id of the adventurer token
    // @return state: the initialized GameState
    func start_new_game(adventurer_ref: TokenRef) -> (state: GameState) {
    }

    // @notice: Stop on-going game and cleans any existing GameStorage storage for account
    func stop_game() {
    }

    // @notice: Let a player pick a room when they're on the map
    // @param state: the current GameState
    // @param room_id: the index of the room picked by the player
    // @return state: the new GameState
    func pick_room(state: GameState, room_id: felt) -> (state: GameState) {
    }

    // @notice: Let a player pick a prize after they won a fight
    // @param state: the current GameState
    // @param discard_card: indicates if a player picked to discard a card rather than take a prize
    // @param id: the id of the prize if discard_card is false, the id in the deck of the card to discard if discard_card is true
    // @return state: the new GameState
    func pick_prize(state: GameState, discard_card: felt, id: felt) -> (state: GameState) {
    }

    // @notice: Called by a player when they are in a room
    // @param state: the current GameState
    // @param action_id: id of the action entity selected by the player. Entity is a card when in a fight room
    // @param target_id: id of the target picked by the player. Only has effect if the selected entity is compatible with picked target
    // @return state: the new GameState
    func next_action(state: GameState, action_id: felt, target_id: felt) -> (state: GameState) {
    }

    // @notice: Saves a new GameState in storage
    // @param cur_state: the current saved GameState available in storage
    // @param new_state: the new GameState to save in storage
    // @return state: the saved GameState
    func save_state(cur_state: GameState, new_state: GameState) -> (state: GameState) {
    }

    // @notice: Draws random cards from the player's deck
    // @param state: the current GameState
    // @return hand_len, hand: the hand array lenght, the array of cards drawn
    func draw_cards(state: GameState) -> (hand_len: felt, hand: Card*) {
    }
}
