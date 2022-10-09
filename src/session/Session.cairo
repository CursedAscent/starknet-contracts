%lang starknet

from src.player.Player import Player
from src.card.Card import Card
from src.scene.SceneState import SceneState
from src.scene.Scene import Scene
from src.utils.xoshiro128.library import Xoshiro128_ss

// Session entity used to keep context of a player's game session
struct Session {
    account_addr: felt,
    player: Player,
    // cards_available_len: felt, immutable, comes with cards_available
    // cards_available: Card*,  // Immutable, all card available for gamemode
    // player_deck_len: felt, // Provided as part of Session tuple (Session, felt, Card*)
    // player_deck: Card*, // Provided as part of Session tuple (Session, felt, Card*)
    // prizes_len: felt,
    // prizes: Card*, // Generated on the fly based on seed
    // hand_len: felt,
    // hand: Card*, // Generated on the fly based on seed
    scene_state: SceneState,
    // scenes_len: felt,
    // scenes: Scene*, // Immutable, scenes[room_1] == Scene.logic_contract_addr
    current_scene_id: felt,
    floor: felt,
    rooms: felt,  // Initializable, all rooms computed at gamemode init
    rooms_paths: felt,  // Initializable, all rooms edges computed at gamemode init
    current_state: felt,  // SessionStateEnum
    seed: Xoshiro128_ss.XoshiroState,  // PRNG seed
}
