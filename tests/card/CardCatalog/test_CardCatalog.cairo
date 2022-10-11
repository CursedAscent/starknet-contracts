%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_contract_address

from tests.card.CardCatalog.utils import deploy_card_catalog

from src.catalog.interfaces.ICatalog import ICatalog
from src.utils.constants import TokenRef

@external
func __setup__() {
    return ();
}

// TODO: test expected failure on EnemyCollection addition
@external
func test_add_collection{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;
    deploy_card_catalog();

    local contract_address;
    local coll_address;
    let (local owner_address) = get_contract_address();
    local game_mode = 'TEST_MODE';
    %{
        ids.contract_address = context.card_catalog_address
        ids.coll_address = context.card_collection_address
    %}

    ICatalog.add_collection(contract_address, 'TEST_MODE', coll_address);
    %{
        storage_owner = load(ids.contract_address, "owner", "felt", [ids.game_mode])[0]
        assert storage_owner == ids.owner_address, "test_add_collection: stored owner is not the same as the add_collection() caller."

        assert load(ids.contract_address, "catalog_len", "felt", [ids.game_mode])[0] == 1, "test_add_collection: there should be only 1 collection for 'TEST_MODE' in storage."
        assert load(ids.contract_address, "catalog", "felt", [ids.game_mode, 0])[0] == ids.coll_address, "test_add_collection: wrong collection stored at index 0."
    %}

    return ();
}

@external
func test_get_collections{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;
    deploy_card_catalog();

    local contract_address;
    local game_mode = 'Cursed';
    %{ ids.contract_address = context.card_catalog_address %}

    let (local collections_len, local collections) = ICatalog.get_collections(
        contract_address, game_mode
    );
    %{
        assert ids.collections_len == 1, "test_get_collections: wrong number of collections retrieved."
        assert memory[ids.collections] == context.card_collection_address, "test_get_collections: wrong collection retrieved at index 0."
    %}

    return ();
}

@external
func test_get_tokens{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;
    deploy_card_catalog();

    local contract_address;
    %{ ids.contract_address = context.card_catalog_address %}

    let (local tokens_len, local tokens: TokenRef*) = ICatalog.get_tokens(
        contract_address, 'Cursed'
    );

    %{ assert ids.tokens_len == 52, "test_get_tokens: Wrong number of tokens retrieved." %}

    local token1: TokenRef = [tokens];
    local token2: TokenRef = [tokens + 1 * TokenRef.SIZE];
    local token4: TokenRef = [tokens + 3 * TokenRef.SIZE];
    local token6: TokenRef = [tokens + 5 * TokenRef.SIZE];
    %{
        assert ids.token1.token_id == 0, "test_get_tokens: Wrong id for tokens[0]."
        assert ids.token1.collection_addr == context.card_collection_address, "test_get_tokens: Wrong collection address for tokens[0]"
        assert ids.token2.token_id == 1, "test_get_tokens: Wrong id for tokens[1]."
        assert ids.token2.collection_addr == context.card_collection_address, "test_get_tokens: Wrong collection address for tokens[1]"
        assert ids.token4.token_id == 3, "test_get_tokens: Wrong id for tokens[3]."
        assert ids.token4.collection_addr == context.card_collection_address, "test_get_tokens: Wrong collection address for tokens[3]"
        assert ids.token6.token_id == 5, "test_get_tokens: Wrong id for tokens[5]."
        assert ids.token6.collection_addr == context.card_collection_address, "test_get_tokens: Wrong collection address for tokens[5]"
    %}

    return ();
}
