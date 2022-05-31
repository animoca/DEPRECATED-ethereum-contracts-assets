// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {ERC721Receiver} from "./../ERC721/ERC721Receiver.sol";
import {IForwarderRegistry, IRecoverableERC721, NFTRentalMarket} from "./NFTRentalMarket.sol";

contract ERC721RentalMarket is NFTRentalMarket, ERC721Receiver {
    constructor(
        IForwarderRegistry forwarderRegistry,
        address nftContract,
        uint256 periodInSeconds,
        address payable operator,
        uint256 operatorShare
    ) NFTRentalMarket(forwarderRegistry, nftContract, periodInSeconds, operator, operatorShare) {}

    //=================================================== ERC721Receiver ====================================================//

    /**
     * Creates a rental listing for a Non-Fungible Token. The token gets escrowed by the contract.
     * @dev Reverts if the caller is not the authorised ERC721 contract.
     * @dev Emits a ListingCreated event.
     * @param from the NFT owner.
     * @param tokenId the NFT identifier.
     * @param data the abi-encoded data representing the lease arguments.
     */
    function onERC721Received(
        address, /* operator*/
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        _requireNotPaused();
        require(msg.sender == address(nftContract), "NFTRental: wrong NFT contract");

        (address payable designatedLessee, address currency, uint256 price, uint256 minimumDuration, bytes memory delegationData) = abi.decode(
            data,
            (address, address, uint256, uint256, bytes)
        );

        _createListing(payable(from), designatedLessee, tokenId, currency, price, minimumDuration, delegationData);
        // deedRegistry.createDeed(from, nftContract, tokenId);

        return _ERC721_RECEIVED;
    }

    function withdrawToken(uint256 tokenId) external {
        address payable owner = _msgSender();
        _prepareTokenWithdrawal(tokenId, owner);
        IRecoverableERC721(nftContract).transferFrom(address(this), owner, tokenId);
    }

    function batchWithdrawToken(uint256[] calldata tokenIds) external {
        address payable owner = _msgSender();
        uint256 length = tokenIds.length;
        for (uint256 i; i != length; ++i) {
            uint256 tokenId = tokenIds[i];
            _prepareTokenWithdrawal(tokenId, owner);
            IRecoverableERC721(nftContract).transferFrom(address(this), owner, tokenId);
        }
    }
}
