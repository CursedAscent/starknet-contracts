%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc

from src.catalog.interfaces.ICatalog import ICatalog
from src.gamemode.constants import GameState
from src.session.Session import Session
from src.card.Card import Card
from src.card.CardBuilder.library import CardBuilderLib
from src.scene.Scene import Scene
from src.scene.SceneState import SceneState
from src.scene.SceneBuilder.library import SceneBuilderLib
from src.scene.constants import SceneTypeEnum
from src.enemy.Enemy import Enemy
from src.utils.constants import TokenRef
from src.SessionManager.library import SessionManagerLib

//
// Storage
//

@storage_var
func card_catalog() -> (card_catalog_address: felt) {
}

@storage_var
func available_cards_len(class: felt) -> (available_cards_len: felt) {
}

@storage_var
func available_cards(class: felt, index: felt) -> (card: Card) {
}

@storage_var
func scene_catalog() -> (scene_catalog_address: felt) {
}

@storage_var
func scene_list_len() -> (scene_list_len: felt) {
}

@storage_var
func scene_list(index: felt) -> (scene: Scene) {
}

@storage_var
func saved_game_state(player_addr: felt) -> (game_state_hash: felt) {
}

namespace AGameMode {
    //
    // Constructor
    //

    // Assumes that catalogs are already populated with collections for game_mode_id
    func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        game_mode_id: felt, card_catalog_addr: felt, scene_catalog_addr: felt
    ) {
        // cards
        card_catalog.write(card_catalog_addr);
        _retrieve_available_cards(card_catalog_addr, game_mode_id);

        // scenes
        scene_catalog.write(scene_catalog_addr);
        _retrieve_scene_list(scene_catalog_addr, game_mode_id);

        return ();
    }

    //
    // Getters
    //

    func get_available_cards_len{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        class: felt
    ) -> felt {
        let (available_cards_len) = available_cards_len.read(class);

        return available_cards_len;
    }

    func get_available_card{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        class: felt, index: felt
    ) -> Card {
        let (card) = available_cards.read(class, index);

        return card;
    }

    func get_available_cards{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        class: felt
    ) -> (cards_len: felt, cards: Card*) {
        alloc_locals;
        let (cards: Card*) = alloc();
        let (cards_len) = available_cards_len.read(class);

        _get_available_cards(class, cards_len, cards + cards_len * Card.SIZE);

        return (cards_len, cards);
    }

    func get_scene_list_len{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        ) -> felt {
        let (scene_list_len) = scene_list_len.read();

        return scene_list_len;
    }

    func get_scene{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        index: felt
    ) -> Scene {
        let (scene) = scene_list.read(index);

        return scene;
    }

    func get_saved_game_state{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        player_addr: felt
    ) -> felt {
        let (game_state_hash) = saved_game_state.read(player_addr);

        return game_state_hash;
    }

    //
    // Setters
    //

    func save_game_state{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        session: Session, card_deck_len: felt, card_deck: Card*
    ) -> felt {
        let hashed_game_state = SessionManagerLib.hash_state(session, card_deck_len, card_deck);

        saved_game_state.write(session.account_addr, hashed_game_state);

        return hashed_game_state;
    }

    func erase_game_state{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        player_addr: felt
    ) {
        saved_game_state.write(player_addr, 0);

        return ();
    }

    //
    // Logic
    //
    func check_stored_game_state{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        session: Session, card_deck_len: felt, card_deck: Card*
    ) -> felt {
        let hashed_game_state = SessionManagerLib.hash_state(session, card_deck_len, card_deck);

        let (game_state_hash) = saved_game_state.read(session.account_addr);
        if (game_state_hash == hashed_game_state) {
            return 1;
        } else {
            return 0;
        }
    }

    //
    // Data
    //

    func generate_empty_scene() -> SceneState {
        let EMPTY_ENEMY = Enemy(
            damage_coef=0,
            protection_points_coef=0,
            armor_coef=0,
            max_health_points=0,
            health_points=0,
            protection_points=0,
            active_effects=0,
            enemy_ref=TokenRef(0, 0),
            id=-1,
            action_list_len=0,
            action_list=(0, 0, 0, 0, 0, 0, 0, 0),
            next_action_id=0,
        );
        let scene_state = SceneState(
            0,
            (EMPTY_ENEMY, EMPTY_ENEMY, EMPTY_ENEMY, EMPTY_ENEMY, EMPTY_ENEMY, EMPTY_ENEMY, EMPTY_ENEMY, EMPTY_ENEMY),
            0,
            0,
        );

        return scene_state;
    }

    //
    // Internals
    //

    func _set_saved_game_state{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        player_addr: felt, game_state_hash: felt
    ) {
        saved_game_state.write(player_addr, game_state_hash);
    }

    func _add_collections_to_catalog{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(catalog_addr: felt, game_mode_id: felt, collections_len: felt, collections: felt*) {
        if (collections_len == 0) {
            return ();
        }

        ICatalog.add_collection(catalog_addr, game_mode_id, [collections]);

        return _add_collections_to_catalog(
            catalog_addr, game_mode_id, collections_len - 1, collections + 1
        );
    }

    func _retrieve_available_cards{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        catalog_addr: felt, game_mode_id: felt
    ) {
        let (token_list_len: felt, token_list: TokenRef*) = ICatalog.get_tokens(
            catalog_addr, game_mode_id
        );

        _store_cards(token_list_len - 1, token_list + (token_list_len - 1) * TokenRef.SIZE);

        return ();
    }

    func _retrieve_scene_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        catalog_addr: felt, game_mode_id: felt
    ) {
        let (token_list_len: felt, token_list: TokenRef*) = ICatalog.get_tokens(
            catalog_addr, game_mode_id
        );

        scene_list_len.write(token_list_len);
        _store_scenes(token_list_len - 1, token_list + (token_list_len - 1) * TokenRef.SIZE);

        return ();
    }

    func _store_cards{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_list_len: felt, token_list: TokenRef*
    ) {
        alloc_locals;

        let card_tmp: Card = CardBuilderLib.build_partial_card([token_list]);
        local card: Card = Card(
            card_tmp.card_ref, token_list_len, card_tmp.action, card_tmp.class, card_tmp.rarity, card_tmp.drawable
            );

        // NB: unsafe assertion on card tokens layout in CardCollection
        // card_id = token_list_len - (nb_of_cards_per_class * class_value)
        let card_id = token_list_len - 13 * (card.class - 1);
        available_cards.write(card.class, card_id, card);

        // NB: not optimized. we write too much on the contract state
        let (card_nb) = available_cards_len.read(card.class);
        available_cards_len.write(card.class, card_nb + 1);

        if (token_list_len == 0) {
            return ();
        }

        return _store_cards(token_list_len - 1, token_list - TokenRef.SIZE);
    }

    func _store_scenes{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_list_len: felt, token_list: TokenRef*
    ) {
        let scene: Scene = SceneBuilderLib.build_partial_scene([token_list]);

        scene_list.write(token_list_len, scene);

        if (token_list_len == 0) {
            return ();
        }

        return _store_scenes(token_list_len - 1, token_list - TokenRef.SIZE);
    }

    func _get_available_cards{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        class: felt, cards_len: felt, cards: Card*
    ) {
        if (cards_len == 0) {
            return ();
        }

        let (card) = available_cards.read(class, cards_len - 1);
        assert [cards - Card.SIZE] = card;

        return _get_available_cards(class, cards_len - 1, cards - Card.SIZE);
    }
}
