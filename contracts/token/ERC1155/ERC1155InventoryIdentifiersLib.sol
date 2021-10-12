// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC1155InventoryIdentifiersLib, a library to introspect inventory identifiers.
 * @dev With 0 < N < 256 representing the Non-Fungible Collection mask length, identifiers are represented as follow:
 * (a) a Fungible Token:
 *     - most significant bit == 0
 * (b) a Non-Fungible Collection:
 *     - most significant bit == 1
 *     - (256-N) least significant bits == 0
 * (c) a Non-Fungible Token:
 *     - most significant bit == 1
 *     - (256-N) least significant bits != 0
 */
library ERC1155InventoryIdentifiersLib {
    // Non-Fungible bit. If an id has this bit set, it is a Non-Fungible (either Collection or Token)
    uint256 internal constant _NF_BIT = 1 << 255;

    function isFungibleToken(uint256 id) internal pure returns (bool) {
        return id & _NF_BIT == 0;
    }

    function isNonFungibleToken(uint256 id, uint256 collectionMaskLength) internal pure returns (bool) {
        return id & _NF_BIT != 0 && id & _getNonFungibleTokenMask(collectionMaskLength) != 0;
    }

    function getNonFungibleCollection(uint256 nftId, uint256 collectionMaskLength) internal pure returns (uint256) {
        return nftId & ~_getNonFungibleTokenMask(collectionMaskLength);
    }

    function _getNonFungibleTokenMask(uint256 collectionMaskLength) private pure returns (uint256) {
        return (1 << (256 - collectionMaskLength)) - 1;
    }
}
