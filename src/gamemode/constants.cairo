%lang starknet

from src.session.Session import Session

using GameState = (session: Session, card_deck_len: felt, card_deck: felt*);
