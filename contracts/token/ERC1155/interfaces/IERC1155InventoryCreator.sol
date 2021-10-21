// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC1155 Inventory, optional extension: Creator.
 * @dev See https://eips.ethereum.org/EIPS/eip-1155
 * @dev Note: The ERC-165 identifier for this interface is 0x510b5158.
 */
interface IERC1155InventoryCreator {
    /**
     * Returns the creator of a collection, or the zero address if the collection has not been created.
     * @dev Reverts if `collectionId` does not represent a collection.
     * @param collectionId Identifier of the collection.
     * @return The creator of a collection, or the zero address if the collection has not been created.
     */
    function creator(uint256 collectionId) external view returns (address);
}
