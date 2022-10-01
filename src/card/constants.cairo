%lang starknet

// Rarities
namespace RarityTypeEnum {
    const COMMON = 0x1;
    const RARE = 0x2;
    const LEGENDARY = 0x3;
}

// On-chain data (used by constructor)
struct CardData {
    action: felt,
    class: felt,
    rarity: felt,
}
