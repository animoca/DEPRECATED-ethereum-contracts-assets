const {accounts, web3} = require('hardhat');
const {createFixtureLoader} = require('@animoca/ethereum-contracts-core/test/utils/fixture');
const {BN, expectEvent, expectRevert} = require('@openzeppelin/test-helpers');

const {behaviors, constants} = require('@animoca/ethereum-contracts-core');
const {Zero, One, Two, MaxUInt256, ZeroAddress} = constants;
const interfaces20 = require('../../../../../src/interfaces/ERC165/ERC20');

function shouldBehaveLikeERC20Allowance(implementation) {
  const {revertMessages, deploy} = implementation;
  const [deployer, owner, spender] = accounts;

  const initialSupply = new BN(100);

  describe('like an allowance ERC20', function () {
    const fixtureLoader = createFixtureLoader(accounts, web3.eth.currentProvider);
    const fixture = async function () {
      this.token = await deploy([owner], [initialSupply], deployer);
    };

    beforeEach(async function () {
      await fixtureLoader(fixture, this);
    });

    describe('increaseAllowance(address,uint256)', function () {
      const shouldIncreaseAllowance = function (preApprovedAmount, amount) {
        const expectedAllowance = preApprovedAmount.add(amount);

        beforeEach(async function () {
          if (!preApprovedAmount.isZero()) {
            await this.token.approve(spender, preApprovedAmount, {from: owner});
          }

          this.receipt = await this.token.increaseAllowance(spender, amount, {from: owner});
        });

        it('increases the spender allowance by the specified amount', async function () {
          (await this.token.allowance(owner, spender)).should.be.bignumber.equal(expectedAllowance);
        });

        it('emits an Approval event', async function () {
          expectEvent(this.receipt, 'Approval', {
            _owner: owner,
            _spender: spender,
            _value: expectedAllowance,
          });
        });
      };

      context('when increasing by a zero amount', function () {
        const amount = Zero;

        context('when the spender is not the zero address', function () {
          context('when there was no pre-approved allowance', function () {
            const preApprovedAmount = Zero;

            shouldIncreaseAllowance(preApprovedAmount, amount);
          });

          context('when there was a pre-approved allowance', function () {
            const preApprovedAmount = initialSupply;

            shouldIncreaseAllowance(preApprovedAmount, amount);
          });
        });

        context('when the spender is the zero address', function () {
          it('reverts', async function () {
            await expectRevert(this.token.increaseAllowance(ZeroAddress, amount, {from: owner}), revertMessages.ApproveToZero);
          });
        });
      });

      context('when increasing by a non-zero amount', function () {
        const amount = One;

        context('when the spender is not the zero address', function () {
          context('when there was no pre-approved allowance', function () {
            const preApprovedAmount = Zero;

            shouldIncreaseAllowance(preApprovedAmount, amount);
          });

          context('when there was a pre-approved allowance', function () {
            const preApprovedAmount = initialSupply;

            shouldIncreaseAllowance(preApprovedAmount, amount);
          });
        });

        context('when the spender is the zero address', function () {
          it('reverts', async function () {
            await expectRevert(this.token.increaseAllowance(ZeroAddress, amount, {from: owner}), revertMessages.ApproveToZero);
          });
        });

        context('when the allowance overflows', function () {
          it('reverts', async function () {
            await this.token.increaseAllowance(spender, amount, {from: owner});
            await expectRevert(this.token.increaseAllowance(spender, MaxUInt256, {from: owner}), revertMessages.AllowanceOverflow);
          });
        });
      });
    });

    describe('decreaseAllowance(address,uint256)', function () {
      const shouldDecreaseAllowance = function (preApprovedAmount, amount) {
        const expectedAllowance = preApprovedAmount.sub(amount);

        beforeEach(async function () {
          if (!preApprovedAmount.isZero()) {
            await this.token.approve(spender, preApprovedAmount, {from: owner});
          }

          this.receipt = await this.token.decreaseAllowance(spender, amount, {from: owner});
        });

        it('decreases the spender allowance by the specified amount', async function () {
          (await this.token.allowance(owner, spender)).should.be.bignumber.equal(expectedAllowance);
        });

        it('emits an approval event', async function () {
          expectEvent(this.receipt, 'Approval', {
            _owner: owner,
            _spender: spender,
            _value: expectedAllowance,
          });
        });
      };

      context('when decreasing by a zero amount', function () {
        const amount = Zero;

        context('when the spender is not the zero address', function () {
          context('when there was no pre-approved allowance', function () {
            const preApprovedAmount = Zero;

            shouldDecreaseAllowance(preApprovedAmount, amount);
          });

          context('when there was a pre-approved allowance', function () {
            // context('when the pre-approved allowance is less than the allowance decrease', function () {
            //   // This test case is not possible when decreasing by a zero amount
            // });

            context('when the pre-approved allowance equals the allowance decrease', function () {
              const preApprovedAmount = amount;

              shouldDecreaseAllowance(preApprovedAmount, amount);
            });

            context('when the pre-approved allowance is greater than the allowance decrease', function () {
              const preApprovedAmount = amount.add(One);

              shouldDecreaseAllowance(preApprovedAmount, amount);
            });
          });
        });

        context('when the spender is the zero address', function () {
          it('reverts', async function () {
            await expectRevert(this.token.decreaseAllowance(ZeroAddress, amount, {from: owner}), revertMessages.ApproveToZero);
          });
        });
      });

      context('when decreasing by a non-zero amount', function () {
        const amount = Two;

        context('when the spender is not the zero address', function () {
          context('when there was no pre-approved allowance', function () {
            it('reverts', async function () {
              await expectRevert(this.token.decreaseAllowance(spender, amount, {from: owner}), revertMessages.AllowanceUnderflow);
            });
          });

          context('when there was a pre-approved allowance', function () {
            context('when the pre-approved allowance is less than the allowance decrease', function () {
              it('reverts', async function () {
                await expectRevert(this.token.decreaseAllowance(spender, amount, {from: owner}), revertMessages.AllowanceUnderflow);
              });
            });

            context('when the pre-approved allowance equals the allowance decrease', function () {
              const preApprovedAmount = amount;

              shouldDecreaseAllowance(preApprovedAmount, amount);
            });

            context('when the pre-approved allowance is greater than the allowance decrease', function () {
              const preApprovedAmount = amount.add(One);

              shouldDecreaseAllowance(preApprovedAmount, amount);
            });
          });
        });

        context('when the spender is the zero address', function () {
          it('reverts', async function () {
            await expectRevert(this.token.increaseAllowance(ZeroAddress, amount, {from: owner}), revertMessages.ApproveToZero);
          });
        });
      });
    });

    behaviors.shouldSupportInterfaces([interfaces20.ERC20Allowance_Experimental]);
  });
}

module.exports = {
  shouldBehaveLikeERC20Allowance,
};
