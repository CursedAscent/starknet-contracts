%lang starknet

from src.utils.constants import TokenRef

// Scene entity
struct Scene {
    scene_ref: TokenRef,
    scene_type: felt, // SceneTypeEnum
    logic_contract_addr: felt,
}
