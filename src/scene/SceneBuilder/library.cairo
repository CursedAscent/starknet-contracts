// Helper functions to create Scene Instances

%lang starknet

from src.scene.Scene import Scene
from src.utils.constants import TokenRef
from src.scene.SceneCollection.interfaces.ISceneCollection import ISceneCollection

namespace SceneBuilderLib {
    // @notice Builds a partial Scene instance from its token data.
    // @param card_ref: The scene's token ids
    // @return card: The partial scene entity
    func build_partial_scene{syscall_ptr: felt*, range_check_ptr}(scene_ref: TokenRef) -> (
        scene: Scene
    ) {
        alloc_locals;

        let (local logic_contract_addr) = ISceneCollection.get_logic_contract_addr(
            contract_address=scene_ref.collection_addr, token_id=scene_ref.token_id
        );

        local scene: Scene = Scene(
            scene_ref=scene_ref,
            logic_contract_addr=logic_contract_addr
            );

        return (scene=scene);
    }
}
