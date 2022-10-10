%lang starknet

from starkware.cairo.common.alloc import alloc

from src.scene.constants import SceneData
from tests.scene.SceneCatalog.utils import deploy_scene_catalog

func __setup__() {
    alloc_locals;

    let (local data: SceneData*) = alloc();
    assert [data] = SceneData(0x42);
    // deploy_scene_catalog(1, data);// implicit arguments required

    return ();
}
