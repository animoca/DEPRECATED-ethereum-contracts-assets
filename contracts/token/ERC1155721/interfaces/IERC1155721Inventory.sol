// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IERC1155} from "./../../ERC1155/interfaces/IERC1155.sol";
import {IERC1155Inventory} from "./../../ERC1155/interfaces/IERC1155Inventory.sol";
import {IERC721} from "./../../ERC721/interfaces/IERC721.sol";
import {IERC721BatchTransfer} from "./../../ERC721/interfaces/IERC721BatchTransfer.sol";

/**
 * @title ERC1155 Inventory with support for ERC721 and EC721BatchTransfer.
 */
interface IERC1155721Inventory is IERC1155Inventory, IERC721, IERC721BatchTransfer {
    //======================================================= ERC721 ========================================================//

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /**
     * Unsafely transfers a Non-Fungible Token.
     * @dev Usage of this method is discouraged, use `safeTransferFrom` whenever possible
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if `nftId` is not owned by `from`.
     * @dev Reverts if `to` is an IERC1155TokenReceiver contract which refuses the receiver call.
     * @dev Resets the ERC721 single token approval.
     * @dev Emits an {IERC721-Transfer} event.
     * @dev Emits an {IERC1155-TransferSingle} event.
     * @param from Current token owner.
     * @param to Address of the new token owner.
     * @param nftId Identifier of the token to transfer.
     */
    function transferFrom(
        address from,
        address to,
        uint256 nftId
    ) external override;

    /**
     * Safely transfers a Non-Fungible Token.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if `nftId` is not owned by `from`.
     * @dev Reverts if `to` is a contract which does not implement IERC1155TokenReceiver or IERC721Receiver.
     * @dev Reverts if `to` is an IERC1155TokenReceiver or IERC721Receiver contract which refuses the transfer.
     * @dev Resets the ERC721 single token approval.
     * @dev Emits an {IERC721-Transfer} event.
     * @dev Emits an {IERC1155-TransferSingle} event.
     * @param from Current token owner.
     * @param to Address of the new token owner.
     * @param nftId Identifier of the token to transfer.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 nftId
    ) external override;

    /**
     * Safely transfers a Non-Fungible Token.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if `nftId` is not owned by `from`.
     * @dev Reverts if `to` is a contract which does not implement IERC1155TokenReceiver or IERC721Receiver.
     * @dev Reverts if `to` is an IERC1155TokenReceiver or IERC721Receiver contract which refuses the transfer.
     * @dev Resets the ERC721 single token approval.
     * @dev Emits an {IERC721-Transfer} event.
     * @dev Emits an {IERC1155-TransferSingle} event.
     * @param from Current token owner.
     * @param to Address of the new token owner.
     * @param nftId Identifier of the token to transfer.
     * @param data Optional data to pass to the receiver contract.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 nftId,
        bytes calldata data
    ) external override;

    //================================================= ERC721BatchTransfer =================================================//

    /**
     * Unsafely transfers a batch of Non-Fungible Tokens.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if one of `nftIds` is not owned by `from`.
     * @dev Reverts if `to` is an IERC1155TokenReceiver which refuses the transfer.
     * @dev Resets the token approval for each of `nftIds`.
     * @dev Emits an {IERC721-Transfer} event for each of `nftIds`.
     * @dev Emits an {IERC1155-TransferBatch} event.
     * @param from Current tokens owner.
     * @param to Address of the new tokens owner.
     * @param nftIds Identifiers of the tokens to transfer.
     */
    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata nftIds
    ) external override;

    //======================================================= ERC1155 =======================================================//

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
     * @dev Resets the ERC721 single token approval if `id` represents a Non-Fungible Token.
     * @dev Emits an {IERC721-Transfer} event if `id` represents a Non-Fungible Token.
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
     * Safely transfers a batch of tokens.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if one of `ids` does not represent a token.
     * @dev Reverts if one of `ids` represents a Non-Fungible Token and `value` is not 1.
     * @dev Reverts if one of `ids` represents a Non-Fungible Token and is not owned by `from`.
     * @dev Reverts if one of `ids` represents a Fungible Token and `value` is 0.
     * @dev Reverts if one of `ids` represents a Fungible Token and `from` has an insufficient balance.
     * @dev Reverts if one of `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155batchReceived} fails or is refused.
     * @dev Resets the ERC721 single token approval for each transferred Non-Fungible Token.
     * @dev Emits an {IERC721-Transfer} event for each transferred Non-Fungible Token.
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

    //================================================== ERC721 && ERC1155 ==================================================//

    /// @inheritdoc IERC1155
    function setApprovalForAll(address operator, bool approved) external override(IERC1155, IERC721);

    /// @inheritdoc IERC1155
    function isApprovedForAll(address owner, address operator) external view override(IERC1155, IERC721) returns (bool);

    //============================================= ERC721 && ERC1155Inventory ==============================================//

    /// @inheritdoc IERC1155Inventory
    function ownerOf(uint256 nftId) external view override(IERC1155Inventory, IERC721) returns (address);
}
