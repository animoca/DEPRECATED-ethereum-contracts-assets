// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {ERC1155InventoryBurnable} from "../../../token/ERC1155/ERC1155InventoryBurnable.sol";
import {IERC1155InventoryMintable} from "../../../token/ERC1155/IERC1155InventoryMintable.sol";
import {IERC1155InventoryCreator} from "../../../token/ERC1155/IERC1155InventoryCreator.sol";
import {BaseMetadataURI} from "../../../metadata/BaseMetadataURI.sol";
import {MinterRole} from "@animoca/ethereum-contracts-core-1.1.2/contracts/access/MinterRole.sol";

contract ERC1155InventoryBurnableMock is ERC1155InventoryBurnable, IERC1155InventoryMintable, IERC1155InventoryCreator, BaseMetadataURI, MinterRole {
    constructor() MinterRole(msg.sender) {}

    // ===================================================================================================
    //                                 User Public Functions
    // ===================================================================================================

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC1155InventoryCreator).interfaceId || super.supportsInterface(interfaceId);
    }

    //================================== ERC1155MetadataURI =======================================/

    /// @dev See {IERC1155MetadataURI-uri(uint256)}.
    function uri(uint256 id) external view virtual override returns (string memory) {
        return _uri(id);
    }

    //================================== ERC1155InventoryCreator =======================================/

    /// @dev See {IERC1155InventoryCreator-creator(uint256)}.
    function creator(uint256 collectionId) external view override returns (address) {
        return _creator(collectionId);
    }

    // ===================================================================================================
    //                               Admin Public Functions
    // ===================================================================================================

    /**
     * Creates a collection.
     * @dev Reverts if the sender is not the contract owner.
     * @dev Reverts if `collectionId` does not represent a collection.
     * @dev Reverts if `collectionId` has already been created.
     * @dev Emits a {IERC1155Inventory-CollectionCreated} event.
     * @param collectionId Identifier of the collection.
     */
    function createCollection(uint256 collectionId) external {
        _requireOwnership(_msgSender());
        _createCollection(collectionId);
    }

    //================================== ERC1155InventoryMintable =======================================/

    /**
     * Safely mints some token.
     * @dev See {IERC1155InventoryMintable-safeMint(address,uint256,uint256,bytes)}.
     */
    function safeMint(
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public virtual override {
        _requireMinter(_msgSender());
        _safeMint(to, id, value, data);
    }

    /**
     * Safely mints a batch of tokens.
     * @dev See {IERC1155721InventoryMintable-safeBatchMint(address,uint256[],uint256[],bytes)}.
     */
    function safeBatchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public virtual override {
        _requireMinter(_msgSender());
        _safeBatchMint(to, ids, values, data);
    }
}
