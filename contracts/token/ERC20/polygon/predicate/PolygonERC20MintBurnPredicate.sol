// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {ManagedIdentity} from "@animoca/ethereum-contracts-core/contracts/metatx/ManagedIdentity.sol";
import {PolygonERC20PredicateBase} from "./PolygonERC20PredicateBase.sol";

/**
 * @title ERC20 Mint/Burn Predicate (for Polygon).
 * Polygon bridging ERC20 minting/burning predicate which works with a `Withdrawn(address account, uint256 value)` event.
 * @dev This contract should be deployed on the Root Chain (Ethereum).
 * @dev Warning: this predicate must be used only for mintable and burnable tokens.
 */
contract PolygonERC20MintBurnPredicate is ManagedIdentity, PolygonERC20PredicateBase {
    // @inheritdoc PolygonERC20PredicateBase
    constructor(address rootChainManager_) PolygonERC20PredicateBase(rootChainManager_) {}

    //==================================================== TokenPredicate ===================================================//

    /**
     * Burns ERC20 tokens for deposit.
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
        require(IERC20BurnableMintable(rootToken).burnFrom(depositor, amount), "Predicate: burn failed");
    }

    /**
     * Validates the {Withdrawn} log signature, then mints the correct amount to withdrawer.
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
        IERC20BurnableMintable(rootToken).mint(withdrawer, amount);
    }
}

interface IERC20BurnableMintable {
    function burnFrom(address from, uint256 value) external returns (bool);

    function mint(address to, uint256 value) external;
}
