// Data descriptions relative to actions made by Card & Enemy entities.

%lang starknet

// Description of an action in the game.
// Due to Cairo limitation, we decided to store this data packed in one felt.
struct Attributes {
    attr1: felt,  // short string
    value1: felt,
    attr2: felt,  // short string
    value2: felt,
    attr3: felt,  // short string
    value3: felt,
    target: felt,  // short string
    target_value: felt,
}

// typename PackedAttribute = felt;

// Description of the possible values in Attribute.attr & Attribute.target.
namespace AttributesEnum {
    // offensive actions
    const DIRECT_HIT = 'DH';
    const ATTACK_HEALTH = 'AH';
    const BLEEDING_STACKS = 'BS';
    const POISON_STACKS = 'PS';
    const PASSIVE_ATTACK = 'PA';

    // defensive actions
    const PROTECTION_POINT = 'PP';
    const HEALTH_POINT = 'HP';
    const ADD_ARMOR = 'AA';

    // Debuffs
    const WEAKEN_DEFENSE = 'WD';
    const WEAKEN_ATTACK = 'WA';
    const WEAKEN_PROTECTION = 'WP';

    // Powers
    const PERMANENT_PROTECTION = 'PPS';
    const REPEAT_DIRECT_HIT = 'RDH';

    // Targets
    const PLAYER_SELECTION = 'TS';
    const RANDOM_TARGET = 'TR';
    const ALL_TARGET = 'TA';
    const PLAYER_TARGET = 'TP';
}

namespace ATTRIBUTE_BIT_POSITION {
    const _1 = 0;  // byte 0
    const _2 = 24;  // byte 3
    const _3 = 40;  // byte 5
    const _4 = 64;  // byte 8
    const _5 = 80;  // byte 10
    const _6 = 104;  // byte 13
    const _7 = 120;  // byte 15
    const _8 = 136;  // byte 17
}

namespace ATTRIBUTE_SHIFT {
    const _1 = 2 ** 0;
    const _2 = 2 ** 24;
    const _3 = 2 ** 40;
    const _4 = 2 ** 64;
    const _5 = 2 ** 80;
    const _6 = 2 ** 104;
    const _7 = 2 ** 120;
    const _8 = 2 ** 136;
}
