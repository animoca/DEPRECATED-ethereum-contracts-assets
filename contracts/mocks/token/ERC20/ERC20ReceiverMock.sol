// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {ERC20Receiver} from "../../../token/ERC20/ERC20Receiver.sol";

contract ERC20ReceiverMock is ERC20Receiver {
    event ERC20Received(address sender, address from, uint256 value, bytes data, uint256 gas);

    bool internal _accept20;

    constructor(bool accept20) {
        _accept20 = accept20;
    }

    function onERC20Received(
        address sender,
        address from,
        uint256 value,
        bytes memory data
    ) public virtual override returns (bytes4) {
        if (_accept20) {
            emit ERC20Received(sender, from, value, data, gasleft());
            return _ERC20_RECEIVED;
        } else {
            return _ERC20_REJECTED;
        }
    }
}
