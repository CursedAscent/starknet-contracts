%lang starknet

from starkware.cairo.common.alloc import alloc

from src.utils.constants import TokenRef
from src.tokens.ERC721.interfaces.IERC721 import IERC721

namespace ACatalogLib {
    func get_tokens_from_collection{syscall_ptr: felt*, range_check_ptr}(
        collection_addr: felt, tokens: TokenRef*
    ) -> (token_list_len: felt) {
        alloc_locals;
        let (local tokens_len) = IERC721.total_supply(collection_addr);

        _get_tokens_from_collection(
            collection_addr, tokens_len - 1, tokens + tokens_len * TokenRef.SIZE
        );

        return (token_list_len=tokens_len);
    }

    //
    // Internals
    //

    func _get_tokens_from_collection{syscall_ptr: felt*, range_check_ptr}(
        collection_addr: felt, token_list_len: felt, token_list: felt*
    ) {
        if (token_list_len == -1) {
            return ();
        }

        // can't copy construct structure :'(
        // [token_list - TokenRef.SIZE] = TokenRef(collection_addr=collection_addr, token_id=token_list_len - 1);
        [token_list - 2] = collection_addr;
        [token_list - 1] = token_list_len;

        return _get_tokens_from_collection(
            collection_addr, token_list_len - 1, token_list - TokenRef.SIZE
        );
    }
}
