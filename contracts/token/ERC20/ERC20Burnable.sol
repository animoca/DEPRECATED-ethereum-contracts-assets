// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IERC165} from "@animoca/ethereum-contracts-core/contracts/introspection/IERC165.sol";
import {IERC20Burnable} from "./interfaces/IERC20Burnable.sol";
import {ERC20} from "./ERC20.sol";

/**
 * @title ERC20 Fungible Token Contract, Burnable version.
 */
contract ERC20Burnable is ERC20, IERC20Burnable {
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) ERC20(name, symbol, decimals) {}

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC20Burnable).interfaceId || super.supportsInterface(interfaceId);
    }

    //==================================================== ERC20Burnable ====================================================//

    /// @inheritdoc IERC20Burnable
    function burn(uint256 amount) external virtual override returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    /// @inheritdoc IERC20Burnable
    function burnFrom(address from, uint256 value) external virtual override returns (bool) {
        _burnFrom(from, value);
        return true;
    }

    /// @inheritdoc IERC20Burnable
    function batchBurnFrom(address[] calldata owners, uint256[] calldata values) external virtual override returns (bool) {
        _batchBurnFrom(owners, values);
        return true;
    }
}
