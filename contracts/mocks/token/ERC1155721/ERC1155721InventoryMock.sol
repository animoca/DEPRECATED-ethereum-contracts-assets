// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {ERC1155721Inventory} from "../../../token/ERC1155721/ERC1155721Inventory.sol";
import {IERC1155721InventoryMintable} from "../../../token/ERC1155721/IERC1155721InventoryMintable.sol";
import {IERC1155721InventoryDeliverable} from "../../../token/ERC1155721/IERC1155721InventoryDeliverable.sol";
import {IERC1155InventoryCreator} from "../../../token/ERC1155/IERC1155InventoryCreator.sol";
import {BaseMetadataURI} from "../../../metadata/BaseMetadataURI.sol";
import {MinterRole} from "@animoca/ethereum-contracts-core-1.0.0/contracts/access/MinterRole.sol";

contract ERC1155721InventoryMock is
    ERC1155721Inventory,
    IERC1155721InventoryMintable,
    IERC1155721InventoryDeliverable,
    IERC1155InventoryCreator,
    BaseMetadataURI,
    MinterRole
{
    constructor() ERC1155721Inventory("ERC1155721InventoryMock", "INV") MinterRole(msg.sender) {}

    // ===================================================================================================
    //                                 User Public Functions
    // ===================================================================================================

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC1155InventoryCreator).interfaceId || super.supportsInterface(interfaceId);
    }

    //================================== ERC1155MetadataURI =======================================/

    /// @dev See {IERC1155MetadataURI-uri(uint256)}.
    function uri(uint256 id) public view virtual override returns (string memory) {
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

    //================================== ERC1155721InventoryMintable =======================================/

    /**
     * Unsafely mints a Non-Fungible Token (ERC721-compatible).
     * @dev See {IERC1155721InventoryMintable-mint(address,uint256)}.
     */
    function mint(address to, uint256 nftId) external virtual override {
        _requireMinter(_msgSender());
        _mint(to, nftId, "", false);
    }

    /**
     * Unsafely mints a batch of Non-Fungible Tokens (ERC721-compatible).
     * @dev See {IERC1155721InventoryMintable-batchMint(address,uint256[])}.
     */
    function batchMint(address to, uint256[] calldata nftIds) external virtual override {
        _requireMinter(_msgSender());
        _batchMint(to, nftIds);
    }

    /**
     * Safely mints a Non-Fungible Token (ERC721-compatible).
     * @dev See {IERC1155721InventoryMintable-safeMint(address,uint256,bytes)}.
     */
    function safeMint(
        address to,
        uint256 nftId,
        bytes calldata data
    ) external virtual override {
        _requireMinter(_msgSender());
        _mint(to, nftId, data, true);
    }

    /**
     * Safely mints somme token (ERC1155-compatible).
     * @dev See {IERC1155721InventoryMintable-safeMint(address,uint256,uint256,bytes)}.
     */
    function safeMint(
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external virtual override {
        _requireMinter(_msgSender());
        _safeMint(to, id, value, data);
    }

    /**
     * Safely mints a batch of tokens (ERC1155-compatible).
     * @dev See {IERC1155721InventoryMintable-safeBatchMint(address,uint256[],uint256[],bytes)}.
     */
    function safeBatchMint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external virtual override {
        _requireMinter(_msgSender());
        _safeBatchMint(to, ids, values, data);
    }

    /**
     * Safely mints tokens to recipients.
     * @dev See {IERC1155721InventoryDeliverable-safeDeliver(address[],uint256[],uint256[],bytes)}.
     */
    function safeDeliver(
        address[] calldata recipients,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external virtual override {
        _requireMinter(_msgSender());
        _safeDeliver(recipients, ids, values, data);
    }
}
