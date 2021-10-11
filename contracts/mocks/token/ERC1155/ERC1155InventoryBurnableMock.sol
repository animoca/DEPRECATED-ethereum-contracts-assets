// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {ManagedIdentity, Recoverable} from "@animoca/ethereum-contracts-core-1.1.2/contracts/utils/Recoverable.sol";
import {IForwarderRegistry, UsingUniversalForwarding} from "ethereum-universal-forwarder-1.0.0/src/solc_0.7/ERC2771/UsingUniversalForwarding.sol";
// solhint-disable-next-line max-line-length
import {IERC165, IERC1155, IERC1155MetadataURI, IERC1155InventoryBurnable, ERC1155InventoryBurnable} from "../../../token/ERC1155/ERC1155InventoryBurnable.sol";
import {IERC1155InventoryMintable} from "../../../token/ERC1155/IERC1155InventoryMintable.sol";
import {IERC1155InventoryCreator} from "../../../token/ERC1155/IERC1155InventoryCreator.sol";
import {BaseMetadataURI} from "../../../metadata/BaseMetadataURI.sol";
import {MinterRole} from "@animoca/ethereum-contracts-core-1.1.2/contracts/access/MinterRole.sol";

/**
 * @title ERC1155 Inventory Burnable Mock.
 */
contract ERC1155InventoryBurnableMock is
    Recoverable,
    UsingUniversalForwarding,
    ERC1155InventoryBurnable,
    IERC1155InventoryMintable,
    IERC1155InventoryCreator,
    BaseMetadataURI,
    MinterRole
{
    constructor(IForwarderRegistry forwarderRegistry, address universalForwarder)
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
    function uri(uint256 id) external view virtual override returns (string memory) {
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

    //============================================== ERC1155InventoryMintable ===============================================//

    /// @inheritdoc IERC1155InventoryMintable
    /// @dev Reverts if the sender is not a minter.
    function safeMint(
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public virtual override {
        _requireMinter(_msgSender());
        _safeMint(to, id, value, data);
    }

    /// @inheritdoc IERC1155InventoryMintable
    /// @dev Reverts if the sender is not a minter.
    function safeBatchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public virtual override {
        _requireMinter(_msgSender());
        _safeBatchMint(to, ids, values, data);
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
