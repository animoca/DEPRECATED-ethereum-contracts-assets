// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IERC1155TokenReceiver} from "./../interfaces/IERC1155TokenReceiver.sol";
import {ERC1155TokenReceiver} from "./../ERC1155TokenReceiver.sol";

/**
 * @title ERC1155 Token Receiver Mock.
 */
contract ERC1155TokenReceiverMock is ERC1155TokenReceiver {
    event ReceivedSingle(address operator, address from, uint256 id, uint256 value, bytes data, uint256 gas);

    event ReceivedBatch(address operator, address from, uint256[] ids, uint256[] values, bytes data, uint256 gas);

    bool internal immutable _accept1155;
    address internal immutable _tokenAddress1155;

    constructor(bool accept1155, address tokenAddress) ERC1155TokenReceiver() {
        _accept1155 = accept1155;
        _tokenAddress1155 = tokenAddress;
    }

    //================================================ ERC1155TokenReceiver =================================================//

    /// @inheritdoc IERC1155TokenReceiver
    /// @dev reverts if the sender is not the supported ERC1155 contract.
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public virtual override returns (bytes4) {
        require(msg.sender == _tokenAddress1155, "ERC1155Receiver: wrong token");
        if (_accept1155) {
            emit ReceivedSingle(operator, from, id, value, data, gasleft());
            return _ERC1155_RECEIVED;
        } else {
            return _ERC1155_REJECTED;
        }
    }

    /// @inheritdoc IERC1155TokenReceiver
    /// @dev reverts if the sender is not the supported ERC1155 contract.
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public virtual override returns (bytes4) {
        require(msg.sender == _tokenAddress1155, "ERC1155Receiver: wrong token");
        if (_accept1155) {
            emit ReceivedBatch(operator, from, ids, values, data, gasleft());
            return _ERC1155_BATCH_RECEIVED;
        } else {
            return _ERC1155_REJECTED;
        }
    }
}
