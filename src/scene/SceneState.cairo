%lang starknet

from src.utils.constants import TokenRef
from src.enemy.Enemy import Enemy

// SceneState entity to keep a scene's context
struct SceneState {
    enemies_len: felt,
    enemies: (Enemy, Enemy, Enemy, Enemy, Enemy, Enemy, Enemy, Enemy),
    current_event: felt,  // ID of scene event (desc in nft metadata)
    is_finished: felt,  // 0 is false, 1 is true
}
