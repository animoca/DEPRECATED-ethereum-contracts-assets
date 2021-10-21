// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IForwarderRegistry} from "ethereum-universal-forwarder/src/solc_0.7/ERC2771/IForwarderRegistry.sol";
import {IERC1155} from "./../interfaces/IERC1155.sol";
import {IERC1155InventoryBurnable} from "./../interfaces/IERC1155InventoryBurnable.sol";
import {ManagedIdentity} from "@animoca/ethereum-contracts-core/contracts/metatx/ManagedIdentity.sol";
import {UsingUniversalForwarding} from "ethereum-universal-forwarder/src/solc_0.7/ERC2771/UsingUniversalForwarding.sol";
import {ERC1155InventoryBurnableMock} from "./ERC1155InventoryBurnableMock.sol";
import {Pausable} from "@animoca/ethereum-contracts-core/contracts/lifecycle/Pausable.sol";

/**
 * @title ERC1155 Inventory Pausable Mock.
 * @dev The minting functions are usable while paused as it can be useful for contract maintenance such as contract migration.
 */
contract ERC1155InventoryPausableMock is Pausable, ERC1155InventoryBurnableMock {
    constructor(
        IForwarderRegistry forwarderRegistry,
        address universalForwarder,
        uint256 collectionMaskLength
    ) ERC1155InventoryBurnableMock(forwarderRegistry, universalForwarder, collectionMaskLength) Pausable(false) {}

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

    //======================================================= ERC1155 =======================================================//

    /// @inheritdoc IERC1155
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

    /// @inheritdoc IERC1155
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

    //============================================== ERC1155InventoryBurnable ===============================================//

    /// @inheritdoc IERC1155InventoryBurnable
    /// @dev Reverts if the contract is paused.
    function burnFrom(
        address from,
        uint256 id,
        uint256 value
    ) public virtual override {
        _requireNotPaused();
        super.burnFrom(from, id, value);
    }

    /// @inheritdoc IERC1155InventoryBurnable
    /// @dev Reverts if the contract is paused.
    function batchBurnFrom(
        address from,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual override {
        _requireNotPaused();
        super.batchBurnFrom(from, ids, values);
    }

    //======================================== Meta Transactions Internal Functions =========================================//

    function _msgSender() internal view virtual override(ManagedIdentity, ERC1155InventoryBurnableMock) returns (address payable) {
        return UsingUniversalForwarding._msgSender();
    }

    function _msgData() internal view virtual override(ManagedIdentity, ERC1155InventoryBurnableMock) returns (bytes memory ret) {
        return UsingUniversalForwarding._msgData();
    }
}
