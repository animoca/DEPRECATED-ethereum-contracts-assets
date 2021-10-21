// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IERC165} from "@animoca/ethereum-contracts-core/contracts/introspection/IERC165.sol";
import {IERC20Receiver} from "./../../interfaces/IERC20Receiver.sol";
import {ERC20Receiver, PolygonChildERC20Base} from "./PolygonChildERC20Base.sol";
import {ERC20Burnable} from "./../../ERC20Burnable.sol";

/**
 * @title ERC20 Fungible Token Contract, Child Burnable version (for Polygon).
 * Polygon bridging ERC20 child token which burns the token and emits a `Withdrawn(address account, uint256 value)` event on exit.
 * @dev This contract should be deployed on the Child Chain (Polygon).
 */
contract PolygonChildERC20Burnable is ERC20Burnable, PolygonChildERC20Base {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address childChainManager
    ) ERC20Burnable(name_, symbol_, decimals_) PolygonChildERC20Base(childChainManager) {}

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC20Burnable, ERC20Receiver) returns (bool) {
        return ERC20Burnable.supportsInterface(interfaceId) || ERC20Receiver.supportsInterface(interfaceId);
    }

    //===================================================== ChildToken ======================================================//

    /**
     * Called when tokens have been deposited on the root chain.
     * @dev Should handle deposit by minting the required amount for user.
     * @dev Reverts if not sent by the depositor (ChildChainManager).
     * @param user address for whom deposit has been done.
     * @param depositData abi encoded amount.
     */
    function deposit(address user, bytes calldata depositData) external override {
        _requireDepositorRole(_msgSender());
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
    }

    /**
     * Called when user wants to withdraw tokens back to the root chain.
     * @dev Should burn user's tokens. This transaction will be verified when exiting on the root chain.
     * @dev Emits a {Withdrawn} event.
     * @param amount amount of tokens to withdraw
     */
    function withdraw(uint256 amount) external {
        address sender = _msgSender();
        _burnFrom(sender, amount);
        emit Withdrawn(sender, amount);
    }

    //==================================================== ERC20Receiver ====================================================//

    /**
     * Called when user wants to withdraw tokens back to the root chain (no pre-approval required).
     * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain.
     * @dev Reverts if the sender is not this contract.
     * @dev Emits a {Withdrawn} event.
     * @inheritdoc IERC20Receiver
     */
    function onERC20Received(
        address, /*operator*/
        address from,
        uint256 amount,
        bytes calldata /*data*/
    ) external virtual override returns (bytes4) {
        require(msg.sender == address(this), "ChildERC20: wrong sender");
        _burn(address(this), amount);
        emit Withdrawn(from, amount);
        return _ERC20_RECEIVED;
    }
}
