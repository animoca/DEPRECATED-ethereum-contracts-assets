// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {INFTDelegationManager} from "./INFTDelegationManager.sol";

interface INFTDelegationRegistry is INFTDelegationManager {
    function registerDelegationManager(
        address nftContract,
        INFTDelegationManager delegationManager,
        bool registered
    ) external;

    function onSingleDelegation(
        address owner,
        address user,
        address nftContract,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function onBatchDelegation(
        address owner,
        address user,
        address nftContract,
        uint256[] calldata tokenIds,
        bytes calldata data
    ) external;

    function lastDelegationManagerUsed(address nftContract, uint256 tokenId) external view returns (INFTDelegationManager);
}
