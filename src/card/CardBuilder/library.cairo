// Helper functions to create Card instances

%lang starknet

from src.card.Card import Card
from src.utils.constants import TokenRef
from src.card.CardCollection.interfaces.ICardCollection import ICardCollection

namespace CardBuilderLib {
    // @notice Builds a partial Card instance from its token data. Its id must be set downstream
    // @param card_ref: The card's token ids
    // @return card: The partial card entity
    func build_partial_card{syscall_ptr: felt*, range_check_ptr}(card_ref: TokenRef) -> (
        card: Card
    ) {
        alloc_locals;

        let (local packed_action) = ICardCollection.get_action(
            contract_address=card_ref.collection_addr, token_id=card_ref.token_id
        );
        let (local class) = ICardCollection.get_class(
            contract_address=card_ref.collection_addr, token_id=card_ref.token_id
        );
        let (local rarity) = ICardCollection.get_rarity(
            contract_address=card_ref.collection_addr, token_id=card_ref.token_id
        );

        local card: Card = Card(
            card_ref=card_ref,
            id=-1,
            action=packed_action,
            class=class,
            rarity=rarity,
            drawable=1
            );

        return (card=card);
    }
}
