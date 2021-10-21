// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC1155 Inventory with support for ERC721, optional extension: Burnable.
 * @dev The ERC721 Burnable function `burnFrom(address,uint256)` is not provided
 *  the ERC1155 Burnable function `burnFrom(address,uint256,uint256)` can be used instead.
 * @dev Note: The ERC-165 identifier for this interface is 0x6059f1b4.
 */
interface IERC1155721InventoryBurnable {
    /**
     * Burns some token (ERC1155-compatible).
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if `id` does not represent a token.
     * @dev Reverts if `id` represents a Fungible Token and `value` is 0.
     * @dev Reverts if `id` represents a Fungible Token and `value` is higher than `from`'s balance.
     * @dev Reverts if `id` represents a Non-Fungible Token and `value` is not 1.
     * @dev Reverts if `id` represents a Non-Fungible Token which is not owned by `from`.
     * @dev Emits an {IERC721-Transfer} event to the zero address if `id` represents a Non-Fungible Token.
     * @dev Emits an {IERC1155-TransferSingle} event to the zero address.
     * @param from Address of the current token owner.
     * @param id Identifier of the token to burn.
     * @param value Amount of token to burn.
     */
    function burnFrom(
        address from,
        uint256 id,
        uint256 value
    ) external;

    /**
     * Burns multiple tokens (ERC1155-compatible).
     * @dev Reverts if `ids` and `values` have different lengths.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if one of `ids` does not represent a token.
     * @dev Reverts if one of `ids` represents a Fungible Token and `value` is 0.
     * @dev Reverts if one of `ids` represents a Fungible Token and `value` is higher than `from`'s balance.
     * @dev Reverts if one of `ids` represents a Non-Fungible Token and `value` is not 1.
     * @dev Reverts if one of `ids` represents a Non-Fungible Token which is not owned by `from`.
     * @dev Emits an {IERC721-Transfer} event to the zero address for each burnt Non-Fungible Token.
     * @dev Emits an {IERC1155-TransferBatch} event to the zero address.
     * @param from Address of the current tokens owner.
     * @param ids Identifiers of the tokens to burn.
     * @param values Amounts of tokens to burn.
     */
    function batchBurnFrom(
        address from,
        uint256[] calldata ids,
        uint256[] calldata values
    ) external;

    /**
     * Burns a batch of Non-Fungible Tokens (ERC721-compatible).
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if one of `nftIds` does not represent a Non-Fungible Token.
     * @dev Reverts if one of `nftIds` is not owned by `from`.
     * @dev Emits an {IERC721-Transfer} event to the zero address for each of `nftIds`.
     * @dev Emits an {IERC1155-TransferBatch} event to the zero address.
     * @param from Current token owner.
     * @param nftIds Identifiers of the tokens to transfer.
     */
    function batchBurnFrom(address from, uint256[] calldata nftIds) external;
}
