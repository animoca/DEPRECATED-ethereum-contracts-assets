// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IForwarderRegistry} from "ethereum-universal-forwarder/src/solc_0.7/ERC2771/IForwarderRegistry.sol";
import {IERC20Mintable} from "./../interfaces/IERC20Mintable.sol";
import {ManagedIdentity} from "@animoca/ethereum-contracts-core/contracts/metatx/ManagedIdentity.sol";
import {Recoverable} from "@animoca/ethereum-contracts-core/contracts/utils/Recoverable.sol";
import {UsingUniversalForwarding} from "ethereum-universal-forwarder/src/solc_0.7/ERC2771/UsingUniversalForwarding.sol";
import {MinterRole} from "@animoca/ethereum-contracts-core/contracts/access/MinterRole.sol";
import {ERC20Simple} from "./../ERC20Simple.sol";

/**
 * @title ERC20 Simple Mock.
 */
contract ERC20SimpleMock is Recoverable, UsingUniversalForwarding, ERC20Simple, MinterRole {
    constructor(IForwarderRegistry forwarderRegistry, address universalForwarder)
        MinterRole(msg.sender)
        UsingUniversalForwarding(forwarderRegistry, universalForwarder)
    {}

    //==================================================== Minting (admin) ====================================================//

    /// @dev Reverts if the sender is not a minter.
    function mint(address to, uint256 value) public virtual {
        _requireMinter(_msgSender());
        _mint(to, value);
    }

    function burn(address from, uint256 value) public virtual returns (bool) {
        _requireMinter(_msgSender());
        _burn(from, value);
        return true;
    }

    //==================================================== Burning ====================================================//

    function burn(uint256 value) public virtual returns (bool) {
        _burn(_msgSender(), value);
        return true;
    }

    function burnFrom(address from, uint256 value) public virtual returns (bool) {
        _burnFrom(from, value);
        return true;
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
