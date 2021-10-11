// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IForwarderRegistry, UsingUniversalForwarding} from "ethereum-universal-forwarder-1.0.0/src/solc_0.7/ERC2771/UsingUniversalForwarding.sol";
// solhint-disable-next-line max-line-length
import {IERC1155721Inventory, IERC1155721InventoryBurnable, ManagedIdentity, ERC1155721InventoryBurnableMock} from "./ERC1155721InventoryBurnableMock.sol";
import {Pausable} from "@animoca/ethereum-contracts-core-1.1.2/contracts/lifecycle/Pausable.sol";

/**
 * @title ERC1155 $ ERC721 Inventory Pausable Mock.
 * @dev The minting functions are usable while paused as it can be useful for contract maintenance such as contract migration.
 */
contract ERC1155721InventoryPausableMock is Pausable, ERC1155721InventoryBurnableMock {
    constructor(IForwarderRegistry forwarderRegistry, address universalForwarder)
        ERC1155721InventoryBurnableMock(forwarderRegistry, universalForwarder)
        Pausable(false)
    {}

    //================================================== Pausable (admin) ===================================================//

    /// @dev Reverts if the sender is not the contract owner.
    function pause() external virtual {
        _requireOwnership(_msgSender());
        _pause();
    }

    /// @dev Reverts if the sender is not the contract owner.
    function unpause() external virtual {
        _requireOwnership(_msgSender());
        _unpause();
    }

    //======================================================= ERC721 ========================================================//

    /// @inheritdoc IERC1155721Inventory
    /// @dev Reverts if the contract is paused.
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _requireNotPaused();
        super.transferFrom(from, to, tokenId);
    }

    /// @inheritdoc IERC1155721Inventory
    /// @dev Reverts if the contract is paused.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _requireNotPaused();
        super.safeTransferFrom(from, to, tokenId);
    }

    /// @inheritdoc IERC1155721Inventory
    /// @dev Reverts if the contract is paused.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        _requireNotPaused();
        super.safeTransferFrom(from, to, tokenId, data);
    }

    //================================================= ERC721BatchTransfer =================================================//

    /// @inheritdoc IERC1155721Inventory
    /// @dev Reverts if the contract is paused.
    function batchTransferFrom(
        address from,
        address to,
        uint256[] memory nftIds
    ) public virtual override {
        _requireNotPaused();
        super.batchTransferFrom(from, to, nftIds);
    }

    //======================================================= ERC1155 =======================================================//

    /// @inheritdoc IERC1155721Inventory
    /// @dev Reverts if the contract is paused.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public virtual override {
        _requireNotPaused();
        super.safeTransferFrom(from, to, id, value, data);
    }

    /// @inheritdoc IERC1155721Inventory
    /// @dev Reverts if the contract is paused.
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public virtual override {
        _requireNotPaused();
        super.safeBatchTransferFrom(from, to, ids, values, data);
    }

    //============================================= ERC1155721InventoryBurnable =============================================//

    /// @inheritdoc IERC1155721InventoryBurnable
    /// @dev Reverts if the contract is paused.
    function burnFrom(
        address from,
        uint256 id,
        uint256 value
    ) public virtual override {
        _requireNotPaused();
        super.burnFrom(from, id, value);
    }

    /// @inheritdoc IERC1155721InventoryBurnable
    /// @dev Reverts if the contract is paused.
    function batchBurnFrom(
        address from,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual override {
        _requireNotPaused();
        super.batchBurnFrom(from, ids, values);
    }

    /// @inheritdoc IERC1155721InventoryBurnable
    /// @dev Reverts if the contract is paused.
    function batchBurnFrom(address from, uint256[] memory nftIds) public virtual override {
        _requireNotPaused();
        super.batchBurnFrom(from, nftIds);
    }

    //======================================== Meta Transactions Internal Functions =========================================//

    function _msgSender() internal view virtual override(ManagedIdentity, ERC1155721InventoryBurnableMock) returns (address payable) {
        return UsingUniversalForwarding._msgSender();
    }

    function _msgData() internal view virtual override(ManagedIdentity, ERC1155721InventoryBurnableMock) returns (bytes memory ret) {
        return UsingUniversalForwarding._msgData();
    }
}
