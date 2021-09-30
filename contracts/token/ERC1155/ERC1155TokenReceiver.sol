// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IERC165} from "@animoca/ethereum-contracts-core-1.1.2/contracts/introspection/IERC165.sol";
import {IERC1155TokenReceiver} from "./IERC1155TokenReceiver.sol";

/**
 * @title ERC1155 Transfers Receiver Contract.
 * @dev The functions `onERC1155Received(address,address,uint256,uint256,bytes)`
 *  and `onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)` need to be implemented by a child contract.
 */
abstract contract ERC1155TokenReceiver is IERC165, IERC1155TokenReceiver {
    // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 internal constant _ERC1155_RECEIVED = 0xf23a6e61;

    // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
    bytes4 internal constant _ERC1155_BATCH_RECEIVED = 0xbc197c81;

    bytes4 internal constant _ERC1155_REJECTED = 0xffffffff;

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC1155TokenReceiver).interfaceId;
    }
}
