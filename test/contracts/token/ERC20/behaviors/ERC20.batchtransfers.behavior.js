const {accounts, web3} = require('hardhat');
const {createFixtureLoader} = require('@animoca/ethereum-contracts-core/test/utils/fixture');
const {expectEventWithParamsOverride} = require('@animoca/ethereum-contracts-core/test/utils/events');
const {BN, expectRevert} = require('@openzeppelin/test-helpers');

const {behaviors, constants} = require('@animoca/ethereum-contracts-core');
const {Zero, One, Two, MaxUInt256, ZeroAddress} = constants;
const interfaces20 = require('../../../../../src/interfaces/ERC165/ERC20');

function shouldBehaveLikeERC20BatchTransfers(implementation) {
  const {features, interfaces, revertMessages, eventParamsOverrides, deploy} = implementation;
  const [deployer, owner, recipient1, recipient2, spender, maxSpender] = accounts;

  describe('like a multi-transfer ERC20', function () {
    const initialSupply = new BN(100);
    const initialAllowance = initialSupply.sub(One);

    const fixtureLoader = createFixtureLoader(accounts, web3.eth.currentProvider);
    const fixture = async function () {
      this.token = await deploy([owner], [initialSupply], deployer);
      await this.token.approve(spender, initialAllowance, {from: owner});
      await this.token.approve(maxSpender, MaxUInt256, {from: owner});
    };

    beforeEach(async function () {
      await fixtureLoader(fixture, this);
    });

    describe('batchTransfer(address[],uint256[])', function () {
      const transferWasSuccessful = function (recipients, values, options) {
        let aggregatedValues = {};
        for (let i = 0; i < recipients.length; ++i) {
          const to = recipients[i];
          const value = values[i];

          it('emits a Transfer event', function () {
            expectEventWithParamsOverride(
              this.receipt,
              'Transfer',
              {
                _from: options.from,
                _to: to,
                _value: value,
              },
              eventParamsOverrides
            );
          });

          aggregatedValues[to] = aggregatedValues[to] ? aggregatedValues[to].add(value) : value;
        }

        let totalMovedBalance = Zero;
        for (const to of Object.keys(aggregatedValues)) {
          const value = aggregatedValues[to];

          if (options.from != to) {
            it('increases the recipient balance', async function () {
              (await this.token.balanceOf(to)).should.be.bignumber.equal(this.recipientBalances[to].add(value));
            });
            totalMovedBalance = totalMovedBalance.add(value);
          }
        }

        it('decreases the sender balance', async function () {
          (await this.token.balanceOf(options.from)).should.be.bignumber.equal(initialSupply.sub(totalMovedBalance));
        });

        it('does not affect the token(s) total supply', async function () {
          (await this.token.totalSupply()).should.be.bignumber.equal(initialSupply);
        });
      };

      const shouldTransferTokens = function (recipients, values) {
        const options = {from: owner};
        beforeEach(async function () {
          this.fromBalance = await this.token.balanceOf(options.from);
          this.recipientBalances = {};
          for (const to of recipients) {
            this.recipientBalances[to] = await this.token.balanceOf(to);
          }
          this.receipt = await this.token.batchTransfer(recipients, values, options);
        });
        transferWasSuccessful(recipients, values, options);
      };

      it('reverts with inconsistent arrays', async function () {
        await expectRevert(this.token.batchTransfer([recipient1], [One, One], {from: owner}), revertMessages.InconsistentArrays);
        await expectRevert(this.token.batchTransfer([recipient1, recipient1], [One], {from: owner}), revertMessages.InconsistentArrays);
      });

      it('reverts when one of the recipients is the zero address', async function () {
        await expectRevert(this.token.batchTransfer([ZeroAddress], [One], {from: owner}), revertMessages.TransferToZero);
        await expectRevert(this.token.batchTransfer([recipient1, ZeroAddress], [Zero, Zero], {from: owner}), revertMessages.TransferToZero);
      });

      it('reverts with an insufficient balance', async function () {
        await expectRevert(this.token.batchTransfer([recipient1], [initialSupply.add(One)], {from: owner}), revertMessages.TransferExceedsBalance);
        await expectRevert(this.token.batchTransfer([owner], [initialSupply.add(One)], {from: owner}), revertMessages.TransferExceedsBalance);
        await expectRevert(this.token.batchTransfer([owner, recipient1], [initialSupply, One], {from: owner}), revertMessages.TransferExceedsBalance);
      });

      it('reverts if values overflow', async function () {
        await expectRevert(
          this.token.batchTransfer([recipient1, recipient1], [One, MaxUInt256], {from: owner}),
          revertMessages.BatchTransferValuesOverflow
        );
      });

      context('when transferring an empty list', function () {
        shouldTransferTokens([], []);
      });

      context('when transferring zero values', function () {
        shouldTransferTokens([recipient1, recipient2, spender], [Zero, One, Zero]);
      });

      context('when transferring the full balance in one transfer', function () {
        shouldTransferTokens([recipient1], [initialSupply]);
      });

      context('when transferring the full balance in several transfers', function () {
        shouldTransferTokens([recipient1, recipient2], [initialSupply.sub(One), One]);
      });

      context('when transferring to the same owner', function () {
        shouldTransferTokens([recipient1, owner, spender, owner, recipient2], [Zero, One, Zero, Two, One]);
      });

      context('when transferring to the same owner where each value is under the balance but cumulates to more than balance', function () {
        shouldTransferTokens([owner, owner, owner, owner, owner], [initialSupply, initialSupply, initialSupply.sub(One), Zero, One]);
      });
    });

    describe('batchTransferFrom(address,address[],uint256[])', function () {
      context('Pre-conditions', function () {
        it('reverts when from is the zero address', async function () {
          await expectRevert(this.token.batchTransferFrom(ZeroAddress, [recipient1], [One], {from: spender}), revertMessages.TransferFromZero);
        });

        it('reverts with inconsistent arrays', async function () {
          await expectRevert(this.token.batchTransferFrom(owner, [recipient1], [One, One], {from: spender}), revertMessages.InconsistentArrays);
          await expectRevert(
            this.token.batchTransferFrom(owner, [recipient1, recipient1], [One], {from: spender}),
            revertMessages.InconsistentArrays
          );
        });

        it('reverts when one of the recipients is the zero address', async function () {
          await expectRevert(this.token.batchTransferFrom(owner, [ZeroAddress], [One], {from: spender}), revertMessages.TransferToZero);
          await expectRevert(
            this.token.batchTransferFrom(owner, [recipient1, ZeroAddress], [Zero, Zero], {from: spender}),
            revertMessages.TransferToZero
          );
        });

        it('reverts with an insufficient balance', async function () {
          await expectRevert(
            this.token.batchTransferFrom(owner, [recipient1], [initialSupply.add(One)], {from: owner}),
            revertMessages.TransferExceedsBalance
          );
          await expectRevert(
            this.token.batchTransferFrom(owner, [owner], [initialSupply.add(One)], {from: owner}),
            revertMessages.TransferExceedsBalance
          );
          await expectRevert(
            this.token.batchTransferFrom(owner, [owner, recipient1], [initialSupply, One], {from: owner}),
            revertMessages.TransferExceedsBalance
          );
        });

        it('reverts with an insufficient allowance', async function () {
          await expectRevert(
            this.token.batchTransferFrom(owner, [recipient1], [initialAllowance.add(One)], {from: spender}),
            revertMessages.TransferExceedsAllowance
          );
          await expectRevert(
            this.token.batchTransferFrom(owner, [owner], [initialAllowance.add(One)], {from: spender}),
            revertMessages.TransferExceedsAllowance
          );
          await expectRevert(
            this.token.batchTransferFrom(owner, [owner, recipient1], [initialAllowance, One], {from: spender}),
            revertMessages.TransferExceedsAllowance
          );
        });

        it('reverts if values overflow', async function () {
          await expectRevert(
            this.token.batchTransferFrom(owner, [recipient1, recipient1], [One, MaxUInt256], {from: spender}),
            revertMessages.BatchTransferValuesOverflow
          );
        });
      });

      const transferWasSuccessful = function (from, recipients, values, options, withEIP717) {
        let totalValue = Zero;
        let aggregatedValues = {};
        for (let i = 0; i < recipients.length; ++i) {
          const to = recipients[i];
          const value = values[i];
          totalValue = totalValue.add(value);

          it('emits a Transfer event', function () {
            expectEventWithParamsOverride(
              this.receipt,
              'Transfer',
              {
                _from: from,
                _to: to,
                _value: value,
              },
              eventParamsOverrides
            );
          });

          aggregatedValues[to] = aggregatedValues[to] ? aggregatedValues[to].add(value) : value;
        }

        let totalMovedBalance = Zero;
        for (const to of Object.keys(aggregatedValues)) {
          const value = aggregatedValues[to];

          if (from != to) {
            it('increases the recipient balance', async function () {
              (await this.token.balanceOf(to)).should.be.bignumber.equal(this.recipientBalances[to].add(value));
            });
            totalMovedBalance = totalMovedBalance.add(value);
          }
        }

        it('decreases the sender balance', async function () {
          (await this.token.balanceOf(from)).should.be.bignumber.equal(initialSupply.sub(totalMovedBalance));
        });

        it('does not affect the token(s) total supply', async function () {
          (await this.token.totalSupply()).should.be.bignumber.equal(initialSupply);
        });

        if (from != options.from) {
          if (withEIP717) {
            it('[EIP717] keeps allowance at max ', async function () {
              (await this.token.allowance(from, options.from)).should.be.bignumber.equal(MaxUInt256);
            });
          } else {
            it('decreases the spender allowance', async function () {
              (await this.token.allowance(from, options.from)).should.be.bignumber.equal(this.allowance.sub(totalValue));
            });
          }

          if (features.AllowanceTracking) {
            it('emits an Approval event', function () {
              expectEventWithParamsOverride(
                this.receipt,
                'Approval',
                {
                  _owner: from,
                  _spender: options.from,
                  _value: withEIP717 ? MaxUInt256 : this.allowance.sub(totalValue),
                },
                eventParamsOverrides
              );
            });
          }
        }
      };

      const shouldTransferTokens = function (recipients, values, options, withEIP717 = false) {
        const from = owner;
        beforeEach(async function () {
          this.allowance = await this.token.allowance(from, options.from);
          this.fromBalance = await this.token.balanceOf(from);
          this.recipientBalances = {};
          for (const to of recipients) {
            this.recipientBalances[to] = await this.token.balanceOf(to);
          }
          this.receipt = await this.token.batchTransferFrom(from, recipients, values, options);
        });
        transferWasSuccessful(from, recipients, values, options, withEIP717);
      };

      const shouldTransferTokensBySender = function (recipients, values) {
        context('when transfer started by the owner', function () {
          shouldTransferTokens(recipients, values, {from: owner});
        });

        context('when transfer started by an approved sender', function () {
          shouldTransferTokens(recipients, values, {from: spender});
        });

        context('when transfer started by a sender with max approval', function () {
          shouldTransferTokens(recipients, values, {from: maxSpender}, features.EIP717);
        });
      };

      context('when transferring an empty list', function () {
        shouldTransferTokensBySender([], []);
      });

      context('when transferring zero values', function () {
        shouldTransferTokensBySender([recipient1, recipient2, spender], [Zero, One, Zero]);
      });

      context('when transferring the full allowance', function () {
        shouldTransferTokensBySender([recipient1], [initialAllowance]);
        shouldTransferTokensBySender([recipient1, recipient2], [initialAllowance.sub(One), One]);
      });

      context('when transferring to the same owner', function () {
        shouldTransferTokensBySender([recipient1, owner, spender, owner, recipient2], [Zero, One, Zero, Two, One]);
      });
    });

    if (features.ERC165) {
      behaviors.shouldSupportInterfaces([interfaces20.ERC20BatchTransfers]);
    }
  });
}

module.exports = {
  shouldBehaveLikeERC20BatchTransfers,
};
