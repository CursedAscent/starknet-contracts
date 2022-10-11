%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin

from tests.scene.SceneCollection.utils import setup_scene_collection

from src.scene.SceneCollection.interfaces.ISceneCollection import ISceneCollection
from src.utils.constants import TokenRef
from src.scene.Scene import Scene
from src.scene.constants import SceneTypeEnum
from src.scene.SceneBuilder.library import SceneBuilderLib

@external
func __setup__() {
    return ();
}

@external
func test_build_partial_scene{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;
    setup_scene_collection();

    local contract_address;
    %{ ids.contract_address = context.scene_collection_address %}

    let scene_ref = TokenRef(collection_addr=contract_address, token_id=0);
    let (local scene) = SceneBuilderLib.build_partial_scene(scene_ref);

    local cocky_imp_addr;
    %{ ids.cocky_imp_addr = context.cocky_imp_address %}
    assert scene.logic_contract_addr = cocky_imp_addr;

    with_attr error_message("Error is expected: scene_type have been hardcoded to 0 for now.") {
        assert scene.scene_type = SceneTypeEnum.FIGHT;
    }

    return ();
}
