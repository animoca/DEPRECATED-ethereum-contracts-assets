// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title Child Token interface for Polygon POS portal.
 */
interface IPolygonChildToken {
    /**
     * Receive a deposit from the POS portal.
     * @dev Reverts if the sender is not the Child Chain manager.
     * @param user Address who receives the deposit.
     * @param depositData Extra data for deposit (amount for ERC20, token id for ERC721 etc.) [ABI encoded]
     */
    function deposit(address user, bytes calldata depositData) external;
}
