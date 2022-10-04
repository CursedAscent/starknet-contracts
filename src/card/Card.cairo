%lang starknet

from src.utils.constants import TokenRef

// Card entity
struct Card {
    card_ref: TokenRef,
    id: felt,
    action: felt,
    class: felt,
    rarity: felt,
    drawable: felt,
}
