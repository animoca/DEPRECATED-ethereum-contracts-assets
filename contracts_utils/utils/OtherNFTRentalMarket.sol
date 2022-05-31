// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IWrappedERC20, ERC20Wrapper} from "@animoca/ethereum-contracts-core/contracts/utils/ERC20Wrapper.sol";
import {Pausable} from "@animoca/ethereum-contracts-core/contracts/lifecycle/Pausable.sol";
import {IRecoverableERC721, ManagedIdentity, Ownable, Recoverable} from "@animoca/ethereum-contracts-core/contracts/utils/Recoverable.sol";
import {PayoutWallet} from "@animoca/ethereum-contracts-core/contracts/payment/PayoutWallet.sol";
// import {ERC721Receiver} from "./../ERC721/ERC721Receiver.sol";
import {IForwarderRegistry, UsingUniversalForwarding} from "ethereum-universal-forwarder/src/solc_0.7/ERC2771/UsingUniversalForwarding.sol";
import {INFTDelegation} from "./INFTDelegation.sol";

contract NFTRentalMarket is Recoverable, Pausable, PayoutWallet, UsingUniversalForwarding, INFTDelegation {
    using ERC20Wrapper for IWrappedERC20;

    // todo confirm
    // event ListingCreated(
    //     address owner,
    //     uint256 tokenId,
    //     address currency,
    //     uint256 price,
    //     uint256 minimumDuration,
    //     uint256 availabilityDate,
    //     bytes delegationData
    // );

    struct Listing {
        address payable owner; // NFT owner
        address payable designatedLessee; // use the zero address for a public listing
        address currency; // native token, a whitelisted ERC20 or the zero address to disable the rental
        uint256 price; // price in currency, for each period
        uint256 minimumDuration; // in number of periods
        bytes delegationData; // additional delegation data
    }

    struct Lease {
        address payable lessee;
        uint256 startDate;
        uint256 duration; // in number of periods
        uint256 paid; // in number of periods
    }

    address public constant NATIVE_CURRENCY = address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    address public immutable nftContract;

    uint256 public immutable periodInSeconds;

    uint256 public immutable operatorShare;

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => Lease) public leases;

    mapping(address => bool) public whitelistedCurrencies;
    mapping(address => uint256) public escrowedERC20s;

    constructor(
        IForwarderRegistry forwarderRegistry,
        address nftContract_,
        uint256 periodInSeconds_,
        address payable operator,
        uint256 operatorShare_
    ) UsingUniversalForwarding(forwarderRegistry, address(0)) PayoutWallet(msg.sender, operator) Pausable(false) {
        nftContract = nftContract_;
        periodInSeconds = periodInSeconds_;
        operatorShare = operatorShare_;
    }

    //=============================================== NFTRentalMarket (admin) ===============================================//

    function addWhitelistedCurrencies(address[] calldata tokens) external {
        _requireOwnership(_msgSender());
        for (uint256 i; i != tokens.length; ++i) {
            whitelistedCurrencies[tokens[i]] = true;
        }
    }

    function pause() external {
        _requireOwnership(_msgSender());
        _pause();
    }

    function unpause() external {
        _requireOwnership(_msgSender());
        _unpause();
    }

    //=================================================== NFTRentalMarket ===================================================//

    /**
     * Rents an NFT which has a current listing for a given period.
     *  If the NFT was rented previously, transfers the remaining lease payment amount to the owner.
     * @dev Reverts if the NFT is not managed by this contract.
     * @dev Reverts if the NFT does not have a current listing.
     * @dev Reverts if the sender is the NFT owner.
     * @dev Reverts if the NFT is already rented out.
     * @dev Emits a NFTRented event.
     * @param tokenId the NFT identifier.
     * @param duration the number of periods to rent the NFT for.
     */
    function rent(uint256 tokenId, uint256 duration) external {
        _requireNotPaused();

        require(duration != 0, "NFTRental: zero duration");

        Listing memory listing = listings[tokenId];
        address payable owner = listing.owner;
        require(owner != address(0), "NFTRental: not on the market");
        address currency = listing.currency;
        require(currency != address(0), "NFTRental: rental disabled");

        address payable lessee = _msgSender();
        address payable designatedLessee = listing.designatedLessee;
        require(designatedLessee == address(0) || designatedLessee == lessee, "NFTRental: private listing");

        uint256 minimumDuration = listing.minimumDuration;
        if (minimumDuration != 0) {
            require(duration >= minimumDuration, "NFTRental: duration too short");
        }

        uint256 price = listing.price;
        Lease memory lease = leases[tokenId];
        if (lease.lessee != address(0)) {
            // there was a previous lease
            uint256 previousDuration = lease.duration;
            require(block.timestamp > lease.startDate + previousDuration * periodInSeconds, "NFTRental: already rented");

            if (price != 0) {
                // operate payout to owner for unclaimed periods
                uint256 remainingPeriodsToClaim = previousDuration - lease.paid;
                if (remainingPeriodsToClaim != 0) {
                    _transferPayout(currency, owner, remainingPeriodsToClaim * price);
                }
            }
        }

        // the first period gets paid immediately
        leases[tokenId] = Lease(lessee, block.timestamp, duration, 1);

        if (price != 0) {
            _payForRental(lessee, owner, currency, price, duration);
        }

        emit Delegated(owner, lessee, tokenId, listing.delegationData);
    }

    /**
     * Updates the lease price or disable a current lease offer for a managed NFT.
     *  If there is an active lease, it will be cancelled and the escrowed funds will be transferred to:
     *   - the NFT owner for the executed lease periods,
     *   - the lessee for the non-executed lease periods, if any.
     *
     * @dev Reverts if the sender is not the NFT owner.
     * @param tokenId the NFT identifier.
     * @param price the updated daily price, 0 means disabling the lease offer.
     */
    function updateListing(
        uint256 tokenId,
        address currency,
        uint256 price,
        uint256 minimumDuration
    ) external {
        Listing storage listing = listings[tokenId];
        address payable owner = listing.owner;
        address previousCurrency = listing.currency;
        uint256 previousPrice = listing.price;
        uint256 previousMinimumDuration = listing.minimumDuration;
        require(owner == _msgSender(), "NFTRental: not the NFT owner");

        Lease storage lease = leases[tokenId];
        uint256 duration = lease.duration;

        if (lease.lessee != address(0)) {
            // there was a previous lease
            uint256 elapsedPeriods = (block.timestamp - lease.startDate) / periodInSeconds + 1;
            require(elapsedPeriods >= previousMinimumDuration, "NFTRental: cannot cancel yet");

            if (elapsedPeriods < duration) {
                // NFT is currently rented out and has not reached the last lease period,
                // refund the remaining lease periods to the lessee and decrease the lease duration.
                lease.duration = elapsedPeriods;
                if (previousPrice != 0) {
                    _transferRefund(previousCurrency, lease.lessee, previousPrice * (duration - elapsedPeriods));
                    duration = elapsedPeriods;
                }
            }

            if (previousPrice != 0) {
                uint256 remainingPeriodsToClaim = duration - lease.paid;
                if (remainingPeriodsToClaim != 0) {
                    // operate payout to owner for unclaimed periods
                    lease.paid = duration;
                    _transferPayout(previousCurrency, owner, remainingPeriodsToClaim * previousPrice);
                }
            }
        }

        if (previousPrice != price) {
            listing.price = price;
        }
        if (previousCurrency != currency) {
            require(currency == address(0) || whitelistedCurrencies[currency], "Rental: wrong currency");
            listing.currency = currency;
        }
        if (previousMinimumDuration != minimumDuration) {
            listing.minimumDuration = minimumDuration;
        }

        // todo confirm
        // emit ListingCreated(owner, tokenId, currency, price, minimumDuration, block.timestamp, delegationData);
    }

    function cancelLeaseAsLessee(uint256 tokenId) external {
        Listing memory listing = listings[tokenId];

        Lease memory lease = leases[tokenId];
        address payable lessee = lease.lessee;
        require(lessee == _msgSender(), "NFTRental: not the lessee");

        uint256 elapsedPeriods = (block.timestamp - lease.startDate) / periodInSeconds + 1;
        require(elapsedPeriods >= listing.minimumDuration, "NFTRental: cannot cancel yet");

        uint256 duration = lease.duration;
        require(elapsedPeriods < duration, "NFTRental: lease fully executed");

        // update the lease period and refund the remaining lease periods to the lessee
        leases[tokenId].duration = elapsedPeriods;

        uint256 price = listing.price;
        if (price != 0) {
            address currency = listing.currency;
            _transferRefund(currency, lessee, price * (duration - elapsedPeriods));
            uint256 remainingPeriodsToClaim = elapsedPeriods - lease.paid;
            if (remainingPeriodsToClaim != 0) {
                // operate payout to owner for unclaimed periods
                _transferPayout(currency, listing.owner, remainingPeriodsToClaim * price);
                leases[tokenId].paid = elapsedPeriods;
            }
        }
    }

    /**
     * Claims the payout until the current period for a token.
     * This function can be called by anyone, the payout is distributed to the token owner, when applicable.
     * This function does not have any revertion logic.
     * @param tokenId the NFT identifier.
     */
    function claimPayout(uint256 tokenId) public {
        Listing memory listing = listings[tokenId];
        address payable owner = listing.owner;
        if (owner != address(0)) {
            Lease storage lease = leases[tokenId];
            uint256 duration = lease.duration;
            uint256 price = listing.price;
            if (lease.lessee != address(0) && price != 0) {
                uint256 elapsedPeriods = (block.timestamp - lease.startDate) / periodInSeconds + 1;
                duration = (elapsedPeriods < duration) ? elapsedPeriods : duration;

                uint256 remainingPeriodsToClaim = duration - lease.paid;
                if (remainingPeriodsToClaim != 0) {
                    _transferPayout(listing.currency, owner, remainingPeriodsToClaim * price);
                    lease.paid = duration;
                }
            }
        }
    }

    /**
     * Claims the payout until the current period for a batch of tokens.
     * This function can be called by anyone, the payout is distributed to the token owners, when applicable.
     * This function does not have any revertion logic.
     * @param tokenIds the NFT identifiers.
     */
    function batchClaimPayout(uint256[] calldata tokenIds) external {
        uint256 length = tokenIds.length;
        for (uint256 i; i < length; ++i) {
            claimPayout(tokenIds[i]);
        }
    }

    function _prepareTokenWithdrawal(uint256 tokenId, address payable sender) internal {
        Listing memory listing = listings[tokenId];
        address payable owner = listing.owner;
        require(owner == sender, "NFTRental: not the NFT owner");

        Lease memory lease = leases[tokenId];
        uint256 duration = lease.duration;
        if (lease.lessee != address(0)) {
            require(block.timestamp > lease.startDate + duration * periodInSeconds, "NFTRental: still rented");

            uint256 price = listing.price;
            if (price != 0) {
                uint256 remainingPeriodsToClaim = duration - lease.paid;
                if (remainingPeriodsToClaim != 0) {
                    _transferPayout(listing.currency, owner, remainingPeriodsToClaim * price);
                }
            }
            delete leases[tokenId];
        }

        delete listings[tokenId];
    }

    //==================================================== NFTDelegation ====================================================//

    function delegationInfo(uint256 tokenId)
        external
        view
        override
        returns (
            address from,
            address to,
            bytes memory delegationData
        )
    {
        Listing memory listing = listings[tokenId];
        address owner = listing.owner;
        if (owner != address(0)) {
            Lease memory lease = leases[tokenId];
            address lessee = lease.lessee;
            if (lessee != address(0) && lease.startDate + lease.duration * periodInSeconds < block.timestamp) {
                return (owner, lessee, listing.delegationData);
            }
        }
    }

    //===================================================== Recoverable =====================================================//

    function recoverERC20s(
        address[] calldata accounts,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external virtual override {
        _requireOwnership(_msgSender());
        uint256 length = accounts.length;
        require(length == tokens.length && length == amounts.length, "Recov: inconsistent arrays");
        for (uint256 i = 0; i != length; ++i) {
            address token = tokens[i];
            uint256 amount = amounts[i];
            uint256 recoverable = IERC20Balance(token).balanceOf(address(this)) - escrowedERC20s[token];
            require(amount <= recoverable, "Recov: insufficient balance");
            IWrappedERC20(token).wrappedTransfer(accounts[i], amount);
        }
    }

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
            if (recoveredContract == nftContract) {
                require(listings[tokenId].owner == address(0), "Recov: token is for rent");
            }
            IRecoverableERC721(contracts[i]).transferFrom(address(this), accounts[i], tokenId);
        }
    }

    //============================================== Helper Internal Functions ==============================================//

    function _createListing(
        address payable owner,
        address payable designatedLessee,
        uint256 tokenId,
        address currency,
        uint256 price,
        uint256 minimumDuration,
        bytes memory delegationData
    ) internal {
        require(currency == address(0) || whitelistedCurrencies[currency], "Rental: wrong currency");
        listings[tokenId] = Listing(owner, designatedLessee, currency, price, minimumDuration, delegationData);

        // todo confirm
        // emit ListingCreated(from, tokenId, currency, price, minimumDuration, block.timestamp, delegationData);
    }

    function _computePayoutSharing(uint256 amount) internal view returns (uint256 ownerAmount, uint256 operatorAmount) {
        operatorAmount = (amount * operatorShare) / 100000;
        ownerAmount = amount - operatorAmount;
    }

    function _payForRental(
        address payable lessee,
        address payable owner,
        address currency,
        uint256 price,
        uint256 duration
    ) internal {
        // compute the shares for the first period
        (uint256 ownerAmount, uint256 operatorAmount) = _computePayoutSharing(price);
        uint256 amount = price * duration; // todo safemath
        if (currency == NATIVE_CURRENCY) {
            require(msg.value >= amount, "Rental: not enough value");

            // transfer the rent for the first period to the owner
            owner.transfer(ownerAmount);
            payoutWallet.transfer(operatorAmount);

            // refund the lessee if too much value is provided
            if (msg.value > amount) {
                lessee.transfer(msg.value - amount);
            }
        } else {
            // transfer the rent for the first period to the owner
            IWrappedERC20(currency).wrappedTransferFrom(lessee, owner, ownerAmount);
            IWrappedERC20(currency).wrappedTransferFrom(lessee, payoutWallet, operatorAmount);

            // escrow the amount for the remaining periods
            if (duration != 1) {
                amount -= price;
                escrowedERC20s[currency] += amount;
                IWrappedERC20(currency).wrappedTransferFrom(lessee, address(this), amount);
            }
        }
    }

    function _transferPayout(
        address currency,
        address payable owner,
        uint256 amount
    ) internal {
        (uint256 ownerAmount, uint256 operatorAmount) = _computePayoutSharing(amount);
        if (currency == NATIVE_CURRENCY) {
            payoutWallet.transfer(operatorAmount);
            owner.transfer(ownerAmount);
        } else {
            escrowedERC20s[currency] -= amount;
            IWrappedERC20 erc20 = IWrappedERC20(currency);
            erc20.wrappedTransfer(payoutWallet, operatorAmount);
            erc20.wrappedTransfer(owner, ownerAmount);
        }
    }

    function _transferRefund(
        address currency,
        address payable lessee,
        uint256 amount
    ) internal {
        if (currency == NATIVE_CURRENCY) {
            lessee.transfer(amount);
        } else {
            escrowedERC20s[currency] -= amount;
            IWrappedERC20(currency).wrappedTransfer(lessee, amount);
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

interface IERC20Balance {
    function balanceOf(address owner) external returns (uint256);
}
