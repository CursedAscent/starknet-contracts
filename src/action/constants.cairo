// Data descriptions relative to actions made by Card & Enemy entities.

%lang starknet

// Description of an action in the game.
// Due to Cairo limitation, we decided to store this data packed in one felt.
struct Action {
    attr1: felt,  // short string
    value1: felt,
    attr2: felt,  // short string
    value2: felt,
    attr3: felt,  // short string
    value3: felt,
    target1: felt,  // short string
    target_value1: felt,
    target2: felt,  // short string
    target_value2: felt,
    target3: felt,  // short string
    target_value3: felt,
}

// typename PackedAttribute = felt;

// Description of the possible attributes in Action.
// 3 bytes MAXIMUM
// todo: reorganize by how value is interpreted (bonus amount, stack amount, repetition, ...)
namespace AttributeEnum {
    // no action
    const NO_ATTRIBUTE = '';

    // offensive actions (value is amount)
    const DIRECT_HIT = 'DH';
    const ATTACK_HEALTH = 'AH';
    const BLEEDING_STACKS = 'BS';
    const POISON_STACKS = 'PS';
    const PASSIVE_ATTACK = 'PA';

    // defensive actions (value is amount)
    const PROTECTION_POINT = 'PP';
    const HEALTH_POINT = 'HP';
    const ADD_ARMOR = 'AA';

    // Debuffs (value is amount of stack)
    const WEAKEN_DEFENSE = 'WD';
    const WEAKEN_ATTACK = 'WA';
    const WEAKEN_PROTECTION = 'WP';

    // Powers (value may be used)
    const PERMANENT_PROTECTION = 'PPS';
    const GENERATE_ATTACK_BONUS = 'GAB';

    // Targets (value is number of repetition)
    const SELECTED_TARGET = 'TS';
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
    const _9 = 152;  // byte 19
    const _10 = 168;  // byte 21
    const _11 = 194;  // byte 23
    const _12 = 210;  // byte 25
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
    const _9 = 2 ** 152;
    const _10 = 2 ** 168;
    const _11 = 2 ** 194;
    const _12 = 2 ** 210;
}
