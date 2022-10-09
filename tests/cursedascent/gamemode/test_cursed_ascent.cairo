%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from tests.card.CardCatalog.utils import deploy_card_catalog
from tests.scene.SceneCatalog.utils import deploy_scene_catalog

from src.gamemode.interfaces.IGameMode import IGameMode
from src.utils.constants import TokenRef
from src.player.constants import AdventurerClassEnum

@external
func deploy_cursed_ascent{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}() {
    deploy_card_catalog();
    deploy_scene_catalog();

    %{
        call_data = [context.card_catalog_address, context.scene_catalog_address]
        context.cursed_ascent_addr = deploy_contract("./src/cursed_ascent/cursed_ascent.cairo", call_data).contract_address
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

@external
func test_start_new_game{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}() {
    alloc_locals;


    local cursed_ascent_addr;

    %{
        ids.cursed_ascent_addr = context.cursed_ascent_addr
    %}

    let (local game_state, local card_deck_len, local card_deck) = IGameMode.start_new_game(contract_address=cursed_ascent_addr, adventurer_ref=TokenRef(0, AdventurerClassEnum.WARRIOR));

    return ();
}