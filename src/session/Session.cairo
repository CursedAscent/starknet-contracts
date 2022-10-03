%lang starknet

from src.player.Player import Player
from src.session.constants import SessionStateEnum

// Session entity used to keep context of a player's game session
struct Session {
    account_addr: felt,
    player: Player,
    cards_available_len: felt,
    cards_available: Card*,  // Immutable, all card available for gamemode
    player_deck_len: felt,
    player_deck: Card*,
    prizes_len: felt,
    prizes: Card*,
    scene_session: SceneState,
    scenes_len: felt,
    scenes: Scene*,
    current_scene_id: felt,
    rooms: felt,  // Immutable, all rooms computed at gamemode init
    rooms_paths: felt,  // Immutable, all rooms edges computed at gamemode init
    current_state: SessionStateEnum,
    seed: felt,  // PRNG seed
}
