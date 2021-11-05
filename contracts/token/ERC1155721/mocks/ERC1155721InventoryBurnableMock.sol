// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IForwarderRegistry} from "ethereum-universal-forwarder/src/solc_0.7/ERC2771/IForwarderRegistry.sol";
import {IERC165} from "@animoca/ethereum-contracts-core/contracts/introspection/IERC165.sol";
import {IERC1155MetadataURI} from "./../../../token/ERC1155/interfaces/IERC1155MetadataURI.sol";
import {IERC1155InventoryCreator} from "./../../../token/ERC1155/interfaces/IERC1155InventoryCreator.sol";
import {IERC1155721InventoryMintable} from "./../interfaces/IERC1155721InventoryMintable.sol";
import {IERC1155721InventoryDeliverable} from "./../interfaces/IERC1155721InventoryDeliverable.sol";
import {IERC1155721InventoryBurnable} from "./../interfaces/IERC1155721InventoryBurnable.sol";
import {ManagedIdentity} from "@animoca/ethereum-contracts-core/contracts/metatx/ManagedIdentity.sol";
import {Recoverable} from "@animoca/ethereum-contracts-core/contracts/utils/Recoverable.sol";
import {UsingUniversalForwarding} from "ethereum-universal-forwarder/src/solc_0.7/ERC2771/UsingUniversalForwarding.sol";
import {MinterRole} from "@animoca/ethereum-contracts-core/contracts/access/MinterRole.sol";
import {ERC1155721InventoryBurnable} from "./../ERC1155721InventoryBurnable.sol";
import {NFTBaseMetadataURI} from "./../../../metadata/NFTBaseMetadataURI.sol";

/**
 * @title ERC1155 & ERC721 Inventory Burnable Mock.
 */
contract ERC1155721InventoryBurnableMock is
    Recoverable,
    UsingUniversalForwarding,
    ERC1155721InventoryBurnable,
    IERC1155721InventoryMintable,
    IERC1155721InventoryDeliverable,
    IERC1155InventoryCreator,
    NFTBaseMetadataURI,
    MinterRole
{
    constructor(
        IForwarderRegistry forwarderRegistry,
        address universalForwarder,
        uint256 collectionMaskLength
    )
        ERC1155721InventoryBurnable("ERC1155721InventoryBurnableMock", "INVB", collectionMaskLength)
        UsingUniversalForwarding(forwarderRegistry, universalForwarder)
        MinterRole(msg.sender)
    {}

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC1155InventoryCreator).interfaceId || super.supportsInterface(interfaceId);
    }

    //================================================= ERC1155MetadataURI ==================================================//

    /// @inheritdoc IERC1155MetadataURI
    function uri(uint256 id) public view virtual override returns (string memory) {
        return _uri(id);
    }

    //=============================================== ERC1155InventoryCreator ===============================================//

    /// @inheritdoc IERC1155InventoryCreator
    function creator(uint256 collectionId) external view override returns (address) {
        return _creator(collectionId);
    }

    //=========================================== ERC1155InventoryCreator (admin) ===========================================//

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

    //============================================= ERC1155721InventoryMintable =============================================//

    /// @inheritdoc IERC1155721InventoryMintable
    /// @dev Reverts if the sender is not a minter.
    function mint(address to, uint256 nftId) external virtual override {
        _requireMinter(_msgSender());
        _mint(to, nftId, "", false);
    }

    /// @inheritdoc IERC1155721InventoryMintable
    /// @dev Reverts if the sender is not a minter.
    function batchMint(address to, uint256[] calldata nftIds) external virtual override {
        _requireMinter(_msgSender());
        _batchMint(to, nftIds);
    }

    /// @inheritdoc IERC1155721InventoryMintable
    /// @dev Reverts if the sender is not a minter.
    function safeMint(
        address to,
        uint256 nftId,
        bytes calldata data
    ) external virtual override {
        _requireMinter(_msgSender());
        _mint(to, nftId, data, true);
    }

    /// @inheritdoc IERC1155721InventoryMintable
    /// @dev Reverts if the sender is not a minter.
    function safeMint(
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external virtual override {
        _requireMinter(_msgSender());
        _safeMint(to, id, value, data);
    }

    /// @inheritdoc IERC1155721InventoryMintable
    /// @dev Reverts if the sender is not a minter.
    function safeBatchMint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external virtual override {
        _requireMinter(_msgSender());
        _safeBatchMint(to, ids, values, data);
    }

    //============================================ ERC1155721InventoryDeliverable =============================================//

    /// @inheritdoc IERC1155721InventoryDeliverable
    /// @dev Reverts if the sender is not a minter.
    function safeDeliver(
        address[] calldata recipients,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external virtual override {
        _requireMinter(_msgSender());
        _safeDeliver(recipients, ids, values, data);
    }

    //======================================== Meta Transactions Internal Functions =========================================//

    function _msgSender() internal view virtual override(ManagedIdentity, UsingUniversalForwarding) returns (address payable) {
        return UsingUniversalForwarding._msgSender();
    }

    function _msgData() internal view virtual override(ManagedIdentity, UsingUniversalForwarding) returns (bytes memory ret) {
        return UsingUniversalForwarding._msgData();
    }

    //=============================================== Mock Coverage Functions ===============================================//

    function msgData() external view returns (bytes memory ret) {
        return _msgData();
    }
}
