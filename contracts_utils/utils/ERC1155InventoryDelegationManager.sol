// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IWrappedERC20, ERC20Wrapper} from "@animoca/ethereum-contracts-core/contracts/utils/ERC20Wrapper.sol";
import {IRecoverableERC721, ManagedIdentity, Ownable, Recoverable} from "@animoca/ethereum-contracts-core/contracts/utils/Recoverable.sol";
import {IForwarderRegistry, UsingUniversalForwarding} from "ethereum-universal-forwarder/src/solc_0.7/ERC2771/UsingUniversalForwarding.sol";
import {ERC1155TokenReceiver} from "./../ERC1155/ERC1155TokenReceiver.sol";
import {INFTDelegationManager, INFTDelegationRegistry} from "./INFTDelegationRegistry.sol";

contract ERC1155InventoryDelegationManager is Recoverable, UsingUniversalForwarding, ERC1155TokenReceiver, INFTDelegationManager {
    struct Delegation {
        address from;
        address to;
        bytes delegationData;
    }

    INFTDelegationRegistry public immutable nftDelegationRegistry;
    IDelegatableERC1155Inventory public immutable nftContract;

    mapping(uint256 => Delegation) public _delegations;

    constructor(
        IForwarderRegistry forwarderRegistry,
        IDelegatableERC1155Inventory nftContract_,
        INFTDelegationRegistry nftDelegationRegistry_
    ) UsingUniversalForwarding(forwarderRegistry, address(0)) Ownable(msg.sender) {
        nftContract = nftContract_;
        nftDelegationRegistry = nftDelegationRegistry_;
    }

    //=================================================== ERC1155Receiver ===================================================//

    /**
     * Delegates a Non-Fungible Token to an account.
     * @dev Reverts if the sender is not the authorised ERC1155 Inventory contract.
     * @dev Reverts if `id` is not a Non-Fungible Token.
     * @dev Emits a Delegated event.
     * @param from the Non-Fungible Token owner.
     * @param id the Non-Fungible Token identifier.
     * @param data free-form data which can carry additional delegation data.
     */
    function onERC1155Received(
        address, /* operator*/
        address from,
        uint256 id,
        uint256, /* value*/
        bytes calldata data
    ) external override returns (bytes4) {
        require(msg.sender == address(nftContract), "Delegator: wrong contract");
        require(!nftContract.isFungible(id), "Delegator: only NFTs");

        (address to, bytes memory delegationData) = abi.decode(data, (address, bytes));

        _delegations[id] = Delegation(from, to, delegationData);
        nftDelegationRegistry.onSingleDelegation(from, to, address(nftContract), id, data);
        // emit Delegated(from, to, id, delegationData);

        return _ERC1155_RECEIVED;
    }

    /**
     * Delegates a batch of Non-Fungible Tokens to an account.
     * @dev Reverts if the sender is not the authorised ERC1155 Inventory contract.
     * @dev Reverts if one of `ids` is not a Non-Fungible Token.
     * @dev Emits a BatchDelegated event.
     * @param from the Non-Fungible Tokens owner.
     * @param ids the Non-Fungible Tokens identifiers.
     * @param data free-form data which can carry additional delegation data.
     */
    function onERC1155BatchReceived(
        address, /* operator*/
        address from,
        uint256[] calldata ids,
        uint256[] calldata, /* values*/
        bytes calldata data
    ) external override returns (bytes4) {
        require(msg.sender == address(nftContract), "Delegator: wrong contract");

        (address to, bytes memory delegationData) = abi.decode(data, (address, bytes));
        uint256 length = ids.length;

        for (uint256 i; i != length; ++i) {
            uint256 id = ids[i];
            require(!nftContract.isFungible(id), "Delegator: only NFTs");
            _delegations[id] = Delegation(from, to, delegationData);
        }

        nftDelegationRegistry.onBatchDelegation(from, to, address(nftContract), ids, data);

        return _ERC1155_BATCH_RECEIVED;
    }

    //==================================================== NFTDelegator =====================================================//

    function endDelegation(uint256 tokenId) external {
        address sender = _msgSender();
        require(sender == _delegations[tokenId].from, "Delegator: not the token owner");
        delete _delegations[tokenId];
        nftContract.safeTransferFrom(address(this), sender, tokenId, 1, "");
    }

    function batchEndDelegation(uint256[] calldata tokenIds) external {
        address sender = _msgSender();

        uint256 length = tokenIds.length;
        uint256[] memory values = new uint256[](length);
        for (uint256 i; i != length; ++i) {
            uint256 tokenId = tokenIds[i];
            require(sender == _delegations[tokenId].from, "Delegator: not the token owner");
            values[i] = 1;
            delete _delegations[tokenId];
        }
        nftContract.safeBatchTransferFrom(address(this), sender, tokenIds, values, "");
    }

    //==================================================== NFTDelegation ====================================================//

    function delegationInfo(address nftContract_, uint256 tokenId)
        external
        view
        override
        returns (
            address from,
            address to,
            bytes memory delegationData
        )
    {
        if (nftContract_ == address(nftContract)) {
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
            if (recoveredContract == address(nftContract)) {
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

interface IDelegatableERC1155Inventory {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;

    function isFungible(uint256 tokenId) external view returns (bool);
}
