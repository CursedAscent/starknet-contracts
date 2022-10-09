%lang starknet

from tests.scene.SceneCatalog.utils import deploy_scene_catalog

func __setup__() {
    deploy_scene_catalog();

    return ();
}