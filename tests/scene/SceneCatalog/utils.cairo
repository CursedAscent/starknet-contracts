%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from src.catalog.interfaces.ICatalog import ICatalog
from tests.scene.SceneCollection.utils import setup_scene_collection

func deploy_scene_catalog{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;
    local scene_catalog_addr;
    local scene_collection_addr;

    setup_scene_collection();

    %{
        context.scene_catalog_address = deploy_contract(
        "./src/scene/SceneCatalog/SceneCatalog.cairo",
        ).contract_address

        ids.scene_catalog_addr = context.scene_catalog_address;
        ids.scene_collection_addr = context.scene_collection_address;
    %}

    ICatalog.add_collection(contract_address=scene_catalog_addr, game_mode='CURSED ASCENT', collection_addr=scene_collection_addr);

    return ();
}