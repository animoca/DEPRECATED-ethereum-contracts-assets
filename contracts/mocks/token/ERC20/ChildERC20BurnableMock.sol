// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {ManagedIdentity, Ownable, Recoverable} from "@animoca/ethereum-contracts-core-1.1.2/contracts/utils/Recoverable.sol";
import {IForwarderRegistry, UsingUniversalForwarding} from "ethereum-universal-forwarder/src/solc_0.7/ERC2771/UsingUniversalForwarding.sol";
import {IERC165, ChildERC20Burnable} from "../../../token/ERC20/ChildERC20Burnable.sol";
import {IERC20Mintable} from "../../../token/ERC20/IERC20Mintable.sol";
import {MinterRole} from "@animoca/ethereum-contracts-core-1.1.2/contracts/access/MinterRole.sol";

/**
 * @title Child ERC20 Burnable Mock.
 */
contract ChildERC20BurnableMock is Recoverable, UsingUniversalForwarding, ChildERC20Burnable, IERC20Mintable, MinterRole {
    constructor(
        address[] memory recipients,
        uint256[] memory values,
        address childChainManager,
        IForwarderRegistry forwarderRegistry,
        address universalForwarder
    )
        ChildERC20Burnable("Child ERC20 Mock", "CE20", 18, childChainManager)
        MinterRole(msg.sender)
        UsingUniversalForwarding(forwarderRegistry, universalForwarder)
    {
        _batchMint(recipients, values);
    }

    //================================================ ERC20Metadata (admin) ================================================//

    /**
     * Sets the token metadata URI.
     * @dev Reverts if not called by the contract owner.
     * @param tokenURI_ the new token metadata URI.
     */
    function setTokenURI(string calldata tokenURI_) external {
        _requireOwnership(_msgSender());
        _tokenURI = tokenURI_;
    }

    //================================================ ERC20Mintable (admin) ================================================//

    /// @inheritdoc IERC20Mintable
    /// @dev Reverts if the sender is not a minter.
    function mint(address to, uint256 value) public virtual override {
        _requireMinter(_msgSender());
        _mint(to, value);
    }

    /// @inheritdoc IERC20Mintable
    /// @dev Reverts if the sender is not a minter.
    function batchMint(address[] memory recipients, uint256[] memory values) public virtual override {
        _requireMinter(_msgSender());
        _batchMint(recipients, values);
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
