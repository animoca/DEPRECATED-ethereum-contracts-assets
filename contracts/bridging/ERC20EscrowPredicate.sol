// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IERC20} from "../token/ERC20/IERC20.sol";
import {Ownable, ERC20BasePredicate} from "./ERC20BasePredicate.sol";

contract ERC20EscrowPredicate is ERC20BasePredicate {
    constructor() Ownable(msg.sender) {}

    /**
     * Locks ERC20 tokens for deposit.
     * @dev Reverts if not called by the manager (RootChainManager).
     * @param depositor Address who wants to deposit tokens.
     * @param depositReceiver Address (address) who wants to receive tokens on child chain.
     * @param rootToken Token which gets deposited.
     * @param depositData ABI encoded amount.
     */
    function lockTokens(
        address depositor,
        address depositReceiver,
        address rootToken,
        bytes calldata depositData
    ) external override {
        _requireManagerRole(_msgSender());
        uint256 amount = abi.decode(depositData, (uint256));
        emit LockedERC20(depositor, depositReceiver, rootToken, amount);
        IERC20(rootToken).transferFrom(depositor, address(this), amount);
    }

    /**
     * Validates the {Withdrawn} log signature, then sends the correct amount to withdrawer.
     * @dev Reverts if not called only by the manager (RootChainManager).
     * @param rootToken Token which gets withdrawn
     * @param log Valid ERC20 burn log from child chain
     */
    function exitTokens(
        address,
        address rootToken,
        bytes memory log
    ) public override {
        _requireManagerRole(_msgSender());
        (address withdrawer, uint256 amount) = _verifyWithdrawalLog(log);
        require(IERC20(rootToken).transfer(withdrawer, amount), "Predicate: transfer failed");
    }
}
