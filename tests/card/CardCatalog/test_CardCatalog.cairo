%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_contract_address

from src.catalog.interfaces.ICatalog import ICatalog
from src.utils.constants import TokenRef

@external
func __setup__() {
    alloc_locals;
    local coll1_name = 'hello';
    local coll1_symbol = 'HELL';
    local coll2_name = 'cairo';
    local coll2_symbol = 'CAI';

    %{ context.contract_address = deploy_contract("./src/card/CardCatalog/CardCatalog.cairo").contract_address %}

    _deploy_collection(1, 'hello', 'HELL', 3);
    _deploy_collection(2, 'cairo', 'CAI', 3);

    return ();
}

// TODO: test expected failure on EnemyCollection addition
@external
func test_add_collection{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local contract_address;
    local coll1_address;
    local coll2_address;
    let (local owner_address) = get_contract_address();
    local game_mode = 'TEST_MODE';
    %{
        ids.contract_address = context.contract_address
        ids.coll1_address = context.coll1_address
        ids.coll2_address = context.coll2_address
    %}

    ICatalog.add_collection(contract_address, 'TEST_MODE', coll1_address);
    %{
        context.owner_address = ids.owner_address
        storage_owner = load(context.contract_address, "owner", "felt", [ids.game_mode])[0]
        assert storage_owner == context.owner_address, "test_add_collection: stored owner is not the same as the add_collection() caller."

        assert load(context.contract_address, "catalog_len", "felt", [ids.game_mode])[0] == 1, "test_add_collection: there should be only 1 collection for 'TEST_MODE' in storage."
        assert load(context.contract_address, "catalog", "felt", [ids.game_mode, 0])[0] == context.coll1_address, "test_add_collection: wrong collection stored at index 0."
    %}

    ICatalog.add_collection(contract_address, 'TEST_MODE', coll2_address);
    %{
        storage_owner = load(context.contract_address, "owner", "felt", [ids.game_mode])[0]
        assert storage_owner == context.owner_address, "test_add_collection: stored owner has changed after 2nd add_collection() call."

        assert load(context.contract_address, "catalog_len", "felt", [ids.game_mode])[0] == 2, "test_add_collection: there should be 2 collections for 'TEST_MODE' in storage."
        assert load(context.contract_address, "catalog", "felt", [ids.game_mode, 0])[0] == context.coll1_address, "test_add_collection: wrong collection stored at index 0."
        assert load(context.contract_address, "catalog", "felt", [ids.game_mode, 1])[0] == context.coll2_address, "test_add_collection: wrong collection stored at index 1."
    %}

    return ();
}

@external
func setup_get_collections{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local contract_address;
    local coll1_address;
    local coll2_address;
    local game_mode = 'TEST_MODE';
    %{
        ids.contract_address = context.contract_address
        ids.coll1_address = context.coll1_address
        ids.coll2_address = context.coll2_address
    %}

    ICatalog.add_collection(contract_address, game_mode, coll1_address);
    ICatalog.add_collection(contract_address, game_mode, coll2_address);

    return ();
}

@external
func test_get_collections{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local contract_address;
    local game_mode = 'TEST_MODE';
    %{ ids.contract_address = context.contract_address %}

    let (local collections_len, local collections) = ICatalog.get_collections(
        contract_address, game_mode
    );
    %{
        assert ids.collections_len == 2, "test_get_collections: wrong number of collections retrieved."
        assert memory[ids.collections] == context.coll1_address, "test_get_collections: wrong collection retrieved at index 0."
        assert memory[ids.collections + 1] == context.coll2_address, "test_get_collections: wrong collection retrieved at index 1."
    %}

    return ();
}

@external
func setup_get_tokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local contract_address;
    local coll1_address;
    local coll2_address;
    local game_mode = 'TEST_MODE';
    %{
        ids.contract_address = context.contract_address
        ids.coll1_address = context.coll1_address
        ids.coll2_address = context.coll2_address
    %}

    ICatalog.add_collection(contract_address, game_mode, coll1_address);
    ICatalog.add_collection(contract_address, game_mode, coll2_address);

    return ();
}

@external
func test_get_tokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local contract_address;
    %{ ids.contract_address = context.contract_address %}

    let (local tokens_len, local tokens: TokenRef*) = ICatalog.get_tokens(
        contract_address, 'TEST_MODE'
    );

    local token1: TokenRef = [tokens];
    local token2: TokenRef = [tokens + 1 * TokenRef.SIZE];
    local token4: TokenRef = [tokens + 3 * TokenRef.SIZE];
    local token6: TokenRef = [tokens + 5 * TokenRef.SIZE];
    %{
        assert ids.tokens_len == 6, "test_get_tokens: Wrong number of tokens retrieved."
        assert ids.token1.token_id == 0, "test_get_tokens: Wrong id for tokens[0]."
        assert ids.token1.collection_addr == context.coll1_address, "test_get_tokens: Wrong collection address for tokens[0]"
        assert ids.token2.token_id == 1, "test_get_tokens: Wrong id for tokens[1]."
        assert ids.token2.collection_addr == context.coll1_address, "test_get_tokens: Wrong collection address for tokens[1]"
        assert ids.token4.token_id == 0, "test_get_tokens: Wrong id for tokens[3]."
        assert ids.token4.collection_addr == context.coll2_address, "test_get_tokens: Wrong collection address for tokens[3]"
        assert ids.token6.token_id == 2, "test_get_tokens: Wrong id for tokens[5]."
        assert ids.token6.collection_addr == context.coll2_address, "test_get_tokens: Wrong collection address for tokens[5]"
    %}

    return ();
}

//
// Internals
//

// Deploy a collection for testing purpose
func _deploy_collection(contract_idx: felt, name: felt, symbol: felt, total_supply: felt) {
    %{
        call_data = []

        call_data.append(ids.name)
        call_data.append(ids.symbol)
        call_data.append(ids.total_supply)

        if (ids.contract_idx == 1):
            base_uri = "base_uri1"

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

            context.coll1_address = deploy_contract(
                "./src/card/CardCollection/CardCollection.cairo",
                call_data
                ).contract_address
        elif (ids.contract_idx == 2):
            base_uri = "base_uri2"

            call_data.append(len(base_uri))
            for c in base_uri: call_data.append(ord(c))

            data = [
                (0x10, 0x20, 0x30),
                (0x40, 0x50, 0x60),
                (0x70, 0x80, 0x90)
            ]

            call_data.append(len(data))
            for d in data:
                for e in d:
                    call_data.append(e)

            context.coll2_address = deploy_contract(
                "./src/card/CardCollection/CardCollection.cairo",
                call_data
                ).contract_address
    %}

    return ();
}
