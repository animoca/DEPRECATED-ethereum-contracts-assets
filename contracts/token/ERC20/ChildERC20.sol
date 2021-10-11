// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IERC165, ERC20} from "./ERC20.sol";
import {IERC20Receiver, ERC20Receiver, ChildERC20Base} from "../../bridging/ChildERC20Base.sol";

/**
 * @title ERC20 Fungible Token Contract, Child version (for Polygon).
 * Polygon bridging ERC20 child token which escrows the token and emits a `Withdrawn(address account, uint256 value)` event on exit.
 * @dev This contract should be deployed on the Child Chain (Polygon).
 */
contract ChildERC20 is ERC20, ChildERC20Base {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address childChainManager
    ) ERC20(name_, symbol_, decimals_) ChildERC20Base(childChainManager) {}

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC20, ERC20Receiver) returns (bool) {
        return ERC20.supportsInterface(interfaceId) || ERC20Receiver.supportsInterface(interfaceId);
    }

    //===================================================== ChildToken ======================================================//

    /**
     * Called when tokens have been deposited on the root chain.
     * @dev Should handle deposit by un-escrowing the required amount for user.
     * @dev Reverts if not sent by the depositor (ChildChainManager).
     * @param user address for whom deposit has been done.
     * @param depositData abi encoded amount.
     */
    function deposit(address user, bytes calldata depositData) public virtual override {
        _requireDepositorRole(_msgSender());
        uint256 amount = abi.decode(depositData, (uint256));
        _transfer(address(this), user, amount);
    }

    /**
     * Called when user wants to withdraw tokens back to the root chain.
     * @dev Should escrow user's tokens. This transaction will be verified when exiting on root chain.
     * @dev Emits a {Withdrawn} event.
     * @param amount amount of tokens to withdraw.
     */
    function withdraw(uint256 amount) public virtual {
        address sender = _msgSender();
        _transferFrom(sender, sender, address(this), amount);
        emit Withdrawn(sender, amount);
    }

    //==================================================== ERC20Receiver ====================================================//

    /**
     * Called when user wants to withdraw tokens back to the root chain (no pre-approval required).
     * @dev Should escrow user's tokens. This transaction will be verified when exiting on root chain.
     * @dev Reverts if the sender is not this contract.
     * @dev Emits a {Withdrawn} event.
     * @inheritdoc IERC20Receiver
     */
    function onERC20Received(
        address, /*operator*/
        address from,
        uint256 amount,
        bytes calldata /*data*/
    ) public virtual override returns (bytes4) {
        require(msg.sender == address(this), "ChildERC20: wrong sender");
        emit Withdrawn(from, amount);
        return _ERC20_RECEIVED;
    }
}
