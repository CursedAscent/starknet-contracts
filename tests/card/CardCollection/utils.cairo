%lang starknet

from src.player.constants import AdventurerClassEnum

func setup_card_collection() {
    alloc_locals;
    local name = 'Cursed';
    local symbol = 'CURSE';
    local WAR = AdventurerClassEnum.WARRIOR;
    local HUN = AdventurerClassEnum.HUNTER;
    local LMA = AdventurerClassEnum.LIGHT_MAGE;
    local DMA = AdventurerClassEnum.DARK_MAGE;

    %{
        call_data = []

        call_data.append(ids.name)
        call_data.append(ids.symbol)
        call_data.append(0x84)

        base_uri = "ipfs://bafybeidlakszlrz2xfjca5r4sfj2watoove4vz3oism5ufmc7dxzlxfywm"

        call_data.append(len(base_uri))
        for c in base_uri: call_data.append(ord(c))

        call_data.append(13*4)

        for i in range(13):
            call_data.append(0x1)
            call_data.append(ids.WAR)
            call_data.append(0x1)

        for i in range(13):
            call_data.append(0x1)
            call_data.append(ids.HUN)
            call_data.append(0x1)

        for i in range(13):
            call_data.append(0x1)
            call_data.append(ids.LMA)
            call_data.append(0x1)

        for i in range(13):
            call_data.append(0x1)
            call_data.append(ids.DMA)
            call_data.append(0x1)

        context.card_collection_address = deploy_contract("./src/card/CardCollection/CardCollection.cairo", call_data).contract_address
    %}

    return ();
}
