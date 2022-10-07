%lang starknet

from src.utils.constants import TokenRef

from src.action.constants import PackedAction

// Card entity
struct Card {
    card_ref: TokenRef,
    id: felt,
    action: PackedAction,
    class: felt,
    rarity: felt,
    drawable: felt,
}
