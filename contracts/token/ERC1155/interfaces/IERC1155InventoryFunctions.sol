// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC1155 Multi Token Standard, optional extension: Inventory.
 * Interface for Fungible/Non-Fungible Tokens management on an ERC1155 contract.
 * @dev See https://eips.ethereum.org/EIPS/eip-xxxx
 * @dev Note: The ERC-165 identifier for this interface is 0x09ce5c46.
 */
interface IERC1155InventoryFunctions {
    function ownerOf(uint256 nftId) external view returns (address);

    function isFungible(uint256 id) external view returns (bool);

    function collectionOf(uint256 nftId) external view returns (uint256);
}
