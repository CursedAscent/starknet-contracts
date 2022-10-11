%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_le

from tests.cursedascent.scene.utils import deploy_cocky_imp
from tests.card.CardCatalog.utils import deploy_card_catalog
from tests.scene.SceneCatalog.utils import deploy_scene_catalog

from src.gamemode.constants import GameState
from src.session.Session import Session
from src.enemy.Enemy import Enemy
from src.card.Card import Card
from src.scene.constants import SceneData, SceneTypeEnum
from src.scene.SceneLogic.constants import SceneLogicEvents
from src.session.constants import SessionStateEnum
from src.gamemode.interfaces.IGameMode import IGameMode
from src.utils.constants import TokenRef
from src.player.constants import AdventurerClassEnum
from src.action.constants import PackedActionHistory
from src.action.library import ActionLib

@external
func deploy_cursed_ascent{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    deploy_cocky_imp();
    let (local data: felt*) = alloc();

    %{ memory[ids.data] = context.cocky_imp_address %}

    deploy_scene_catalog(1, cast(data, SceneData*));
    deploy_card_catalog();

    local cursed_ascent;
    %{
        call_data = [context.card_catalog_address, context.scene_catalog_address]
        context.cursed_ascent_addr = deploy_contract("./src/cursed_ascent/cursed_ascent.cairo", call_data).contract_address
        ids.cursed_ascent = context.cursed_ascent_addr
    %}

    // let (local cards_len1, cards1: felt*) = IGameMode.get_available_cards(
    //     cursed_ascent, AdventurerClassEnum.WARRIOR
    // );
    // let (local cards_len2, cards2: felt*) = IGameMode.get_available_cards(
    //     cursed_ascent, AdventurerClassEnum.HUNTER
    // );
    // let (local cards_len3, cards3: felt*) = IGameMode.get_available_cards(
    //     cursed_ascent, AdventurerClassEnum.LIGHT_MAGE
    // );
    // let (local cards_len4, cards4: felt*) = IGameMode.get_available_cards(
    //     cursed_ascent, AdventurerClassEnum.DARK_MAGE
    // );
    // local card_size = Card.SIZE;
    // you can visualize cards layout here (it involves several contracts!)
    // %{
    //     print(ids.card_size)
    //     print("warrior cards:")
    //     print(ids.cards_len1)
    //     for i in range(0, ids.cards_len1):
    //         print(i)
    //         print(memory[ids.cards1 + (i * ids.card_size)], memory[ids.cards1 + (i * ids.card_size) + 1], memory[ids.cards1 + (i * ids.card_size) + 2], memory[ids.cards1 + (i * ids.card_size) + 4])

    // print("hunter cards:")
    //     print(ids.cards_len2)
    //     for i in range(0, ids.cards_len2):
    //         print(i)
    //         print(memory[ids.cards2 + (i * ids.card_size)], memory[ids.cards2 + (i * ids.card_size) + 1], memory[ids.cards2 + (i * ids.card_size) + 2], memory[ids.cards2 + (i * ids.card_size) + 4])

    // print("light mage cards:")
    //     print(ids.cards_len3)
    //     for i in range(0, ids.cards_len3):
    //         print(i)
    //         print(memory[ids.cards3 + (i * ids.card_size)], memory[ids.cards3 + (i * ids.card_size) + 1], memory[ids.cards3 + (i * ids.card_size) + 2], memory[ids.cards3 + (i * ids.card_size) + 4])

    // print("dark mage cards:")
    //     print(ids.cards_len4)
    //     for i in range(0, ids.cards_len4):
    //         print(i)
    //         print(memory[ids.cards4 + (i * ids.card_size)], memory[ids.cards4 + (i * ids.card_size) + 1], memory[ids.cards4 + (i * ids.card_size) + 2], memory[ids.cards4 + (i * ids.card_size) + 4])
    // %}

    return ();
}

@external
func __setup__{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    deploy_cursed_ascent();

    return ();
}

// @external
// func test_start_new_game{
//     syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
// }() {
//     alloc_locals;
//     deploy_cursed_ascent();

// local cursed_ascent_addr;
//     %{ ids.cursed_ascent_addr = context.cursed_ascent_addr %}

