%lang starknet

from src.utils.constants import TokenRef
from src.enemy.Enemy import Enemy

using EnemyList = (Enemy, Enemy, Enemy, Enemy, Enemy, Enemy, Enemy, Enemy);

// SceneState entity to keep a scene's context
struct SceneState {
    enemies_len: felt,
    enemies: EnemyList,
    current_event: felt,  // SceneLogicEvents (desc in nft metadata)
    is_finished: felt,  // 0 is false, 1 is true
}
