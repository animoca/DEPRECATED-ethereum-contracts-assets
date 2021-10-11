// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IChildToken} from "@animoca/ethereum-contracts-core-1.1.2/contracts/bridging/IChildToken.sol";
import {IERC20Receiver, ERC20Receiver} from "../token/ERC20/ERC20Receiver.sol";

/**
 * @title ERC20 Child Token Base (for Polygon).
 * Polygon bridging ERC20 child token which emits a `Withdrawn(address account, uint256 value)` event on exit.
 * @dev This contract should be deployed on the Child Chain (Polygon).
 * @dev The function `deposit(address,bytes)` needs to be implemented by a child contract.
 * @dev A function `withdraw(uint256)` can be implemented by a child contract to better integrate with Polygon bridge website.
 */
abstract contract ChildERC20Base is IChildToken, ERC20Receiver {
    event Withdrawn(address account, uint256 value);

    // see https://github.com/maticnetwork/pos-portal/blob/master/contracts/child/ChildChainManager/ChildChainManager.sol
    address public childChainManager;

    /**
     * Constructor
     * @param childChainManager_ the Polygon/MATIC ChildChainManager proxy address.
     */
    constructor(address childChainManager_) {
        childChainManager = childChainManager_;
    }

    //============================================== Helper Internal Functions ==============================================//

    function _requireDepositorRole(address account) internal view {
        require(account == childChainManager, "ChildERC20: only depositor");
    }
}
