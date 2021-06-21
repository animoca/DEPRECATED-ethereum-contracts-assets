// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {Ownable} from "@animoca/ethereum-contracts-core-1.0.1/contracts/access/Ownable.sol";
import {IChildToken} from "@animoca/ethereum-contracts-core-1.0.1/contracts/bridging/IChildToken.sol";
import {ERC20Receiver} from "../token/ERC20/ERC20Receiver.sol";

abstract contract ChildERC20Base is IChildToken, Ownable, ERC20Receiver {
    event Withdrawn(address account, uint256 value);

    address public depositor;

    function setDepositor(address childChainManager) external {
        _requireOwnership(_msgSender());
        depositor = childChainManager;
    }

    function _requireDepositorRole(address account) internal view {
        require(account == depositor, "ChildERC20: only depositor");
    }

    function test() public {
        emit Withdrawn(address(0), 0);
    }
}
