%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc

from src.tokens.ERC721.AERC721 import AERC721
from src.enemy.constants import EnemyData

//
// Storage
//

@storage_var
func action_list_len(token_id: felt) -> (action_list_len: felt) {
}

@storage_var
func action(token_id: felt, action_id: felt) -> (packed_action: felt) {
}

@storage_var
func armor_coef(token_id: felt) -> (armor_coef: felt) {
}

@storage_var
func protection_points_coef(token_id: felt) -> (protection_points_coef: felt) {
}

@storage_var
func damage_coef(token_id: felt) -> (damage_coef: felt) {
}


@storage_var
func health_points(token_id: felt) -> (health_points: felt) {
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
    data: EnemyData*,

) {
    AERC721.initializer(name, symbol, total_supply, base_uri_len, base_uri);
    _initializer(data_len - 1, data + (data_len - 1) * EnemyData.SIZE);

    return ();
}

// Unrolls array into storage slots for given token_id
func _initialize_action_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: felt, action_list: (felt, felt, felt, felt, felt, felt, felt, felt)
) {
    action.write(token_id, 0, action_list[0]);
    action.write(token_id, 1, action_list[1]);
    action.write(token_id, 2, action_list[2]);
    action.write(token_id, 3, action_list[3]);
    action.write(token_id, 4, action_list[4]);
    action.write(token_id, 5, action_list[5]);
    action.write(token_id, 6, action_list[6]);
    action.write(token_id, 7, action_list[7]);

    return ();
}

func _initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    data_len: felt, data: EnemyData*
) {
    if (data_len == -1) {
        return ();
    }

    let enemyData = [data];

    action_list_len.write(data_len, enemyData.action_list_len);

    _initialize_action_list(data_len, enemyData.action_list);

    armor_coef.write(data_len, enemyData.armor_coef);
    protection_points_coef.write(data_len, enemyData.protection_points_coef);
    damage_coef.write(data_len, enemyData.damage_coef);
    health_points.write(data_len, enemyData.health_points);

    return _initializer(data_len - 1, data - EnemyData.SIZE);
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

// @notice Get the list of all actions an enemy has
// @param token_id: the id of the enemy in the collection
// @return action_list_len, action_list: the length of the array, array containing all the actions
@view
func get_action_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(token_id: felt) -> (
    action_list: (felt, felt, felt, felt, felt, felt, felt, felt)
) {

    return _fill_action_list(token_id);
}

// @notice Get a specific action of an enemy
// @param token_id: the id of the enemy in the collection
// @param action_id: the id of the action to retrieve
// @return action: the retrieved action packed in a felt
@view
func get_action{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(token_id: felt, action_id: felt) -> (packed_action: felt) {
    return action.read(token_id, action_id);
}

// @notice Get the armor base coefficient of an enemy
// @param token_id: the id of the enemy in the collection
// @return armor_coef: the armor base coefficient
@view
func get_armor_coef{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(token_id: felt) -> (armor_coef: felt) {
    return armor_coef.read(token_id);
}

// @notice Get the protection point coefficient of an enemy
// @param token_id: the id of the enemy in the collection
// @return protection_points_coef: the protection points base coefficient
@view
func get_protection_points_coef{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(token_id: felt) -> (protection_points_coef: felt) {
    return protection_points_coef.read(token_id);
}

// @notice Get the damage coefficient of an enemy
// @param token_id: the id of the enemy in the collection
// @return damage_coef: the damage base coefficient
@view
func get_damage_coef{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(token_id: felt) -> (damage_coef: felt) {
    return damage_coef.read(token_id);
}

// @notice Get the based health points of an enemy
// @param token_id: the id of the enemy in the collection
// @return health_points: the enemy's base health points
@view
func get_health_points{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(token_id: felt) -> (health_points: felt) {
    return health_points.read(token_id);
}

//
// Internals
//

func _fill_action_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: felt
) -> (action_list: (felt, felt, felt, felt, felt, felt, felt, felt)) {
    alloc_locals;
    local action_list: (felt, felt, felt, felt, felt, felt, felt, felt);

    // You can't iterate over a tuple since they only accept constant value
    let (packed_action) = action.read(token_id, 0);
    action_list[0] = packed_action;
    let (packed_action) = action.read(token_id, 1);
    action_list[1] = packed_action;
    let (packed_action) = action.read(token_id, 2);
    action_list[2] = packed_action;
    let (packed_action) = action.read(token_id, 3);
    action_list[3] = packed_action;
    let (packed_action) = action.read(token_id, 4);
    action_list[4] = packed_action;
    let (packed_action) = action.read(token_id, 5);
    action_list[5] = packed_action;
    let (packed_action) = action.read(token_id, 6);
    action_list[6] = packed_action;
    let (packed_action) = action.read(token_id, 7);
    action_list[7] = packed_action;

    return (action_list=action_list);
}