// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {Ownable} from "@animoca/ethereum-contracts-core-1.1.2/contracts/access/Ownable.sol";
import {TrustlessNFTDelegationRegistry} from "./TrustlessNFTDelegationRegistry.sol";

contract OwnableNFTDelegationRegistry is TrustlessNFTDelegationRegistry, Ownable {
    constructor() Ownable(msg.sender) {}

    function _hasRegistrationPermission(address sender, address nftContract) internal virtual override returns (bool) {
        return super._hasRegistrationPermission(sender, nftContract) || sender == owner();
    }
}
