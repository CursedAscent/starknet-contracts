%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from src.catalog.interfaces.ICatalog import ICatalog
from tests.card.CardCollection.utils import setup_card_collection

func deploy_card_catalog{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;
    setup_card_collection();

    local catalog_contract_address;
    local card_collection_address;
    %{
        context.card_catalog_address = deploy_contract("./src/card/CardCatalog/CardCatalog.cairo").contract_address

        ids.catalog_contract_address = context.card_catalog_address
        ids.card_collection_address = context.card_collection_address
    %}

    ICatalog.add_collection(catalog_contract_address, 'CURSED ASCENT', card_collection_address);

    return ();
}