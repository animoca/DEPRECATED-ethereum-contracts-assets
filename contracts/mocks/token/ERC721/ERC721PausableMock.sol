// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IForwarderRegistry, UsingUniversalForwarding} from "ethereum-universal-forwarder/src/solc_0.7/ERC2771/UsingUniversalForwarding.sol";
import {IERC721, IERC721Burnable, IERC721BatchTransfer, ManagedIdentity, ERC721BurnableMock} from "./ERC721BurnableMock.sol";
import {Pausable} from "@animoca/ethereum-contracts-core-1.1.2/contracts/lifecycle/Pausable.sol";

/**
 * @title ERC721 Pausable Mock.
 * @dev The minting functions are usable while paused as it can be useful for contract maintenance such as contract migration.
 */
contract ERC721PausableMock is Pausable, ERC721BurnableMock {
    constructor(IForwarderRegistry forwarderRegistry, address universalForwarder)
        ERC721BurnableMock(forwarderRegistry, universalForwarder)
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

    /// @inheritdoc IERC721
    /// @dev Reverts if the contract is paused.
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _requireNotPaused();
        super.transferFrom(from, to, tokenId);
    }

    /// @inheritdoc IERC721
    /// @dev Reverts if the contract is paused.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _requireNotPaused();
        super.safeTransferFrom(from, to, tokenId);
    }

    /// @inheritdoc IERC721
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

    /// @inheritdoc IERC721BatchTransfer
    /// @dev Reverts if the contract is paused.
    function batchTransferFrom(
        address from,
        address to,
        uint256[] memory tokenIds
    ) public virtual override {
        _requireNotPaused();
        super.batchTransferFrom(from, to, tokenIds);
    }

    //=================================================== ERC721Burnable ====================================================//

    /// @inheritdoc IERC721Burnable
    /// @dev Reverts if the contract is paused.
    function burnFrom(address from, uint256 tokenId) public virtual override {
        _requireNotPaused();
        super.burnFrom(from, tokenId);
    }

    /// @inheritdoc IERC721Burnable
    /// @dev Reverts if the contract is paused.
    function batchBurnFrom(address from, uint256[] memory tokenIds) public virtual override {
        _requireNotPaused();
        super.batchBurnFrom(from, tokenIds);
    }

    //======================================== Meta Transactions Internal Functions =========================================//

    function _msgSender() internal view virtual override(ManagedIdentity, ERC721BurnableMock) returns (address payable) {
        return UsingUniversalForwarding._msgSender();
    }

    function _msgData() internal view virtual override(ManagedIdentity, ERC721BurnableMock) returns (bytes memory ret) {
        return UsingUniversalForwarding._msgData();
    }
}
