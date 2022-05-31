// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {ERC1155TokenReceiver} from "./../ERC1155/ERC1155TokenReceiver.sol";
import {IForwarderRegistry, NFTRentalMarket} from "./NFTRentalMarket.sol";

contract ERC1155InventoryRentalMarket is NFTRentalMarket, ERC1155TokenReceiver {
    constructor(
        IForwarderRegistry forwarderRegistry,
        address nftContract,
        uint256 periodInSeconds,
        address payable operator,
        uint256 operatorShare
    ) NFTRentalMarket(forwarderRegistry, nftContract, periodInSeconds, operator, operatorShare) {}

    //================================================ ERC1155TokenReceiver =================================================//

    /**
     * Creates a rental listing for a Non-Fungible Token. The token gets escrowed by the contract.
     * @dev Reverts if the caller is not the authorised ERC1155 Inventory contract.
     * @dev Emits a ListingCreated event.
     * @param from the NFT owner.
     * @param id the NFT identifier.
     * @param data the abi-encoded data representing the lease arguments.
     */
    function onERC1155Received(
        address, /* operator*/
        address from,
        uint256 id,
        uint256, /* value*/
        bytes calldata data
    ) external override returns (bytes4) {
        require(msg.sender == address(nftContract), "NFTRental: wrong NFT contract");
        require(!IDelegatableERC1155Inventory(nftContract).isFungible(id), "NFTRental: only NFTs");

        (address payable designatedLessee, address currency, uint256 price, uint256 minimumDuration, bytes memory delegationData) = abi.decode(
            data,
            (address, address, uint256, uint256, bytes)
        );

        _createListing(payable(from), designatedLessee, id, currency, price, minimumDuration, delegationData);

        return _ERC1155_RECEIVED;
    }

    /**
     * Creates a rental listing for a batch of Non-Fungible Token. The token(s) gets escrowed by the contract.
     * @dev Reverts if the caller is not the authorised ERC1155 Inventory contract.
     * @dev Emits a ListingCreated event for each token.
     * @param from the NFTs owner.
     * @param ids the NFTs identifiers.
     * @param data the abi-encoded data representing the lease arguments.
     */
    function onERC1155BatchReceived(
        address, /* operator*/
        address from,
        uint256[] calldata ids,
        uint256[] calldata, /* value*/
        bytes calldata data
    ) external override returns (bytes4) {
        require(msg.sender == address(nftContract), "NFTRental: wrong NFT contract");

        (address payable designatedLessee, address currency, uint256 price, uint256 minimumDuration, bytes memory delegationData) = abi.decode(
            data,
            (address, address, uint256, uint256, bytes)
        );

        for (uint256 i; i != ids.length; ++i) {
            _createListing(payable(from), designatedLessee, ids[i], currency, price, minimumDuration, delegationData);
        }

        return _ERC1155_BATCH_RECEIVED;
    }

    function withdrawToken(uint256 tokenId) external {
        address payable owner = _msgSender();
        _prepareTokenWithdrawal(tokenId, owner);
        IDelegatableERC1155Inventory(nftContract).safeTransferFrom(address(this), owner, tokenId, 1, "");
    }

    function batchWithdrawToken(uint256[] calldata tokenIds) external {
        address payable owner = _msgSender();
        uint256[] memory values = new uint256[](tokenIds.length);
        for (uint256 i; i != tokenIds.length; ++i) {
            _prepareTokenWithdrawal(tokenIds[i], owner);
            values[i] = 1;
        }
        IDelegatableERC1155Inventory(nftContract).safeBatchTransferFrom(address(this), owner, tokenIds, values, "");
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
