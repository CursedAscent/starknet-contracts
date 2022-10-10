%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc

from tests.cursedascent.scene.utils import deploy_cocky_imp
from tests.card.CardCatalog.utils import deploy_card_catalog
from tests.scene.SceneCatalog.utils import deploy_scene_catalog

from src.card.Card import Card
from src.scene.constants import SceneData, SceneTypeEnum
from src.scene.SceneLogic.constants import SceneLogicEvents
from src.session.constants import SessionStateEnum
from src.gamemode.interfaces.IGameMode import IGameMode
from src.utils.constants import TokenRef
from src.player.constants import AdventurerClassEnum

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

    let (local cards_len1, cards1: felt*) = IGameMode.get_available_cards(
        cursed_ascent, AdventurerClassEnum.WARRIOR
    );
    let (local cards_len2, cards2: felt*) = IGameMode.get_available_cards(
        cursed_ascent, AdventurerClassEnum.HUNTER
    );
    let (local cards_len3, cards3: felt*) = IGameMode.get_available_cards(
        cursed_ascent, AdventurerClassEnum.LIGHT_MAGE
    );
    let (local cards_len4, cards4: felt*) = IGameMode.get_available_cards(
        cursed_ascent, AdventurerClassEnum.DARK_MAGE
    );
    local card_size = Card.SIZE;
    // you can visualize cards layout here (it involves several contracts!)
    %{
        # print(ids.card_size)
        # print("warrior cards:")
        # print(ids.cards_len1)
        # for i in range(0, ids.cards_len1):
        #     print(i)
        #     print(memory[ids.cards1 + (i * ids.card_size)], memory[ids.cards1 + (i * ids.card_size) + 1], memory[ids.cards1 + (i * ids.card_size) + 2], memory[ids.cards1 + (i * ids.card_size) + 4])

        # print("hunter cards:")
        # print(ids.cards_len2)
        # for i in range(0, ids.cards_len2):
        #     print(i)
        #     print(memory[ids.cards2 + (i * ids.card_size)], memory[ids.cards2 + (i * ids.card_size) + 1], memory[ids.cards2 + (i * ids.card_size) + 2], memory[ids.cards2 + (i * ids.card_size) + 4])

        # print("light mage cards:")
        # print(ids.cards_len3)
        # for i in range(0, ids.cards_len3):
        #     print(i)
        #     print(memory[ids.cards3 + (i * ids.card_size)], memory[ids.cards3 + (i * ids.card_size) + 1], memory[ids.cards3 + (i * ids.card_size) + 2], memory[ids.cards3 + (i * ids.card_size) + 4])

        # print("dark mage cards:")
        # print(ids.cards_len4)
        # for i in range(0, ids.cards_len4):
        #     print(i)
        #     print(memory[ids.cards4 + (i * ids.card_size)], memory[ids.cards4 + (i * ids.card_size) + 1], memory[ids.cards4 + (i * ids.card_size) + 2], memory[ids.cards4 + (i * ids.card_size) + 4])
    %}

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
    let (local game_state, local card_deck_len, local card_deck) = IGameMode.start_new_game(
        contract_address=cursed_ascent_addr, adventurer_ref=TokenRef(0, AdventurerClassEnum.WARRIOR)
    );

    assert game_state.player.class = AdventurerClassEnum.WARRIOR;
    assert game_state.current_state = SessionStateEnum.GAME_INITIALIZED;
    assert card_deck_len = 5;

    // pick room (there, scene_state should be initialized)
    // assert game_state.current_state = SessionStateEnum.GAME_IN_ROOM;
    // assert game_state.scene_state.current_event = SceneLogicEvents.INTRO;

    // next action (draw hand before !!)
    // let (
    //     local game_state,
    //     local card_deck_len,
    //     local card_deck,
    //     local history_len,
    //     local hisotry: PackedActionHistory*,
    // ) = IGameMode.next_action(game_state, card_deck_len, card_deck);

    return ();
}
