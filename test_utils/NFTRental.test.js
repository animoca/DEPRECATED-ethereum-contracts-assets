const {artifacts, accounts, web3} = require('hardhat');
const {BN, expectRevert, expectEvent, time} = require('@openzeppelin/test-helpers');
const {constants} = require('@animoca/ethereum-contracts-core');
const {Zero, One, Two, Three, MaxUInt256, ZeroAddress} = constants;
const {createFixtureLoader} = require('@animoca/ethereum-contracts-core/test/utils/fixture');

const [deployer, participant1, participant2, other] = accounts;

const token1 = '1';
const token2 = '2';

describe('NFTRental', function () {
  const fixtureLoader = createFixtureLoader(accounts, web3.eth.currentProvider);
  const fixture = async function () {
    const registry = await artifacts.require('ForwarderRegistry').new({from: deployer});
    const forwarder = await artifacts.require('UniversalForwarder').new({from: deployer});
    this.erc20 = await artifacts
      .require('ERC20Mock')
      .new([participant1, participant2], ['10000000', '10000000'], registry.address, forwarder.address, {from: deployer});
    this.nft = await artifacts.require('ERC721Mock').new(registry.address, forwarder.address, {from: deployer});
    await this.nft.batchMint(participant1, [token1, token2], {from: deployer});
    this.rental = await artifacts.require('NFTRental').new(registry.address, forwarder.address, this.nft.address, {from: deployer});
    await this.erc20.approve(this.rental.address, await this.erc20.balanceOf(participant2), {from: participant2});
  };

  beforeEach(async function () {
    await fixtureLoader(fixture, this);
  });

  describe('onERC71Received (create rental offer)', function () {
    it('reverts if the the NFT contract is incorrect', async function () {
      const otherNft = await artifacts.require('ERC721Mock').new({from: deployer});
      await otherNft.batchMint(participant1, [token1, token2], {from: deployer});
      const rentalData = web3.eth.abi.encodeParameters(['address', 'uint256'], [this.erc20.address, One]);
      await expectRevert(
        otherNft.methods['safeTransferFrom(address,address,uint256,bytes)'](participant1, this.rental.address, token1, rentalData, {
          from: participant1,
        }),
        'NFTRental: wrong NFT contract'
      );
    });

    it('sets the rental offer', async function () {
      const rentalData = web3.eth.abi.encodeParameters(['address', 'uint256'], [this.erc20.address, One]);
      await this.nft.methods['safeTransferFrom(address,address,uint256,bytes)'](participant1, this.rental.address, token1, rentalData, {
        from: participant1,
      });
      const rentalOffer = await this.rental.rentalOffers(token1);
      rentalOffer.owner.should.be.equal(participant1);
      rentalOffer.paymentToken.should.be.equal(this.erc20.address);
      rentalOffer.dailyPrice.should.be.bignumber.equal(One);
    });
  });

  describe('rent', function () {
    const price = One;
    const rentalPeriod = Two;

    beforeEach(async function () {
      const rentalData = web3.eth.abi.encodeParameters(['address', 'uint256'], [this.erc20.address, price]);
      await this.nft.methods['safeTransferFrom(address,address,uint256,bytes)'](participant1, this.rental.address, token1, rentalData, {
        from: participant1,
      });
    });

    it('reverts if the NFT does not have a rental offer', async function () {
      await expectRevert(this.rental.rent(token2, rentalPeriod, {from: participant2}), 'NFTRental: not for rent');
    });

    it('reverts if the owner tries to self rent', async function () {
      await expectRevert(this.rental.rent(token1, rentalPeriod, {from: participant1}), 'NFTRental: self rental');
    });

    it('reverts if the token is already rented', async function () {
      await this.rental.rent(token1, rentalPeriod, {from: participant2});
      await expectRevert(this.rental.rent(token1, rentalPeriod, {from: participant2}), 'NFTRental: already rented');
    });

    context('when succesful (first rental)', function () {
      beforeEach(async function () {
        this.receipt = await this.rental.rent(token1, rentalPeriod, {from: participant2});
        this.timestamp = new BN((await web3.eth.getBlock(this.receipt.receipt.blockNumber)).timestamp);
      });

      it('creates the rental', async function () {
        const rental = await this.rental.rentals(token1);
        rental.rentee.should.be.equal(participant2);
        rental.rentalPeriod.should.be.bignumber.equal(rentalPeriod);
        rental.timestamp.should.be.bignumber.equal(this.timestamp);
      });

      it('transfers the full payment amount to the rental contract', async function () {
        await expectEvent.inTransaction(this.receipt.tx, this.erc20, 'Transfer', {
          _from: participant2,
          _to: this.rental.address,
          _value: price.mul(rentalPeriod),
        });
      });
    });

    context('when succesful (subsequent rental)', function () {
      const nextRentalPeriod = Three;
      beforeEach(async function () {
        await this.rental.rent(token1, rentalPeriod, {from: participant2});
        await time.increase(time.duration.days(rentalPeriod));
        this.receipt = await this.rental.rent(token1, nextRentalPeriod, {from: participant2});
        this.timestamp = new BN((await web3.eth.getBlock(this.receipt.receipt.blockNumber)).timestamp);
      });

      it('creates the rental', async function () {
        const rental = await this.rental.rentals(token1);
        rental.rentee.should.be.equal(participant2);
        rental.rentalPeriod.should.be.bignumber.equal(nextRentalPeriod);
        rental.timestamp.should.be.bignumber.equal(this.timestamp);
      });

      it('transfers the previous payment amount to the NFT owner', async function () {
        await expectEvent.inTransaction(this.receipt.tx, this.erc20, 'Transfer', {
          _from: this.rental.address,
          _to: participant1,
          _value: price.mul(rentalPeriod),
        });
      });

      it('transfers the full payment amount to the rental contract', async function () {
        await expectEvent.inTransaction(this.receipt.tx, this.erc20, 'Transfer', {
          _from: participant2,
          _to: this.rental.address,
          _value: price.mul(nextRentalPeriod),
        });
      });
    });
  });
});
