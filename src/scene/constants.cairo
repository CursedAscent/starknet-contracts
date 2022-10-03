%lang starknet

namespace SceneTypeEnum {
    const FIGHT = 0x1;
    const ELITE_FIGHT = 0x2;
    const BOSS_FIGHT = 0x3;
    const BONFIRE = 0x4;
}

// On-chain data (used by constructor)
struct SceneData {
    logic_contract_addr: felt,
}
