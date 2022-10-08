%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc

from src.scene.SceneLogic.interfaces.ISceneLogic import ISceneLogic
from src.tokens.ERC721.AERC721 import AERC721
from src.utils.constants import TokenRef
from src.scene.constants import SceneData

//
// Storage
//

@storage_var
func logic_addr(token_id: felt) -> (logic_contract_addr: felt) {
}

//
// Constructor
//

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt,
    symbol: felt,
    total_supply: felt,
    base_uri_len: felt,
    base_uri: felt*,
    data_len: felt,
    data: SceneData*,
) {
    AERC721.initializer(name, symbol, total_supply, base_uri_len, base_uri);
    _initializer(data_len - 1, data + data_len * SceneData.SIZE);

    return ();
}

func _initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    data_len: felt, data: SceneData*
) {
    if (data_len == -1) {
        return ();
    }

    let sceneData = [data - SceneData.SIZE];

    logic_addr.write(data_len, sceneData.logic_contract_addr);

    return _initializer(data_len - 1, data - SceneData.SIZE);
}

//
// Getters
//

// @notice Return the name of the token
// @return name: the name of the token
@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
    return AERC721.name();
}

// @notice Return the symbol of the token
// @return symbol: the symbol of the token
@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (symbol: felt) {
    return AERC721.symbol();
}

// @notice Return the number of tokens in the collection
// @return total_supply: the number of tokens in the collection
@view
func total_supply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    total_supply: felt
) {
    return AERC721.total_supply();
}

// @notice Return the formatted URI of the given token
// @param token_id: the id of the token
// @return : a string containing the URI of the token and its length
@view
func tokenURI{
    bitwise_ptr: BitwiseBuiltin*, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(token_id: felt) -> (token_uri_len: felt, token_uri: felt*) {
    return AERC721.tokenURI(token_id=token_id);
}

// @notice Get the address of the ISceneLogic implementation contract tied to this NFT
// @param token_id: the id of the scene in the collection
// @return logic_contract_addr: the address of the ISceneLogic implementation contract
@view
func get_logic_contract_addr{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: felt
) -> (logic_contract_addr: felt) {
    return logic_addr.read(token_id);
}

// @notice Get the list of event ids from the logic contract
// @param token_id: the id of the scene in the collection
// @return event_id_list_len, event_id_list: the length of the event id list, the list of event ids
@view
func get_event_id_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: felt
) -> (event_id_list_len: felt, event_id_list: felt*) {
    let (scene_logic) = logic_addr.read(token_id);

    let (data_len, data) = ISceneLogic.get_event_id_list(scene_logic);
    return (data_len, data);
}

// @notice Get the list of enemy ids declared by the logic contract
// @param token_id: the id of the scene in the collection
// @return enemy_id_list_len, enemy_id_list: the length of the enemy id list, the list of enemy ids
@view
func get_enemy_id_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: felt
) -> (enemy_id_list_len: felt, enemy_id_list: TokenRef*) {
    let (scene_logic) = logic_addr.read(token_id);

    let (data_len, data) = ISceneLogic.get_enemy_id_list(scene_logic);
    return (data_len, data);
}
