const {config, artifacts, accounts, web3} = require('hardhat');
const {createFixtureLoader} = require('@animoca/ethereum-contracts-core/test/utils/fixture');
const {expectEventWithParamsOverride} = require('@animoca/ethereum-contracts-core/test/utils/events');
const {BN, expectEvent, expectRevert} = require('@openzeppelin/test-helpers');

const {behaviors, constants} = require('@animoca/ethereum-contracts-core');
const {Zero, One, MaxUInt256, ZeroAddress} = constants;
const interfaces20 = require('../../../../../src/interfaces/ERC165/ERC20');

function shouldBehaveLikeERC20Safe(implementation) {
  const {features, interfaces, revertMessages, eventParamsOverrides, deploy} = implementation;
  const [deployer, owner, recipient, spender, maxSpender] = accounts;

  describe('like a safe ERC20', function () {
    const initialSupply = new BN(100);
    const initialAllowance = initialSupply.sub(One);
    const data = '0x42';

    const fixtureLoader = createFixtureLoader(accounts, web3.eth.currentProvider);
    const fixture = async function () {
      this.token = await deploy([owner], [initialSupply], deployer);
      await this.token.approve(spender, initialAllowance, {from: owner});
      await this.token.approve(maxSpender, MaxUInt256, {from: owner});
      this.nonReceiver = await artifacts.require('ERC20Mock').new([], [], ZeroAddress, ZeroAddress);
      this.receiver = await artifacts.require('ERC20ReceiverMock').new(true, this.token.address);
      this.refusingReceiver = await artifacts.require('ERC20ReceiverMock').new(false, this.token.address);
      this.wrongTokenReceiver = await artifacts.require('ERC20ReceiverMock').new(false, ZeroAddress);
    };

    beforeEach(async function () {
      await fixtureLoader(fixture, this);
    });

    describe('safeTransfer(address,uint256,bytes)', function () {
      context('Pre-conditions', function () {
        it('reverts when sent to the zero address', async function () {
          await expectRevert(this.token.safeTransfer(ZeroAddress, One, data, {from: owner}), revertMessages.TransferToZero);
        });

        it('reverts with an insufficient balance', async function () {
          await expectRevert(this.token.safeTransfer(recipient, initialSupply.add(One), data, {from: owner}), revertMessages.TransferExceedsBalance);
        });

        it('reverts when sent to a non-receiver contract', async function () {
          await expectRevert.unspecified(this.token.safeTransfer(this.nonReceiver.address, One, data, {from: owner}));
        });

        it('reverts when sent to a refusing receiver contract', async function () {
          await expectRevert(this.token.safeTransfer(this.refusingReceiver.address, One, data, {from: owner}), revertMessages.TransferRefused);
        });

        it('reverts when sent to a receiver contract receiving another token', async function () {
          await expectRevert(this.token.safeTransfer(this.wrongTokenReceiver.address, One, data, {from: owner}), 'ERC20Receiver: wrong token');
        });
      });

      const transferWasSuccessful = function (to, value, options, toReceiver = false) {
        if (options.from == to) {
          it('does not affect the sender balance', async function () {
            (await this.token.balanceOf(options.from)).should.be.bignumber.equal(initialSupply);
          });
        } else {
          it('decreases the sender balance', async function () {
            (await this.token.balanceOf(options.from)).should.be.bignumber.equal(initialSupply.sub(value));
          });

          it('increases the recipient balance', async function () {
            (await this.token.balanceOf(toReceiver ? this.receiver.address : to)).should.be.bignumber.equal(value);
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
              _to: toReceiver ? this.receiver.address : to,
              _value: value,
            },
            eventParamsOverrides
          );
        });

        if (toReceiver) {
          it('calls onERC20Received(address,address,uint256,bytes) on a receiver contract', function () {
            expectEvent.inTransaction(this.receipt.tx, this.receiver, 'ERC20Received', {
              sender: options.from,
              from: options.from,
              value: value,
              data: data,
            });
          });
        }
      };

      const shouldTransferTokenByRecipient = function (value) {
        const options = {from: owner};
        context('when transferring to the sender', function () {
          const to = owner;
          beforeEach(async function () {
            this.fromBalance = await this.token.balanceOf(options.from);
            this.toBalance = await this.token.balanceOf(to);
            this.receipt = await this.token.safeTransfer(to, value, data, options);
          });
          transferWasSuccessful(to, value, options);
        });

        context('when transferring to another account', function () {
          const to = recipient;
          beforeEach(async function () {
            this.fromBalance = await this.token.balanceOf(options.from);
            this.toBalance = await this.token.balanceOf(to);
            this.receipt = await this.token.safeTransfer(to, value, data, options);
          });
          transferWasSuccessful(to, value, options);
        });

        context('when transferring to an ERC20Receiver contract', function () {
          beforeEach(async function () {
            this.fromBalance = await this.token.balanceOf(options.from);
            this.toBalance = await this.token.balanceOf(this.receiver.address);
            this.receipt = await this.token.safeTransfer(this.receiver.address, value, data, options);
          });
          transferWasSuccessful(null, value, options, true);
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

    describe('safeTransferFrom(address,address,uint256,bytes)', function () {
      context('Pre-conditions', function () {
        it('reverts when from is the zero address', async function () {
          await expectRevert(
            this.token.safeTransferFrom(ZeroAddress, recipient, One, data, {from: spender}),
            revertMessages.TransferExceedsAllowance
          );
        });

        it('reverts when sent to the zero address', async function () {
          await expectRevert(this.token.safeTransferFrom(owner, ZeroAddress, One, data, {from: spender}), revertMessages.TransferToZero);
        });

        it('reverts with an insufficient balance', async function () {
          await this.token.approve(spender, initialSupply.add(One), {from: owner});
          await expectRevert(
            this.token.safeTransferFrom(owner, recipient, initialSupply.add(One), data, {from: spender}),
            revertMessages.TransferExceedsBalance
          );
        });

        it('reverts with an insufficient allowance', async function () {
          await expectRevert(
            this.token.safeTransferFrom(owner, recipient, initialAllowance.add(One), data, {from: spender}),
            revertMessages.TransferExceedsAllowance
          );
        });

        it('reverts when sent to a non-receiver contract', async function () {
          await expectRevert.unspecified(this.token.safeTransferFrom(owner, this.nonReceiver.address, One, data, {from: spender}));
        });

        it('reverts when sent to a refusing receiver contract', async function () {
          await expectRevert(
            this.token.safeTransferFrom(owner, this.refusingReceiver.address, One, data, {from: spender}),
            revertMessages.TransferRefused
          );
        });

        const transferWasSuccessful = function (from, to, value, options, withEIP717, toReceiver = false) {
          if (from == to) {
            it('does not affect the sender balance', async function () {
              (await this.token.balanceOf(from)).should.be.bignumber.equal(initialSupply);
            });
          } else {
            it('decreases the sender balance', async function () {
              (await this.token.balanceOf(from)).should.be.bignumber.equal(initialSupply.sub(value));
            });

            it('increases the recipient balance', async function () {
              (await this.token.balanceOf(toReceiver ? this.receiver.address : to)).should.be.bignumber.equal(value);
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
                _to: toReceiver ? this.receiver.address : to,
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
                this.receipt = await this.token.safeTransferFrom(from, to, value, data, options);
              });
              transferWasSuccessful(from, to, value, options, withEIP717);
            });
            context('when transferring to the spender', function () {
              const to = spender;
              beforeEach(async function () {
                this.toBalance = await this.token.balanceOf(to);
                this.receipt = await this.token.safeTransferFrom(from, to, value, data, options);
              });
              transferWasSuccessful(from, to, value, options, withEIP717);
            });
            context('when transferring to another account', function () {
              const to = recipient;
              beforeEach(async function () {
                this.toBalance = await this.token.balanceOf(to);
                this.receipt = await this.token.safeTransferFrom(from, to, value, data, options);
              });
              transferWasSuccessful(from, to, value, options, withEIP717);
            });
            context('when transferring to an ERC20Receiver contract', function () {
              beforeEach(async function () {
                this.toBalance = await this.token.balanceOf(this.receiver.address);
                this.receipt = await this.token.safeTransferFrom(from, this.receiver.address, value, data, options);
              });
              transferWasSuccessful(from, null, value, options, withEIP717, true);
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
    });

    if (features.ERC165) {
      behaviors.shouldSupportInterfaces([interfaces20.ERC20SafeTransfers]);
    }
  });
}

module.exports = {
  shouldBehaveLikeERC20Safe,
};
