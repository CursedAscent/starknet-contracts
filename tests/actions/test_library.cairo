%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin

from src.action.constants import Action, AttributeEnum, ATTRIBUTE_SHIFT, ATTRIBUTE_BIT_POSITION
from src.action.library import ActionLib

@external
func test_pack{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    local attribute: Action = Action(AttributeEnum.DIRECT_HIT, 420, AttributeEnum.PROTECTION_POINT, 777, 0, 0, AttributeEnum.SELECTED_TARGET, 1, AttributeEnum.ALL_TARGET, 2, 0, 0);
    let (local packed) = ActionLib.pack(attribute);
    let (local unpacked: Action) = ActionLib.unpack(packed);

    assert unpacked.attr1 = attribute.attr1;
    assert unpacked.value1 = attribute.value1;
    assert unpacked.attr2 = attribute.attr2;
    assert unpacked.value2 = attribute.value2;
    assert unpacked.attr3 = attribute.attr3;
    assert unpacked.value3 = attribute.value3;
    assert unpacked.target1 = attribute.target1;
    assert unpacked.target_value1 = attribute.target_value1;
    assert unpacked.target2 = attribute.target2;
    assert unpacked.target_value2 = attribute.target_value2;
    assert unpacked.target3 = attribute.target3;
    assert unpacked.target_value3 = attribute.target_value3;

    return ();
}
