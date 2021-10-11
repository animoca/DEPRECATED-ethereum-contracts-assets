// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IERC1155} from "./../ERC1155/IERC1155.sol";
import {IERC1155InventoryFunctions} from "./../ERC1155/IERC1155InventoryFunctions.sol";

/**
 * @title ERC1155 Multi Token Standard, optional extension: Inventory.
 * Interface for Fungible/Non-Fungible Tokens management on an ERC1155 contract.
 *
 * This interface rationalizes the co-existence of Fungible and Non-Fungible Tokens
 * within the same contract. As several kinds of Fungible Tokens can be managed under
 * the Multi-Token standard, we consider that Non-Fungible Tokens can be classified
 * under their own specific type. We introduce the concept of Non-Fungible Collection
 * and consider the usage of 3 types of identifiers:
 * (a) Fungible Token identifiers, each representing a set of Fungible Tokens,
 * (b) Non-Fungible Collection identifiers, each representing a set of Non-Fungible Tokens (this is not a token),
 * (c) Non-Fungible Token identifiers.
 *
 * Identifiers nature
 * |       Type                | isFungible  | isCollection | isToken |
 * |  Fungible Token           |   true      |     true     |  true   |
 * |  Non-Fungible Collection  |   false     |     true     |  false  |
 * |  Non-Fungible Token       |   false     |     false    |  true   |
 *
 * Identifiers compatibilities
 * |       Type                |  transfer  |   balance    |   supply    |  owner  |
 * |  Fungible Token           |    OK      |     OK       |     OK      |   NOK   |
 * |  Non-Fungible Collection  |    NOK     |     OK       |     OK      |   NOK   |
 * |  Non-Fungible Token       |    OK      |   0 or 1     |   0 or 1    |   OK    |
 *
 * @dev See https://eips.ethereum.org/EIPS/eip-xxxx
 * @dev Note: The ERC-165 identifier for this interface is 0x09ce5c46.
 */
interface IERC1155Inventory is IERC1155, IERC1155InventoryFunctions {
    //================================================== ERC1155Inventory ===================================================//
    /**
     * Optional event emitted when a collection (Fungible Token or Non-Fungible Collection) is created.
     *  This event can be used by a client application to determine which identifiers are meaningful
     *  to track through the functions `balanceOf`, `balanceOfBatch` and `totalSupply`.
     * @dev This event MUST NOT be emitted twice for the same `collectionId`.
     */
    event CollectionCreated(uint256 indexed collectionId, bool indexed fungible);

    /**
     * Retrieves the owner of a Non-Fungible Token (ERC721-compatible).
     * @dev Reverts if `nftId` is owned by the zero address.
     * @param nftId Identifier of the token to query.
     * @return Address of the current owner of the token.
     */
    function ownerOf(uint256 nftId) external view override returns (address);

    /**
     * Introspects whether or not `id` represents a Fungible Token.
     *  This function MUST return true even for a Fungible Token which is not-yet created.
     * @param id The identifier to query.
     * @return bool True if `id` represents aFungible Token, false otherwise.
     */
    function isFungible(uint256 id) external view override returns (bool);

    /**
     * Introspects the Non-Fungible Collection to which `nftId` belongs.
     * @dev This function MUST return a value representing a Non-Fungible Collection.
     * @dev This function MUST return a value for a non-existing token, and SHOULD NOT be used to check the existence of a Non-Fungible Token.
     * @dev Reverts if `nftId` does not represent a Non-Fungible Token.
     * @param nftId The token identifier to query the collection of.
     * @return The Non-Fungible Collection identifier to which `nftId` belongs.
     */
    function collectionOf(uint256 nftId) external view override returns (uint256);

    //======================================================= ERC1155 =======================================================//

    /**
     * Retrieves the balance of `id` owned by account `owner`.
     * @param owner The account to retrieve the balance of.
     * @param id The identifier to retrieve the balance of.
     * @return
     *  If `id` represents a collection (Fungible Token or Non-Fungible Collection), the balance for this collection.
     *  If `id` represents a Non-Fungible Token, 1 if the token is owned by `owner`, else 0.
     */
    function balanceOf(address owner, uint256 id) external view override returns (uint256);

    /**
     * Retrieves the balances of `ids` owned by accounts `owners`.
     * @dev Reverts if `owners` and `ids` have different lengths.
     * @param owners The accounts to retrieve the balances of.
     * @param ids The identifiers to retrieve the balances of.
     * @return An array of elements such as for each pair `id`/`owner`:
     *  If `id` represents a collection (Fungible Token or Non-Fungible Collection), the balance for this collection.
     *  If `id` represents a Non-Fungible Token, 1 if the token is owned by `owner`, else 0.
     */
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view override returns (uint256[] memory);

    /**
     * Safely transfers some token.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if `id` does not represent a token.
     * @dev Reverts if `id` represents a Non-Fungible Token and `value` is not 1.
     * @dev Reverts if `id` represents a Non-Fungible Token and is not owned by `from`.
     * @dev Reverts if `id` represents a Fungible Token and `value` is 0.
     * @dev Reverts if `id` represents a Fungible Token and `from` has an insufficient balance.
     * @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155received} fails or is refused.
     * @dev Emits an {IERC1155-TransferSingle} event.
     * @param from Current token owner.
     * @param to Address of the new token owner.
     * @param id Identifier of the token to transfer.
     * @param value Amount of token to transfer.
     * @param data Optional data to pass to the receiver contract.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override;

    /**
     * @notice this documentation overrides its {IERC1155-safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)}.
     * Safely transfers a batch of tokens.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if one of `ids` does not represent a token.
     * @dev Reverts if one of `ids` represents a Non-Fungible Token and `value` is not 1.
     * @dev Reverts if one of `ids` represents a Non-Fungible Token and is not owned by `from`.
     * @dev Reverts if one of `ids` represents a Fungible Token and `value` is 0.
     * @dev Reverts if one of `ids` represents a Fungible Token and `from` has an insufficient balance.
     * @dev Reverts if one of `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155batchReceived} fails or is refused.
     * @dev Emits an {IERC1155-TransferBatch} event.
     * @param from Current tokens owner.
     * @param to Address of the new tokens owner.
     * @param ids Identifiers of the tokens to transfer.
     * @param values Amounts of tokens to transfer.
     * @param data Optional data to pass to the receiver contract.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override;
}
