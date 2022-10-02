// Partial interface of the ERC721 standard., used by our Collection contracts.
// For the moment there is no concept of token distribution & ownership.

%lang starknet

@contract_interface
namespace IERC721 {
    //
    // Getters:
    //

    // @notice Return the name of the token
    // @return name: the name of the token
    func name() -> (name: felt) {
    }

    // @notice Return the symbol of the token
    // @return symbol: the symbol of the token
    func symbol() -> (symbol: felt) {
    }

    // @notice Return the number of tokens in the collection
    // @return total_supply: the number of tokens in the collection
    func total_supply() -> (total_supply: felt) {
    }

    // @notice Return the URI of the given token
    // @param token_id: the id of the token
    // @return token_uri_len, token_uri: the length of the token URI, the token URI
    func tokenURI(tokenId: felt) -> (token_uri_len: felt, token_uri: felt*) {
    }
}
