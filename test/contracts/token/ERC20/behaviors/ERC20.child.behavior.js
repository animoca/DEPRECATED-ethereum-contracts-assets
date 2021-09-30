const {accounts, web3} = require('hardhat');
const {createFixtureLoader} = require('@animoca/ethereum-contracts-core/test/utils/fixture');
const {BN, expectEvent, expectRevert} = require('@openzeppelin/test-helpers');

const {behaviors, constants} = require('@animoca/ethereum-contracts-core');
const {Zero, One, Two, MaxUInt256, ZeroAddress} = constants;
const interfaces20 = require('../../../../../src/interfaces/ERC165/ERC20');
const {AbiCoder} = require('ethers/utils');

const abi = new AbiCoder();

function shouldBehaveLikeChildERC20(implementation) {
  const {revertMessages, deploy, features} = implementation;
  const [deployer, owner, spender] = accounts;

  const initialSupply = new BN(100);

  describe('like a Child ERC20', function () {
    const fixtureLoader = createFixtureLoader(accounts, web3.eth.currentProvider);
    const fixture = async function () {
      this.token = await deploy([owner], [initialSupply], deployer);
    };

    beforeEach(async function () {
      await fixtureLoader(fixture, this);
    });

    describe('deposit(address,bytes)', function () {
      const depositData = abi.encode(['uint256'], ['1']);

      it('reverts if not called by the ChildChainManager', async function () {
        await expectRevert(this.token.deposit(owner, depositData, {from: owner}), revertMessages.NonDepositor);
      });

      if (implementation.methods['burnFrom(address,uint256)'] == undefined) {
        it('reverts if there is not enough quantity escrowed', async function () {
          await expectRevert(this.token.deposit(owner, depositData, {from: deployer}), revertMessages.TransferExceedsBalance);
        });
      }

      context('when successful', function () {
        beforeEach(async function () {
          await this.token.withdraw(One, {from: owner});
          this.supply = await this.token.totalSupply();
          this.balance = await this.token.balanceOf(owner);
          this.receipt = await this.token.deposit(owner, depositData, {from: deployer});
        });

        if (implementation.methods['burnFrom(address,uint256)'] != undefined) {
          it('mints tokens to the depositor', async function () {
            (await this.token.totalSupply()).should.be.bignumber.equal(this.supply.add(One));
            (await this.token.balanceOf(this.token.address)).should.be.bignumber.equal(Zero);
            (await this.token.balanceOf(owner)).should.be.bignumber.equal(this.balance.add(One));
          });
        } else {
          it('transfers tokens from the escrow to the depositor', async function () {
            (await this.token.totalSupply()).should.be.bignumber.equal(this.supply);
            (await this.token.balanceOf(this.token.address)).should.be.bignumber.equal(Zero);
            (await this.token.balanceOf(owner)).should.be.bignumber.equal(this.balance.add(One));
          });
        }
      });
    });

    describe('withdraw with withdraw(uint256)', function () {
      it('reverts if the withdrawer has an insufficient balance', async function () {
        await expectRevert(this.token.withdraw('100000000000000', {from: owner}), revertMessages.TransferExceedsBalance);
      });

      context('when successful', function () {
        beforeEach(async function () {
          this.supply = await this.token.totalSupply();
          this.balance = await this.token.balanceOf(owner);
          this.receipt = await this.token.withdraw(One, {from: owner});
        });

        if (implementation.methods['burnFrom(address,uint256)'] != undefined) {
          it('burns the tokens', async function () {
            (await this.token.totalSupply()).should.be.bignumber.equal(this.supply.sub(One));
            (await this.token.balanceOf(this.token.address)).should.be.bignumber.equal(Zero);
            (await this.token.balanceOf(owner)).should.be.bignumber.equal(this.balance.sub(One));
          });
        } else {
          it('transfers the tokens to the escrow', async function () {
            (await this.token.totalSupply()).should.be.bignumber.equal(this.supply);
            (await this.token.balanceOf(this.token.address)).should.be.bignumber.equal(One);
            (await this.token.balanceOf(owner)).should.be.bignumber.equal(this.balance.sub(One));
          });
        }

        it('emits a Withdrawn event', async function () {
          expectEvent(this.receipt, 'Withdrawn', {
            account: owner,
            value: One,
          });
        });
      });
    });

    describe('withdraw with onERC20Received()', function () {
      it('reverts if the withdrawer has an insufficient balance', async function () {
        await expectRevert(
          this.token.safeTransfer(this.token.address, '100000000000000', '0x00', {from: owner}),
          revertMessages.TransferExceedsBalance
        );
      });

      it('reverts if onERC20Received() is called directly', async function () {
        await expectRevert(this.token.onERC20Received(owner, owner, One, '0x00', {from: owner}), revertMessages.DirectReceiverCall);
      });

      context('when successful', function () {
        beforeEach(async function () {
          this.supply = await this.token.totalSupply();
          this.balance = await this.token.balanceOf(owner);
          this.receipt = await this.token.safeTransfer(this.token.address, One, '0x00', {from: owner});
        });

        if (implementation.methods['burnFrom(address,uint256)'] != undefined) {
          it('burns the tokens', async function () {
            (await this.token.totalSupply()).should.be.bignumber.equal(this.supply.sub(One));
            (await this.token.balanceOf(this.token.address)).should.be.bignumber.equal(Zero);
            (await this.token.balanceOf(owner)).should.be.bignumber.equal(this.balance.sub(One));
          });
        } else {
          it('transfers the tokens to the escrow', async function () {
            (await this.token.totalSupply()).should.be.bignumber.equal(this.supply);
            (await this.token.balanceOf(this.token.address)).should.be.bignumber.equal(One);
            (await this.token.balanceOf(owner)).should.be.bignumber.equal(this.balance.sub(One));
          });
        }

        it('emits a Withdrawn event', async function () {
          expectEvent.inTransaction(this.receipt.tx, this.token, 'Withdrawn', {
            account: owner,
            value: One,
          });
        });
      });
    });

    if (implementation.methods['burnFrom(address,uint256)'] == undefined && features.Recoverable) {
      describe('recoverERC20s()', function () {
        it('reverts if not sent by the contract owner', async function () {
          await expectRevert(this.token.recoverERC20s([], [this.token.address], [One], {from: owner}), revertMessages.NotContractOwner);
        });
        it('reverts with inconsistent arrays', async function () {
          await expectRevert(this.token.recoverERC20s([], [this.token.address], [One], {from: deployer}), revertMessages.RecovInconsistentArrays);
          await expectRevert(
            this.token.recoverERC20s([deployer], [this.token.address], [], {from: deployer}),
            revertMessages.RecovInconsistentArrays
          );
          await expectRevert(this.token.recoverERC20s([deployer], [], [One], {from: deployer}), revertMessages.RecovInconsistentArrays);
        });
        it('reverts if trying to recover escrowed token', async function () {
          await this.token.safeTransfer(this.token.address, One, '0x00', {from: owner});
          await expectRevert(
            this.token.recoverERC20s([deployer], [this.token.address], [One], {from: deployer}),
            revertMessages.RecovInsufficientBalance
          );
        });
        it('recovers ERC20s sent accidentally to this contract', async function () {
          await this.token.transfer(this.token.address, One, {from: owner});
          const otherToken = await deploy([owner], [initialSupply], deployer);
          await otherToken.transfer(this.token.address, One, {from: owner});
          await this.token.recoverERC20s([deployer, deployer], [this.token.address, otherToken.address], [One, One], {from: deployer});
        });
      });
    }

    behaviors.shouldSupportInterfaces([interfaces20.ERC20Receiver]);
  });
}

module.exports = {
  shouldBehaveLikeChildERC20,
};
