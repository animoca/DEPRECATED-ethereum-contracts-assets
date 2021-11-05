// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IERC20Receiver} from "./../interfaces/IERC20Receiver.sol";
import {ERC20Receiver} from "./../ERC20Receiver.sol";

/**
 * @title ERC20 Receiver Mock.
 */
contract ERC20ReceiverMock is ERC20Receiver {
    event ERC20Received(address sender, address from, uint256 value, bytes data, uint256 gas);

    bool internal immutable _accept;
    address internal immutable _tokenAddress;

    constructor(bool accept, address tokenAddress) {
        _accept = accept;
        _tokenAddress = tokenAddress;
    }

    //==================================================== ERC20Receiver ====================================================//

    /// @inheritdoc IERC20Receiver
    function onERC20Received(
        address sender,
        address from,
        uint256 value,
        bytes memory data
    ) public virtual override returns (bytes4) {
        require(msg.sender == _tokenAddress, "ERC20Receiver: wrong token");
        if (_accept) {
            emit ERC20Received(sender, from, value, data, gasleft());
            return _ERC20_RECEIVED;
        } else {
            return _ERC20_REJECTED;
        }
    }
}
