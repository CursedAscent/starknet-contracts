%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin

from src.actions.constants import (
    Attributes,
    AttributesEnum,
    ATTRIBUTE_SHIFT,
    ATTRIBUTE_BIT_POSITION,
)
from src.actions.library import AttributesLib

@external
func test_pack{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    local attribute: Attributes = Attributes(AttributesEnum.DIRECT_HIT, 420, AttributesEnum.PROTECTION_POINT, 777, 0, 0, AttributesEnum.PLAYER_SELECTION, 1);
    let (local packed) = AttributesLib.pack(attribute);
    let (local unpacked: Attributes) = AttributesLib.unpack(packed);

    assert unpacked.attr1 = attribute.attr1;
    assert unpacked.value1 = attribute.value1;
    assert unpacked.attr2 = attribute.attr2;
    assert unpacked.value2 = attribute.value2;
    assert unpacked.attr3 = attribute.attr3;
    assert unpacked.value3 = attribute.value3;
    assert unpacked.target = attribute.target;
    assert unpacked.target_value = attribute.target_value;

    return ();
}
