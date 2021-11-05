// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IERC165} from "@animoca/ethereum-contracts-core/contracts/introspection/IERC165.sol";
import {IERC20Receiver} from "./interfaces/IERC20Receiver.sol";

/**
 * @title ERC20 Safe Transfers Receiver Contract.
 * @dev The function `onERC20Received(address,address,uint256,bytes)` needs to be implemented by a child contract.
 */
abstract contract ERC20Receiver is IERC20Receiver, IERC165 {
    bytes4 internal constant _ERC20_RECEIVED = type(IERC20Receiver).interfaceId;
    bytes4 internal constant _ERC20_REJECTED = 0xffffffff;

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC20Receiver).interfaceId;
    }
}