// let (local game_state, local card_deck_len, local card_deck) = IGameMode.start_new_game(
//         contract_address=cursed_ascent_addr,
//         adventurer_ref=TokenRef(0, AdventurerClassEnum.LIGHT_MAGE),
//     );

// assert game_state.player.class = AdventurerClassEnum.LIGHT_MAGE;
//     assert card_deck_len = 5;

// return ();
// }

@external
func test_next_action{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;
    deploy_cursed_ascent();

    local cursed_ascent_addr;
    %{ ids.cursed_ascent_addr = context.cursed_ascent_addr %}

    // start new game
    let (local game_state, local card_deck_len, local card_deck: Card*) = IGameMode.start_new_game(
        contract_address=cursed_ascent_addr, adventurer_ref=TokenRef(0, AdventurerClassEnum.WARRIOR)
    );

    assert game_state.player.class = AdventurerClassEnum.WARRIOR;
    assert game_state.current_state = SessionStateEnum.GAME_INITIALIZED;
    assert card_deck_len = 5;

    // pick room (there, scene_state should be initialized)
    let (local game_state, local card_deck_len, local card_deck: Card*) = IGameMode.pick_room(
        cursed_ascent_addr, game_state, card_deck_len, card_deck, 1
    );
    assert game_state.current_state = SessionStateEnum.GAME_IN_ROOM;
    assert game_state.scene_state.current_event = SceneLogicEvents.INTRO;

    // draw cards
    let (local hand_len, local hand: Card*, _) = IGameMode.draw_cards(
        cursed_ascent_addr, game_state, card_deck_len, card_deck
    );
    assert hand_len = 3;

    // lets print out the hand
    local hand_felt: felt* = hand;
    local card_size = Card.SIZE;
    %{
        print("Draw Hand:")
        print("card 1")
        print(memory[ids.hand_felt], memory[ids.hand_felt + 1], memory[ids.hand_felt + 2], memory[ids.hand_felt + 3], memory[ids.hand_felt + 4], memory[ids.hand_felt + 5], memory[ids.hand_felt + 6])
        print("card 2")
        print(memory[ids.hand_felt + 7], memory[ids.hand_felt + 8], memory[ids.hand_felt + 9], memory[ids.hand_felt + 10], memory[ids.hand_felt + 11], memory[ids.hand_felt + 12], memory[ids.hand_felt + 13])
        print("card 3")
        print(memory[ids.hand_felt + 14], memory[ids.hand_felt + 15], memory[ids.hand_felt + 16], memory[ids.hand_felt + 17], memory[ids.hand_felt + 18], memory[ids.hand_felt + 19], memory[ids.hand_felt + 20])
    %}

    // next action
    let (
        local game_state2,
        local card_deck_len,
        local card_deck: Card*,
        local history_len,
        local history: PackedActionHistory*,
    ) = IGameMode.next_action(cursed_ascent_addr, game_state, card_deck_len, card_deck, 1, 2, 0);

    // print variables
    local enemy_before: Enemy = game_state.scene_state.enemies[0];
    local enemy_after: Enemy = game_state2.scene_state.enemies[0];
    %{
        print("action result:")
        print("BEFORE ACTION")
        print(ids.game_state.player.health_points)
        print(ids.game_state.player.protection_points)
        print(ids.enemy_before.health_points)
        print(ids.enemy_before.protection_points)

        print("AFTER ACTION")
        print(ids.game_state2.player.health_points)
        print(ids.game_state2.player.protection_points)
        print(ids.enemy_after.health_points)
        print(ids.enemy_after.protection_points)

        print("history_len:")
        print(ids.history_len)
    %}

    // lets corrupt the GameState and call the contract (expecting a revert)
    // (game_state is the old game state, before the first next_action call)
    %{ expect_revert(error_message="received game state doesn't match with the saved hash") %}

    let (
        local game_state,
        local card_deck_len,
        local card_deck: Card*,
        local history_len,
        local history: PackedActionHistory*,
    ) = IGameMode.next_action(cursed_ascent_addr, game_state, card_deck_len, card_deck, 1, 0, 0);

    return ();
}
