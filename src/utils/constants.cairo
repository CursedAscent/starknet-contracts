// Useful structures & constant data for the repo

%lang starknet

// Identify a token in a particuliar collection
struct TokenRef {
    collection_addr: felt,
    token_id: felt,
}

// Wrapper for a felt array
// Note: Cannot be used as a return type
struct FeltList {
    length: felt,
    elements: felt*,
}
