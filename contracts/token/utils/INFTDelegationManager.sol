// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

interface INFTDelegationManager {
    event SingleDelegation(address owner, address user, address nftContract, uint256 tokenId, INFTDelegationManager delegationManager, bytes data);
    event BatchDelegation(address owner, address user, address nftContract, uint256[] tokenIds, INFTDelegationManager delegationManager, bytes data);

    function delegationInfo(address nftContract, uint256 tokenId) external view returns (address owner, address user, bytes memory data);
}
