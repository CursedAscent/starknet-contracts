%lang starknet

from src.session.Session import Session
from src.card.Card import Card

using GameState = (session: Session, card_deck_len: felt, card_deck: Card*);
