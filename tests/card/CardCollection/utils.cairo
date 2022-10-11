%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin

from src.player.constants import AdventurerClassEnum
from src.action.library import ActionLib
from src.action.constants import Action

func setup_card_collection{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;
    local name = 'Cursed';
    local symbol = 'CURSE';
    local WAR = AdventurerClassEnum.WARRIOR;
    local HUN = AdventurerClassEnum.HUNTER;
    local LMA = AdventurerClassEnum.LIGHT_MAGE;
    local DMA = AdventurerClassEnum.DARK_MAGE;

    local action1: Action = Action('DH', 10, 0, 0, 0, 0, 'TS', 1, 0, 0, 0, 0);
    let (local pa1) = ActionLib.pack_action(action1);
    local action2: Action = Action('PP', 20, 0, 0, 0, 0, 'TP', 1, 0, 0, 0, 0);
    let (local pa2) = ActionLib.pack_action(action2);

    %{
        call_data = []

        call_data.append(ids.name)
        call_data.append(ids.symbol)
        call_data.append(52)

        base_uri = "ipfs://bafybeidlakszlrz2xfjca5r4sfj2watoove4vz3oism5ufmc7dxzlxfywm"

        call_data.append(len(base_uri))
        for c in base_uri: call_data.append(ord(c))

        call_data.append(13*4)

        for i in range(13):
            call_data.append(ids.pa1 if (i % 2) == 0 else ids.pa2)
            call_data.append(ids.WAR)
            call_data.append(0x1)

        for i in range(13):
            call_data.append(ids.pa1 if (i % 2) == 0 else ids.pa2)
            call_data.append(ids.HUN)
            call_data.append(0x1)

        for i in range(13):
            call_data.append(ids.pa1 if (i % 2) == 0 else ids.pa2)
            call_data.append(ids.LMA)
            call_data.append(0x1)

        for i in range(13):
            call_data.append(ids.pa1 if (i % 2) == 0 else ids.pa2)
            call_data.append(ids.DMA)
            call_data.append(0x1)

        context.card_collection_address = deploy_contract("./src/card/CardCollection/CardCollection.cairo", call_data).contract_address
    %}

    return ();
}
