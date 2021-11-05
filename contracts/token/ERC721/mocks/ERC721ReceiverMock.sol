// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IERC721Receiver} from "./../interfaces/IERC721Receiver.sol";
import {ERC721Receiver} from "./../ERC721Receiver.sol";

/**
 * @title ERC721 Receiver Mock.
 */
contract ERC721ReceiverMock is ERC721Receiver {
    event Received(address operator, address from, uint256 tokenId, bytes data, uint256 gas);

    bool internal immutable _accept721;
    address internal immutable _tokenAddress721;

    constructor(bool accept721, address tokenAddress) ERC721Receiver() {
        _accept721 = accept721;
        _tokenAddress721 = tokenAddress;
    }

    //=================================================== ERC721Receiver ====================================================//

    /// @inheritdoc IERC721Receiver
    /// @dev reverts if the sender is not the supported ERC721 contract.
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public virtual override returns (bytes4) {
        require(msg.sender == _tokenAddress721, "ERC721Receiver: wrong token");
        if (_accept721) {
            emit Received(operator, from, tokenId, data, gasleft());
            return _ERC721_RECEIVED;
        } else {
            return _ERC721_REJECTED;
        }
    }
}
