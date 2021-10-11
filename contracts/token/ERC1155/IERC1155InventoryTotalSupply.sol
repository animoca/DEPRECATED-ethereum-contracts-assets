// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC1155 Inventory, optional extension: Total Supply.
 * @dev See https://eips.ethereum.org/EIPS/eip-xxxx
 * @dev Note: The ERC-165 identifier for this interface is 0xbd85b039.
 */
interface IERC1155InventoryTotalSupply {
    /**
     * Retrieves the total supply of `id`.
     * @param id The identifier for which to retrieve the supply of.
     * @return
     *  If `id` represents a collection (Fungible Token or Non-Fungible Collection), the total supply for this collection.
     *  If `id` represents a Non-Fungible Token, 1 if the token exists, else 0.
     */
    function totalSupply(uint256 id) external view returns (uint256);
}
