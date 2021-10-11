// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {ManagedIdentity, Ownable, Recoverable} from "@animoca/ethereum-contracts-core-1.1.2/contracts/utils/Recoverable.sol";
import {IForwarderRegistry, UsingUniversalForwarding} from "ethereum-universal-forwarder-1.0.0/src/solc_0.7/ERC2771/UsingUniversalForwarding.sol";
import {IERC165, ERC20} from "../../../token/ERC20/ERC20.sol";
import {IERC20Mintable} from "../../../token/ERC20/IERC20Mintable.sol";
import {MinterRole} from "@animoca/ethereum-contracts-core-1.1.2/contracts/access/MinterRole.sol";

/**
 * @title ERC20 Mock.
 */
contract ERC20Mock is Recoverable, UsingUniversalForwarding, ERC20, IERC20Mintable, MinterRole {
    constructor(
        address[] memory recipients,
        uint256[] memory values,
        IForwarderRegistry forwarderRegistry,
        address universalForwarder
    ) ERC20("ERC20 Mock", "E20", 18) MinterRole(msg.sender) UsingUniversalForwarding(forwarderRegistry, universalForwarder) {
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
