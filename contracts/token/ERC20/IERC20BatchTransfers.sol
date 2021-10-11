// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC20 Token Standard, optional extension: Batch Transfers.
 * @dev See https://eips.ethereum.org/EIPS/eip-20
 * @dev Note: the ERC-165 identifier for this interface is 0xc05327e6.
 */
interface IERC20BatchTransfers {
    /**
     * Moves multiple `amounts` tokens from the caller's account to each of `recipients`.
     * @dev Reverts if `recipients` and `amounts` have different lengths.
     * @dev Reverts if one of `recipients` is the zero address.
     * @dev Reverts if the caller has an insufficient balance.
     * @dev Emits an {IERC20-Transfer} event for each individual transfer.
     * @param recipients the list of recipients to transfer the tokens to.
     * @param amounts the amounts of tokens to transfer to each of `recipients`.
     * @return a boolean value indicating whether the operation succeeded.
     */
    function batchTransfer(address[] calldata recipients, uint256[] calldata amounts) external returns (bool);

    /**
     * Moves multiple `amounts` tokens from an account to each of `recipients`.
     * @dev Reverts if `recipients` and `amounts` have different lengths.
     * @dev Reverts if one of `recipients` is the zero address.
     * @dev Reverts if `from` has an insufficient balance.
     * @dev Reverts if the sender is not `from` and has an insufficient allowance.
     * @dev Emits an {IERC20-Transfer} event for each individual transfer.
     * @dev Emits an {IERC20-Approval} event.
     * @param from The address which owns the tokens to be transferred.
     * @param recipients the list of recipients to transfer the tokens to.
     * @param amounts the amounts of tokens to transfer to each of `recipients`.
     * @return a boolean value indicating whether the operation succeeded.
     */
    function batchTransferFrom(
        address from,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external returns (bool);
}
