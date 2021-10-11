// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IWrappedERC20, ERC20Wrapper} from "@animoca/ethereum-contracts-core-1.1.2/contracts/utils/ERC20Wrapper.sol";
import {IRecoverableERC721, ManagedIdentity, Ownable, Recoverable} from "@animoca/ethereum-contracts-core-1.1.2/contracts/utils/Recoverable.sol";
import {IForwarderRegistry, UsingUniversalForwarding} from "ethereum-universal-forwarder/src/solc_0.7/ERC2771/UsingUniversalForwarding.sol";
import {ERC721Receiver} from "../ERC721/ERC721Receiver.sol";
import {INFTDelegationManager, INFTDelegationRegistry} from "./INFTDelegationRegistry.sol";

contract ERC721DelegationManager is Recoverable, UsingUniversalForwarding, ERC721Receiver, INFTDelegationManager {

    struct Delegation {
        address from;
        address to;
        bytes delegationData;
    }

    IRecoverableERC721 public immutable NFT_CONTRACT;
    INFTDelegationRegistry public immutable NFT_DELEGATION_REGISTRY;

    mapping(uint256 => Delegation) public _delegations;

    constructor(
        IForwarderRegistry forwarderRegistry,
        address universalForwarder,
        IRecoverableERC721 nftContract,
        INFTDelegationRegistry nftDelegationRegistry
    ) UsingUniversalForwarding(forwarderRegistry, universalForwarder) Ownable(msg.sender) {
        NFT_CONTRACT = nftContract;
        NFT_DELEGATION_REGISTRY = nftDelegationRegistry;
    }

    //=================================================== ERC721Receiver ====================================================//

    /**
     * Delegates an NFT to an account.
     * @dev Reverts if the sender is not the authorised ERC721 contract.
     * @dev Emits a Delegated event.
     * @param from the NFT owner.
     * @param tokenId the NFT identifier.
     * @param data free-form data which can carry additional delegation data.
     */
    function onERC721Received(
        address, /* operator*/
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        require(msg.sender == address(NFT_CONTRACT), "Delegator: wrong contract");

        (address to, bytes memory delegationData) = abi.decode(data, (address, bytes));

        _delegations[tokenId] = Delegation(from, to, delegationData);
        NFT_DELEGATION_REGISTRY.onSingleDelegation(from, to, address(NFT_CONTRACT), tokenId, data);

        return _ERC721_RECEIVED;
    }

    //==================================================== NFTDelegator =====================================================//

    function endDelegation(uint256 tokenId) external {
        address sender = _msgSender();
        require(sender == _delegations[tokenId].from, "Delegator: token not delegated");
        delete _delegations[tokenId];
        NFT_CONTRACT.transferFrom(address(this), sender, tokenId);
    }

    function batchEndDelegation(uint256[] calldata tokenIds) external {
        address sender = _msgSender();
        uint256 length = tokenIds.length;
        for (uint256 i; i != length; ++i) {
            uint256 tokenId = tokenIds[i];
            require(sender == _delegations[tokenId].from, "Delegator: token not delegated");
            delete _delegations[tokenId];
            NFT_CONTRACT.transferFrom(address(this), sender, tokenId);
        }
    }

    //==================================================== NFTDelegation ====================================================//

    function delegationInfo(address nftContract, uint256 tokenId) external view override returns (address from, address to, bytes memory delegationData) {
        if (nftContract == address(NFT_CONTRACT)) {
            Delegation memory delegation = _delegations[tokenId];
            return (delegation.from, delegation.to, delegation.delegationData);
        }
    }

    //===================================================== Recoverable =====================================================//

    function recoverERC721s(
        address[] calldata accounts,
        address[] calldata contracts,
        uint256[] calldata tokenIds
    ) external virtual override {
        _requireOwnership(_msgSender());
        uint256 length = accounts.length;
        require(length == contracts.length && length == tokenIds.length, "Recov: inconsistent arrays");
        for (uint256 i = 0; i != length; ++i) {
            uint256 tokenId = tokenIds[i];
            address recoveredContract = contracts[i];
            if (recoveredContract == address(NFT_CONTRACT)) {
                require(_delegations[tokenId].from != address(0), "Recov: token is delegated");
            }
            IRecoverableERC721(contracts[i]).transferFrom(address(this), accounts[i], tokenId);
        }
    }

    //======================================== Meta Transactions Internal Functions =========================================//

    function _msgSender() internal view virtual override(ManagedIdentity, UsingUniversalForwarding) returns (address payable) {
        return UsingUniversalForwarding._msgSender();
    }

    function _msgData() internal view virtual override(ManagedIdentity, UsingUniversalForwarding) returns (bytes memory ret) {
        return UsingUniversalForwarding._msgData();
    }
}
