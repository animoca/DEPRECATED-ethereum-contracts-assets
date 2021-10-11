// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

interface INFTDelegation {
    event Delegated(address from, address to, uint256 tokenId, bytes delegationData);
    event BatchDelegated(address from, address to, uint256[] tokenIds, bytes delegationData);

    function delegationInfo(uint256 tokenId) external view returns (address from, address to, bytes memory delegationData);
}
