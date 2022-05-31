// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IERC20} from "./interfaces/IERC20.sol";
import {ManagedIdentity} from "@animoca/ethereum-contracts-core/contracts/metatx/ManagedIdentity.sol";

/**
 * @title ERC20 Fungible Token Contract, simple implementation.
 */
contract ERC20Simple is ManagedIdentity, IERC20 {
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    uint256 internal _totalSupply;

    //======================================================== ERC20 ========================================================//

    /// @inheritdoc IERC20
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /// @inheritdoc IERC20
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    /// @inheritdoc IERC20
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /// @inheritdoc IERC20
    function approve(address spender, uint256 value) external virtual override returns (bool) {
        _approve(_msgSender(), spender, value);
        return true;
    }

    /// @inheritdoc IERC20
    function transfer(address to, uint256 value) external virtual override returns (bool) {
        _transfer(_msgSender(), to, value);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external virtual override returns (bool) {
        _transferFrom(_msgSender(), from, to, value);
        return true;
    }

    //============================================ High-level Internal Functions ============================================//

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal {
        require(spender != address(0), "ERC20: zero address spender");
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _decreaseAllowance(
        address owner,
        address spender,
        uint256 subtractedValue
    ) internal {
        uint256 allowance_ = _allowances[owner][spender];

        if (allowance_ != type(uint256).max && subtractedValue != 0) {
            // save gas when allowance is maximal by not reducing it (see https://github.com/ethereum/EIPs/issues/717)
            uint256 newAllowance = allowance_ - subtractedValue;
            require(newAllowance < allowance_, "ERC20: insufficient allowance");
            _allowances[owner][spender] = newAllowance;
            allowance_ = newAllowance;
        }
        emit Approval(owner, spender, allowance_);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual {
        require(to != address(0), "ERC20: to zero address");

        if (value != 0) {
            uint256 balance = _balances[from];
            uint256 newBalance = balance - value;
            require(newBalance < balance, "ERC20: insufficient balance");
            if (from != to) {
                _balances[from] = newBalance;
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    function _transferFrom(
        address sender,
        address from,
        address to,
        uint256 value
    ) internal {
        if (from != sender) {
            _decreaseAllowance(from, sender, value);
        }
        _transfer(from, to, value);
    }

    function _mint(address to, uint256 value) internal virtual {
        require(to != address(0), "ERC20: mint to zero");
        if (value != 0) {
            uint256 supply = _totalSupply;
            uint256 newSupply = supply + value;
            require(newSupply > supply, "ERC20: supply overflow");
            _totalSupply = newSupply;
            _balances[to] += value; // balance cannot overflow if supply does not
        }
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal virtual {
        if (value != 0) {
            uint256 balance = _balances[from];
            uint256 newBalance = balance - value;
            require(newBalance < balance, "ERC20: insufficient balance");
            _balances[from] = newBalance;
            _totalSupply -= value; // will not underflow if balance does not
        }
        emit Transfer(from, address(0), value);
    }

    function _burnFrom(address from, uint256 value) internal virtual {
        address sender = _msgSender();
        if (from != sender) {
            _decreaseAllowance(from, sender, value);
        }
        _burn(from, value);
    }
}
