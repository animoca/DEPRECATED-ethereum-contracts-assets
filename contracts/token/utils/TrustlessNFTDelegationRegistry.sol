// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {INFTDelegationManager, INFTDelegationRegistry} from "./INFTDelegationRegistry.sol";

contract TrustlessNFTDelegationRegistry is INFTDelegationRegistry {
    mapping(address => mapping(INFTDelegationManager => bool)) public registeredDelegationManagers;
    mapping(address => mapping(uint256 => INFTDelegationManager)) public override lastDelegationManagerUsed;

    function registerDelegationManager(
        address nftContract,
        INFTDelegationManager delegationManager,
        bool registered
    ) external virtual override {
        require(_hasRegistrationPermission(msg.sender, nftContract), "not allowed");
        registeredDelegationManagers[nftContract][delegationManager] = registered;
    }

    function onSingleDelegation(
        address owner,
        address user,
        address nftContract,
        uint256 tokenId,
        bytes calldata data
    ) external override {
        INFTDelegationManager delegationManager = INFTDelegationManager(msg.sender);
        require(registeredDelegationManagers[nftContract][delegationManager], "not allowed");
        lastDelegationManagerUsed[nftContract][tokenId] = delegationManager;
        emit SingleDelegation(owner, user, nftContract, tokenId, delegationManager, data);
    }

    function onBatchDelegation(
        address owner,
        address user,
        address nftContract,
        uint256[] calldata tokenIds,
        bytes calldata data
    ) external override {
        INFTDelegationManager delegationManager = INFTDelegationManager(msg.sender);
        require(registeredDelegationManagers[nftContract][delegationManager], "not allowed");
        for (uint256 i; i != tokenIds.length; ++i) {
            lastDelegationManagerUsed[nftContract][tokenIds[i]] = delegationManager;
        }
        emit BatchDelegation(owner, user, nftContract, tokenIds, delegationManager, data);
    }

    function delegationInfo(address nftContract, uint256 tokenId)
        external
        view
        override
        returns (
            address owner,
            address user,
            bytes memory data
        )
    {
        INFTDelegationManager delegationManager = lastDelegationManagerUsed[nftContract][tokenId];
        if (address(delegationManager) != address(0) && registeredDelegationManagers[nftContract][delegationManager]) {
            (owner, user, data) = delegationManager.delegationInfo(nftContract, tokenId);
        }
    }

    function _hasRegistrationPermission(address sender, address nftContract) internal virtual returns (bool) {
        return sender == nftContract || sender == IERC173Owner(nftContract).owner();
    }
}

interface IERC173Owner {
    function owner() external view returns (address);
}
