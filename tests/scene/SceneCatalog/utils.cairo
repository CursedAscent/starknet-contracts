%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc

from src.catalog.interfaces.ICatalog import ICatalog
from src.scene.constants import SceneData
from tests.scene.SceneCollection.utils import setup_scene_collection

func deploy_scene_catalog{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(scene_collection_data_len: felt, scene_collection_data: SceneData*) {
    alloc_locals;
    local scene_catalog_addr;
    local scene_collection_addr;

    setup_scene_collection(scene_collection_data_len, scene_collection_data);

    %{
        context.scene_catalog_address = deploy_contract(
        "./src/scene/SceneCatalog/SceneCatalog.cairo",
        ).contract_address

        ids.scene_catalog_addr = context.scene_catalog_address;
        ids.scene_collection_addr = context.scene_collection_address;
    %}

    ICatalog.add_collection(
        contract_address=scene_catalog_addr,
        game_mode='Cursed',
        collection_addr=scene_collection_addr,
    );

    return ();
}
