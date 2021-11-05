// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IWrappedERC20, ERC20Wrapper} from "@animoca/ethereum-contracts-core/contracts/utils/ERC20Wrapper.sol";
import {IERC1155TokenReceiver} from "./../ERC1155/interfaces/IERC1155TokenReceiver.sol";
import {IERC1155InventoryBurnable} from "./../ERC1155/interfaces/IERC1155InventoryBurnable.sol";
import {Ownable} from "@animoca/ethereum-contracts-core/contracts/access/Ownable.sol";
import {Recoverable} from "@animoca/ethereum-contracts-core/contracts/utils/Recoverable.sol";
import {ERC1155TokenReceiver} from "./../ERC1155/ERC1155TokenReceiver.sol";

/**
 * @title ERC1155 Vouchers Redeemer.
 * An ERC1155TokenReceiver contract used to redeem (burn) vouchers for their representative value in a given ERC20 token.
 * @dev The function `_voucherValue(uint256)` needs to be implemented by a child contract.
 */
abstract contract ERC1155VouchersRedeemer is ERC1155TokenReceiver, Recoverable {
    using ERC20Wrapper for IWrappedERC20;

    IERC1155InventoryBurnable public immutable vouchers;
    IWrappedERC20 public immutable deliverable;
    address public tokenHolder;

    /**
     * Constructor.
     * @param vouchers_ the address of the vouchers contract.
     * @param deliverable_ the address of the ERC20 token contract.
     * @param tokenHolder_ the address of the ERC20 token holder.
     */
    constructor(
        IERC1155InventoryBurnable vouchers_,
        IWrappedERC20 deliverable_,
        address tokenHolder_
    ) Ownable(msg.sender) {
        vouchers = vouchers_;
        deliverable = deliverable_;
        tokenHolder = tokenHolder_;
    }

    /**
     * Called for redeeming one type of vouchers.
     * @dev Reverts if the sender is not the vouchers contract.
     * @dev Reverts if the amount of ERC20 token to deliver overflows.
     * @dev Reverts if the token holder does not have enough ERC20 balance.
     * @dev Reverts if this contract does not have enough ERC20 allowance from the token holder.
     * @dev Emits an {IERC1155-TransferSingle} event for the burning of the voucher(s).
     * @dev Emits an {IERC20-Transfer} event for the for the delivery of the ERC20.
     * @inheritdoc IERC1155TokenReceiver
     */
    function onERC1155Received(
        address, /*operator*/
        address from,
        uint256 id,
        uint256 value,
        bytes calldata /*data*/
    ) external virtual override returns (bytes4) {
        require(msg.sender == address(vouchers), "Redeemer: wrong sender");
        vouchers.burnFrom(address(this), id, value);
        uint256 voucherValue = _voucherValue(id);
        uint256 tokenAmount = voucherValue * value;
        require(tokenAmount / voucherValue == value, "Redeemer: amount overflow");
        deliverable.wrappedTransferFrom(tokenHolder, from, tokenAmount);
        return _ERC1155_RECEIVED;
    }

    /**
     * Called for redeeming several types of vouchers.
     * @dev Reverts if the sender is not the vouchers contract.
     * @dev Reverts if an individual amount of ERC20 token to deliver overflows.
     * @dev Reverts if the total amount of ERC20 token to deliver overflows.
     * @dev Reverts if the token holder does not have enough ERC20 balance.
     * @dev Reverts if this contract does not have enough ERC20 allowance from the token holder.
     * @dev Emits an {IERC1155-TransferBatch} event for the burning of the voucher(s).
     * @dev Emits an {IERC20-Transfer} event for the for the delivery of the ERC20.
     * @inheritdoc IERC1155TokenReceiver
     */
    function onERC1155BatchReceived(
        address, /*operator*/
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata /*data*/
    ) external virtual override returns (bytes4) {
        require(msg.sender == address(vouchers), "Redeemer: wrong sender");
        vouchers.batchBurnFrom(address(this), ids, values);
        uint256 tokenAmount;
        for (uint256 i; i != ids.length; ++i) {
            uint256 id = ids[i];
            uint256 value = values[i];
            uint256 voucherValue = _voucherValue(id);
            uint256 amount = voucherValue * value;
            require(amount / voucherValue == value, "Redeemer: amount overflow");
            uint256 newAmount = tokenAmount + amount;
            require(newAmount >= tokenAmount, "Redeemer: amount overflow");
            tokenAmount = newAmount;
        }
        deliverable.wrappedTransferFrom(tokenHolder, from, tokenAmount);
        return _ERC1155_BATCH_RECEIVED;
    }

    /**
     * Sets the token holder address.
     * @dev Reverts if the sender is not the contract owner.
     * @param tokenHolder_ the new address for the token holder.
     */
    function setTokenHolder(address tokenHolder_) external virtual {
        _requireOwnership(_msgSender());
        tokenHolder = tokenHolder_;
    }

    /**
     * Validates the validity of the voucher for a specific redeemer deployment and returns the value of the voucher.
     * @dev Reverts if the voucher is not valid for this redeemer.
     * @param tokenId the id of the voucher.
     * @return the value of the voucher in ERC20 token.
     */
    function _voucherValue(uint256 tokenId) internal view virtual returns (uint256);
}
