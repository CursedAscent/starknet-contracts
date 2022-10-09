%lang starknet

// Session states
namespace SessionStateEnum {
    const GAME_INITIALIZED = 0x1;
    const GAME_IN_MAP = 0x2;
    const GAME_IN_ROOM = 0x3;
    const GAME_LOST = 0x5;
    const GAME_WON = 0x6;
}
