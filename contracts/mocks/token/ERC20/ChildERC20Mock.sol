// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IWrappedERC20, ERC20Wrapper} from "@animoca/ethereum-contracts-core-1.1.2/contracts/utils/ERC20Wrapper.sol";
import {ManagedIdentity, Ownable, Recoverable} from "@animoca/ethereum-contracts-core-1.1.2/contracts/utils/Recoverable.sol";
import {IForwarderRegistry, UsingUniversalForwarding} from "ethereum-universal-forwarder/src/solc_0.7/ERC2771/UsingUniversalForwarding.sol";
import {IERC165, ChildERC20} from "../../../token/ERC20/ChildERC20.sol";
import {IERC20Mintable} from "../../../token/ERC20/IERC20Mintable.sol";
import {MinterRole} from "@animoca/ethereum-contracts-core-1.1.2/contracts/access/MinterRole.sol";

/**
 * @title Child ERC20 Mock.
 */
contract ChildERC20Mock is Recoverable, UsingUniversalForwarding, ChildERC20, IERC20Mintable, MinterRole {
    using ERC20Wrapper for IWrappedERC20;

    uint256 internal _inEscrow;

    constructor(
        address[] memory recipients,
        uint256[] memory values,
        address childChainManager,
        IForwarderRegistry forwarderRegistry,
        address universalForwarder
    )
        ChildERC20("Child ERC20 Mock", "CE20", 18, childChainManager)
        MinterRole(msg.sender)
        UsingUniversalForwarding(forwarderRegistry, universalForwarder)
    {
        _batchMint(recipients, values);
    }

    //================================================ ERC20Metadata (admin) ================================================//

    /**
     * Sets the token metadata URI.
     * @dev Reverts if not called by the contract owner.
     * @param tokenURI_ the new token metadata URI.
     */
    function setTokenURI(string calldata tokenURI_) external {
        _requireOwnership(_msgSender());
        _tokenURI = tokenURI_;
    }

    //================================================ ERC20Mintable (admin) ================================================//

    /// @inheritdoc IERC20Mintable
    /// @dev Reverts if the sender is not a minter.
    function mint(address to, uint256 value) public virtual override {
        _requireMinter(_msgSender());
        _mint(to, value);
    }

    /// @inheritdoc IERC20Mintable
    /// @dev Reverts if the sender is not a minter.
    function batchMint(address[] memory recipients, uint256[] memory values) public virtual override {
        _requireMinter(_msgSender());
        _batchMint(recipients, values);
    }

    //===================================================== ChildERC20 ======================================================//

    /// @inheritdoc ChildERC20
    function deposit(address user, bytes calldata depositData) public virtual override {
        _inEscrow -= abi.decode(depositData, (uint256));
        super.deposit(user, depositData);
    }

    /// @inheritdoc ChildERC20
    function withdraw(uint256 amount) public virtual override {
        _inEscrow += amount;
        super.withdraw(amount);
    }

    /// @inheritdoc ChildERC20
    function onERC20Received(
        address operator,
        address from,
        uint256 amount,
        bytes calldata data
    ) public virtual override returns (bytes4) {
        _inEscrow += amount;
        return super.onERC20Received(operator, from, amount, data);
    }

    //===================================================== Recoverable =====================================================//

    /// @inheritdoc Recoverable
    /// @dev Reverts if one of `tokens` is this contract and if the amount being recovered corresponds to escrowed tokens for bridging.
    function recoverERC20s(
        address[] calldata accounts,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external virtual override {
        _requireOwnership(_msgSender());
        uint256 length = accounts.length;
        require(length == tokens.length && length == amounts.length, "Recov: inconsistent arrays");
        for (uint256 i = 0; i != length; ++i) {
            address token = tokens[i];
            uint256 amount = amounts[i];
            if (token == address(this)) {
                uint256 recoverable = _balances[address(this)] - _inEscrow;
                require(amount <= recoverable, "Recov: insufficient balance");
            }
            IWrappedERC20(token).wrappedTransfer(accounts[i], amount);
        }
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
