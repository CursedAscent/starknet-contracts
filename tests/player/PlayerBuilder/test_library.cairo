%lang starknet

from src.player.PlayerBuilder.library import PlayerBuilderLib
from src.utils.constants import TokenRef
from src.player.constants import AdventurerClassEnum

@external
func test_build_player{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    let adventurer_ref = TokenRef(collection_addr=0x0, token_id=AdventurerClassEnum.WARRIOR);

    let (local player) = PlayerBuilderLib.build_player(adventurer_ref);

    assert player.damage_coef = 100;

    return ();
}
