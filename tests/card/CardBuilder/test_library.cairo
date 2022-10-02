%lang starknet

from src.card.CardCollection.interfaces.ICardCollection import ICardCollection
from src.utils.constants import TokenRef
from src.card.Card import Card
from src.card.CardBuilder.library import CardBuilderLib

@external
func __setup__() {
    alloc_locals;
    local name = 'hello';
    local symbol = 'HELL';

    %{
        call_data = []

        call_data.append(ids.name)
        call_data.append(ids.symbol)
        call_data.append(0x84)

        base_uri = "ipfs://bafybeidlakszlrz2xfjca5r4sfj2watoove4vz3oism5ufmc7dxzlxfywm"

        call_data.append(len(base_uri))
        for c in base_uri: call_data.append(ord(c))

        data = [
            (0x1, 0x2, 0x3),
            (0x4, 0x5, 0x6),
            (0x7, 0x8, 0x9)
        ]

        call_data.append(len(data))
        for d in data:
            for e in d:
                call_data.append(e)

        context.contract_address = deploy_contract("./src/card/CardCollection/CardCollection.cairo", call_data).contract_address
    %}

    return ();
}

@external
func test_build_partial_card{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local contract_address;
    %{ ids.contract_address = context.contract_address %}

    let card_ref = TokenRef(collection_addr=contract_address, token_id=1);
    let (local card) = CardBuilderLib.build_partial_card(card_ref);

    assert card.card_ref.token_id = 1;
    assert card.id = -1;
    assert card.action = 0x4;
    assert card.class = 0x5;
    assert card.rarity = 0x6;

    return ();
}
