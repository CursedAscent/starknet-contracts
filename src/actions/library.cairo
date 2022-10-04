%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc

from src.actions.constants import Attributes, ATTRIBUTE_SHIFT, ATTRIBUTE_BIT_POSITION
from src.utils.unpack import unpack_data

namespace AttributesLib {
    func pack{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(unpacked_attribute: Attributes) -> (packed_attribute: felt) {
        let attr1 = unpacked_attribute.attr1 * ATTRIBUTE_SHIFT._1;
        let value1 = unpacked_attribute.value1 * ATTRIBUTE_SHIFT._2;
        let attr2 = unpacked_attribute.attr2 * ATTRIBUTE_SHIFT._3;
        let value2 = unpacked_attribute.value2 * ATTRIBUTE_SHIFT._4;
        let attr3 = unpacked_attribute.attr3 * ATTRIBUTE_SHIFT._5;
        let value3 = unpacked_attribute.value3 * ATTRIBUTE_SHIFT._6;
        let target = unpacked_attribute.target * ATTRIBUTE_SHIFT._7;
        let target_value = unpacked_attribute.target_value * ATTRIBUTE_SHIFT._8;

        return (
            packed_attribute=attr1 + value1 + attr2 + value2 + attr3 + value3 + target + target_value,
        );
    }

    func unpack{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(packed_attribute: felt) -> (attributes: Attributes) {
        alloc_locals;
        let (local attr1) = unpack_data(packed_attribute, ATTRIBUTE_BIT_POSITION._1, 16777215);  // 3 bytes
        let (local value1) = unpack_data(packed_attribute, ATTRIBUTE_BIT_POSITION._2, 65535);  // 2 bytes
        let (local attr2) = unpack_data(packed_attribute, ATTRIBUTE_BIT_POSITION._3, 16777215);
        let (local value2) = unpack_data(packed_attribute, ATTRIBUTE_BIT_POSITION._4, 65535);
        let (local attr3) = unpack_data(packed_attribute, ATTRIBUTE_BIT_POSITION._5, 16777215);
        let (local value3) = unpack_data(packed_attribute, ATTRIBUTE_BIT_POSITION._6, 65535);
        let (local target) = unpack_data(packed_attribute, ATTRIBUTE_BIT_POSITION._7, 65535);
        let (local target_value) = unpack_data(packed_attribute, ATTRIBUTE_BIT_POSITION._8, 65535);

        return (
            attributes=Attributes(attr1, value1, attr2, value2, attr3, value3, target, target_value)
        );
    }
}
