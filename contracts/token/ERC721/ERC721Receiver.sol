// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IERC165} from "@animoca/ethereum-contracts-core-1.1.2/contracts/introspection/IERC165.sol";
import {IERC721Receiver} from "./IERC721Receiver.sol";

/**
 * @title ERC721 Safe Transfers Receiver Contract.
 * @dev The function `onERC721Received(address,address,uint256,bytes)` needs to be implemented by a child contract.
 */
abstract contract ERC721Receiver is IERC165, IERC721Receiver {
    bytes4 internal constant _ERC721_RECEIVED = type(IERC721Receiver).interfaceId;
    bytes4 internal constant _ERC721_REJECTED = 0xffffffff;

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC721Receiver).interfaceId;
    }
}
