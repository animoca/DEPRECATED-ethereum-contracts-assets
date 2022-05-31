const {artifacts, accounts, web3} = require('hardhat');
const {createFixtureLoader} = require('@animoca/ethereum-contracts-core/test/utils/fixture');
const {expectEventWithParamsOverride} = require('@animoca/ethereum-contracts-core/test/utils/events');
const {BN, expectEvent, expectRevert} = require('@openzeppelin/test-helpers');
const interfaces20 = require('../../../../../src/interfaces/ERC165/ERC20');
const {behaviors, constants, interfaces: interfaces165} = require('@animoca/ethereum-contracts-core');
const {Zero, One, MaxUInt256, ZeroAddress} = constants;

function shouldBehaveLikeERC20Standard(implementation) {
  const {features, interfaces, revertMessages, eventParamsOverrides, deploy} = implementation;
  const [deployer, owner, recipient, spender, maxSpender] = accounts;

  // eslint-disable-next-line
  describe('like an ERC20Standard', function () {
    const initialSupply = new BN('100');
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

    describe('totalSupply()', function () {
      it('returns the initial supply of tokens', async function () {
        (await this.token.totalSupply()).should.be.bignumber.equal(initialSupply);
      });
    });

    describe('balanceOf(address)', function () {
      it('returns zero for an account without balance', async function () {
        (await this.token.balanceOf(spender)).should.be.bignumber.equal(Zero);
      });

      it('returns the correct balance for an account with balance', async function () {
        (await this.token.balanceOf(owner)).should.be.bignumber.equal(initialSupply);
      });
    });

    describe('allowance(address,address)', function () {
      it('returns zero when there is no allowance', async function () {
        (await this.token.allowance(owner, recipient)).should.be.bignumber.equal(Zero);
        (await this.token.allowance(owner, owner)).should.be.bignumber.equal(Zero);
      });

      it('returns the allowance if it has been set', async function () {
        (await this.token.allowance(owner, spender)).should.be.bignumber.equal(initialAllowance);
      });
    });

    describe('approve(address,uint256)', function () {
      it('reverts if approving the zero address', async function () {
        await expectRevert(this.token.approve(ZeroAddress, One, {from: owner}), revertMessages.ApproveToZero);
      });

      const approveWasSuccessful = function (approved, amount) {
        it('sets the new allowance for the spender', async function () {
          (await this.token.allowance(owner, approved)).should.be.bignumber.equal(amount);
        });
        it('emits the Approval event', async function () {
          expectEvent(this.receipt, 'Approval', {
            _owner: owner,
            _spender: approved,
            _value: amount,
          });
        });
      };

      const shouldApproveBySpender = function (amount) {
        context('when approving another account', function () {
          const approved = spender;
          beforeEach(async function () {
            this.receipt = await this.token.approve(approved, amount, {from: owner});
          });
          approveWasSuccessful(approved, amount);
        });
        context('when approving oneself', function () {
          const approved = owner;
          beforeEach(async function () {
            this.receipt = await this.token.approve(approved, amount, {from: owner});
          });
          approveWasSuccessful(approved, amount);
        });
      };

      context('when approving a zero amount', function () {
        shouldApproveBySpender(Zero);
      });
      context('when approving a non-zero amount', function () {
        const amount = initialSupply;

        context("when approving less than the owner's balance", function () {
          shouldApproveBySpender(amount.subn(1));
        });

        context("when approving exactly the owner's balance", function () {
          shouldApproveBySpender(amount);
        });

        context("when approving more than the owner's balance", function () {
          shouldApproveBySpender(amount.addn(1));
        });
      });
    });

    describe('transfer(address,uint256)', function () {
      context('Pre-conditions', function () {
        it('reverts when sent to the zero address', async function () {
          await expectRevert(this.token.transfer(ZeroAddress, One, {from: owner}), revertMessages.TransferToZero);
        });

        it('reverts with an insufficient balance', async function () {
          await expectRevert(this.token.transfer(recipient, initialSupply.add(One), {from: owner}), revertMessages.TransferExceedsBalance);
        });
      });

      const transferWasSuccessful = function (to, value, options) {
        if (options.from == to) {
          it('does not affect the sender balance', async function () {
            (await this.token.balanceOf(options.from)).should.be.bignumber.equal(initialSupply);
          });
        } else {
          it('decreases the sender balance', async function () {
            (await this.token.balanceOf(options.from)).should.be.bignumber.equal(initialSupply.sub(value));
          });

          it('increases the recipient balance', async function () {
            (await this.token.balanceOf(to)).should.be.bignumber.equal(value);
          });
        }

        it('does not affect the token(s) total supply', async function () {
          (await this.token.totalSupply()).should.be.bignumber.equal(initialSupply);
        });

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
      };

      const shouldTransferTokenByRecipient = function (value) {
        const options = {from: owner};
        context('when transferring to the sender', function () {
          const to = owner;
          beforeEach(async function () {
            this.fromBalance = await this.token.balanceOf(options.from);
            this.toBalance = await this.token.balanceOf(to);
            this.receipt = await this.token.transfer(to, value, options);
          });
          transferWasSuccessful(to, value, options);
        });

        context('when transferring to another account', function () {
          const to = recipient;
          beforeEach(async function () {
            this.fromBalance = await this.token.balanceOf(options.from);
            this.toBalance = await this.token.balanceOf(to);
            this.receipt = await this.token.transfer(to, value, options);
          });
          transferWasSuccessful(to, value, options);
        });
      };

      context('when transferring a zero value', function () {
        shouldTransferTokenByRecipient(Zero);
      });

      context('when transferring a non-zero value', function () {
        shouldTransferTokenByRecipient(One);
      });

      context('when transferring the full balance', function () {
        shouldTransferTokenByRecipient(initialSupply);
      });
    });

    describe('transferFrom(address,address,uint256)', function () {
      context('Pre-conditions', function () {
        it('reverts when from is the zero address', async function () {
          await expectRevert(this.token.transferFrom(ZeroAddress, recipient, One, {from: spender}), revertMessages.TransferExceedsAllowance);
        });

        it('reverts when sent to the zero address', async function () {
          await expectRevert(this.token.transferFrom(owner, ZeroAddress, One, {from: spender}), revertMessages.TransferToZero);
        });

        it('reverts with an insufficient balance', async function () {
          await this.token.approve(spender, initialSupply.add(One), {from: owner});
          await expectRevert(
            this.token.transferFrom(owner, recipient, initialSupply.add(One), {from: spender}),
            revertMessages.TransferExceedsBalance
          );
        });

        it('reverts with an insufficient allowance', async function () {
          await expectRevert(
            this.token.transferFrom(owner, recipient, initialAllowance.add(One), {from: spender}),
            revertMessages.TransferExceedsAllowance
          );
        });
      });

      const transferWasSuccessful = function (from, to, value, options, withEIP717) {
        if (from == to) {
          it('does not affect the sender balance', async function () {
            (await this.token.balanceOf(from)).should.be.bignumber.equal(initialSupply);
          });
        } else {
          it('decreases the sender balance', async function () {
            (await this.token.balanceOf(from)).should.be.bignumber.equal(initialSupply.sub(value));
          });

          it('increases the recipient balance', async function () {
            (await this.token.balanceOf(to)).should.be.bignumber.equal(value);
          });
        }

        it('does not affect the token(s) total supply', async function () {
          (await this.token.totalSupply()).should.be.bignumber.equal(initialSupply);
        });

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

        if (from != options.from) {
          if (withEIP717) {
            it('[EIP717] keeps allowance at max ', async function () {
              (await this.token.allowance(from, options.from)).should.be.bignumber.equal(MaxUInt256);
            });
          } else {
            it('decreases the spender allowance', async function () {
              (await this.token.allowance(from, options.from)).should.be.bignumber.equal(this.allowance.sub(value));
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
                  _value: withEIP717 ? MaxUInt256 : this.allowance.sub(value),
                },
                eventParamsOverrides
              );
            });
          }
        }
      };

      const shouldTransferTokenByRecipient = function (from, value, options, withEIP717 = false) {
        context('when transferring to different recipients', function () {
          beforeEach(async function () {
            this.fromBalance = await this.token.balanceOf(options.from);
            this.allowance = await this.token.allowance(from, options.from);
          });
          context('when transferring to the owner', function () {
            const to = owner;
            beforeEach(async function () {
              this.toBalance = await this.token.balanceOf(to);
              this.receipt = await this.token.transferFrom(from, to, value, options);
            });
            transferWasSuccessful(from, to, value, options, withEIP717);
          });
          context('when transferring to the spender', function () {
            const to = spender;
            beforeEach(async function () {
              this.toBalance = await this.token.balanceOf(to);
              this.receipt = await this.token.transferFrom(from, to, value, options);
            });
            transferWasSuccessful(from, to, value, options, withEIP717);
          });
          context('when transferring to another account', function () {
            const to = recipient;
            beforeEach(async function () {
              this.toBalance = await this.token.balanceOf(to);
              this.receipt = await this.token.transferFrom(from, to, value, options);
            });
            transferWasSuccessful(from, to, value, options, withEIP717);
          });
        });
      };

      const shouldTransferTokenBySender = function (value) {
        const from = owner;
        context('when transfer started by the owner', function () {
          shouldTransferTokenByRecipient(from, value, {from: owner});
        });

        context('when transfer started by an approved sender', function () {
          shouldTransferTokenByRecipient(from, value, {from: spender});
        });

        context('when transfer started by a sender with max approval', function () {
          shouldTransferTokenByRecipient(from, value, {from: maxSpender}, features.EIP717);
        });
      };

      context('when transferring a zero value', function () {
        shouldTransferTokenBySender(Zero);
      });

      context('when transferring a non-zero value', function () {
        shouldTransferTokenBySender(One);
      });

      context('when transferring the full allowance', function () {
        shouldTransferTokenBySender(initialAllowance);
      });
    });

    if (features.ERC165) {
      behaviors.shouldSupportInterfaces([interfaces165.ERC165.ERC165, interfaces20.ERC20]);
    }
  });
}

module.exports = {
  shouldBehaveLikeERC20Standard,
};
