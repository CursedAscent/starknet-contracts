// Interface of the CardCollection contract.
// It's an NFT where each token is a card, with its associated data.
// Each token is a couple of on-chain and off-chain data usable by any game.
// For the moment there is no concept of token distribution & ownership.

%lang starknet

@contract_interface
namespace ICardCollection {
    //
    // Getters:
    //

    // @notice Return the number of tokens in the collection
    // @return total_supply: the number of tokens in the collection
    func total_supply() -> (total_supply: felt) {
    }

    // @notice Get the action of the card
    // @param token_id: the id of the card in the collection
    // @return packed_action: a packed, on-chain description of the card action
    func get_action(token_id: felt) -> (packed_action: felt) {
    }

    // @notice Get the class associated with the given card
    // @param token_id: the id of the card in the collection
    // @return class: the identifier of the class (as a AdventurerClassEnum)
    func get_class(token_id: felt) -> (class: felt) {
    }

    // @notice Get the rarity of the card
    // @param token_id: the id of the card in the collection
    // @return rarity: the rarity value (as a RarityTypeEnum)
    func get_rarity(token_id: felt) -> (rarity: felt) {
    }

    // @notice Return the name of the token
    // @return name: the name of the token
    func name() -> (name: felt) {
    }

    // @notice Return the symbol of the token
    // @return symbol: the symbol of the token
    func symbol() -> (symbol: felt) {
    }

    // @notice Return the URI of the given token
    // @param token_id: the id of the token
    // @return tokenURI: the URI of the token
    func tokenURI(tokenId: felt) -> (tokenURI: felt) {
    }
}
