// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {ERC721Receiver, ERC721ReceiverMock} from "../ERC721/ERC721ReceiverMock.sol";
import {ERC1155TokenReceiver, ERC1155TokenReceiverMock} from "../ERC1155/ERC1155TokenReceiverMock.sol";

/**
 * @title ERC721 Receiver & ERC1155 Token Receiver Mock.
 */
contract ERC1155721ReceiverMock is ERC721ReceiverMock, ERC1155TokenReceiverMock {
    constructor(
        bool supports721,
        bool supports1155,
        address tokenAddress
    ) ERC721ReceiverMock(supports721, tokenAddress) ERC1155TokenReceiverMock(supports1155, tokenAddress) {}

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Receiver, ERC1155TokenReceiver) returns (bool) {
        return ERC721Receiver.supportsInterface(interfaceId) || ERC1155TokenReceiver.supportsInterface(interfaceId);
    }
}
