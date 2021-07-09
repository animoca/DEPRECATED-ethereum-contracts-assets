const {accounts, web3} = require('hardhat');
const {createFixtureLoader} = require('@animoca/ethereum-contracts-core/test/utils/fixture');
const {expectEventWithParamsOverride} = require('@animoca/ethereum-contracts-core/test/utils/events');
const {BN, expectEvent, expectRevert} = require('@openzeppelin/test-helpers');

const {constants} = require('@animoca/ethereum-contracts-core');
const {Zero, One, MaxUInt256, ZeroAddress} = constants;

function shouldBehaveLikeERC20Burnable(implementation) {
  const {contractName, features, methods, revertMessages, eventParamsOverrides, deploy} = implementation;
  const {'burn(uint256)': burn, 'burnFrom(address,uint256)': burnFrom, 'batchBurnFrom(address[],uint256[])': batchBurnFrom} = methods;
  const [deployer, owner, spender, maxSpender] = accounts;

  const initialSupply = new BN(100);
  const initialAllowance = initialSupply.sub(One);

  if (burn === undefined) {
    console.log(`ERC20Burnable: non-standard ERC20 method burn(uint256) is not supported by ${contractName}, associated tests will be skipped`);
  }

  if (burnFrom === undefined) {
    console.log(
      `ERC20Burnable: non-standard ERC20 method burnFrom(address,uint256) is not supported by ${contractName}, associated tests will be skipped`
    );
  }

  if (batchBurnFrom === undefined) {
    console.log(
      `ERC20Burnable: non-standard ERC20 method batchBurnFrom(address[],uint256[]) is not supported by ${contractName}, ` +
        `associated tests will be skipped`
    );
  }

  describe('like a burnable ERC20', function () {
    const fixtureLoader = createFixtureLoader(accounts, web3.eth.currentProvider);
    const fixture = async function () {
      this.token = await deploy([owner], [initialSupply], deployer);
      await this.token.approve(spender, initialAllowance, {from: owner});
      await this.token.approve(maxSpender, MaxUInt256, {from: owner});
    };

    beforeEach(async function () {
      await fixtureLoader(fixture, this);
    });

    describe('burn(uint256)', function () {
      if (burn === undefined) {
        return;
      }

      context('Pre-conditions', function () {
        it('reverts with an insufficient balance', async function () {
          await expectRevert(burn(this.token, initialSupply.add(One), {from: owner}), revertMessages.BurnExceedsBalance);
        });
      });

      const burnWasSuccessful = function (value, options) {
        it('decreases the sender balance', async function () {
          (await this.token.balanceOf(options.from)).should.be.bignumber.equal(initialSupply.sub(value));
        });

        it('decreases the total supply', async function () {
          (await this.token.totalSupply()).should.be.bignumber.equal(initialSupply.sub(value));
        });

        it('emits a Transfer event', function () {
          expectEventWithParamsOverride(
            this.receipt,
            'Transfer',
            {
              _from: options.from,
              _to: ZeroAddress,
              _value: value,
            },
            eventParamsOverrides
          );
        });
      };

      const shouldBurnTokens = function (value) {
        const options = {from: owner};
        context('when burning tokens', function () {
          beforeEach(async function () {
            this.fromBalance = await this.token.balanceOf(options.from);
            this.receipt = await burn(this.token, value, options);
          });
          burnWasSuccessful(value, options);
        });
      };

      context('when burning a zero value', function () {
        shouldBurnTokens(Zero);
      });

      context('when burning a non-zero value', function () {
        shouldBurnTokens(One);
      });

      context('when burning the full balance', function () {
        shouldBurnTokens(initialSupply);
      });
    });

    describe('burnFrom(address,uint256)', function () {
      if (burnFrom === undefined) {
        return;
      }

      context('Pre-conditions', function () {
        it('reverts when from is the zero address', async function () {
          await expectRevert(burnFrom(this.token, ZeroAddress, One, {from: spender}), revertMessages.BurnFromZero);
        });

        it('reverts with an insufficient balance', async function () {
          await this.token.approve(spender, initialSupply.add(One), {from: owner});
          await expectRevert(burnFrom(this.token, owner, initialSupply.add(One), {from: spender}), revertMessages.BurnExceedsBalance);
        });

        it('reverts with an insufficient allowance', async function () {
          await expectRevert(burnFrom(this.token, owner, initialAllowance.add(One), {from: spender}), revertMessages.BurnExceedsAllowance);
        });
      });

      const burnWasSuccessful = function (from, value, options, withEIP717) {
        it('decreases the owner balance', async function () {
          (await this.token.balanceOf(from)).should.be.bignumber.equal(initialSupply.sub(value));
        });

        it('decreases the total supply', async function () {
          (await this.token.totalSupply()).should.be.bignumber.equal(initialSupply.sub(value));
        });

        it('emits a Transfer event', function () {
          expectEventWithParamsOverride(
            this.receipt,
            'Transfer',
            {
              _from: from,
              _to: ZeroAddress,
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

      const shouldBurnTokens = function (from, value, options, withEIP717 = false) {
        context('when burning tokens', function () {
          beforeEach(async function () {
            this.fromBalance = await this.token.balanceOf(options.from);
            this.allowance = await this.token.allowance(from, options.from);
            this.receipt = await burnFrom(this.token, from, value, options);
          });
          burnWasSuccessful(from, value, options, withEIP717);
        });
      };

      const shouldBurnTokensBySender = function (value) {
        const from = owner;
        context('when burning started by the owner', function () {
          shouldBurnTokens(from, value, {from: owner});
        });

        context('when burning started by an approved sender', function () {
          shouldBurnTokens(from, value, {from: spender});
        });

        context('when burning started by a sender with max approval', function () {
          shouldBurnTokens(from, value, {from: maxSpender}, features.EIP717);
        });
      };

      context('when burning a zero value', function () {
        shouldBurnTokensBySender(Zero);
      });

      context('when burning a non-zero value', function () {
        shouldBurnTokensBySender(One);
      });

      context('when burning the full allowance', function () {
        shouldBurnTokensBySender(initialAllowance);
      });
    });

    describe('batchBurnFrom(address[],uint256[])', function () {
      if (batchBurnFrom === undefined) {
        return;
      }

      context('Pre-conditions', function () {
        it('reverts with inconsistent arrays', async function () {
          await expectRevert(batchBurnFrom(this.token, [spender, spender], [One], {from: spender}), revertMessages.InconsistentArrays);
          await expectRevert(batchBurnFrom(this.token, [spender], [One, One], {from: spender}), revertMessages.InconsistentArrays);
        });

        it('reverts when one of the owners is the zero address', async function () {
          await expectRevert(batchBurnFrom(this.token, [ZeroAddress], [One], {from: spender}), revertMessages.BurnFromZero);
          await expectRevert(batchBurnFrom(this.token, [spender, ZeroAddress], [One, One], {from: spender}), revertMessages.BurnFromZero);
        });

        it('reverts with an insufficient balance', async function () {
          await expectRevert(batchBurnFrom(this.token, [owner], [initialSupply.add(One)], {from: owner}), revertMessages.BurnExceedsBalance);
          await expectRevert(batchBurnFrom(this.token, [owner, owner], [initialSupply, One], {from: owner}), revertMessages.BurnExceedsBalance);
        });

        it('reverts with an insufficient allowance', async function () {
          await expectRevert(batchBurnFrom(this.token, [owner], [initialAllowance.add(One)], {from: spender}), revertMessages.BurnExceedsAllowance);
          await expectRevert(
            batchBurnFrom(this.token, [owner, owner], [initialAllowance, One], {from: spender}),
            revertMessages.BurnExceedsAllowance
          );
        });

        it('reverts when values overflow', async function () {
          await expectRevert(
            batchBurnFrom(this.token, [owner, owner], [initialAllowance, MaxUInt256], {from: spender}),
            revertMessages.BatchBurnValuesOverflow
          );
          await expectRevert(
            batchBurnFrom(this.token, [owner, owner], [initialAllowance, MaxUInt256], {from: maxSpender}),
            revertMessages.BatchBurnValuesOverflow
          );
        });
      });

      const burnWasSuccessful = function (owners, values, options, withEIP717) {
        let totalValue = Zero;
        let aggregatedValues = {};
        for (let i = 0; i < owners.length; ++i) {
          const from = owners[i];
          const value = values[i];
          totalValue = totalValue.add(value);

          it('emits a Transfer event', function () {
            expectEventWithParamsOverride(
              this.receipt,
              'Transfer',
              {
                _from: from,
                _to: ZeroAddress,
                _value: value,
              },
              eventParamsOverrides
            );
          });

          aggregatedValues[from] = aggregatedValues[from] ? aggregatedValues[from].add(value) : value;
        }

        for (const from of Object.keys(aggregatedValues)) {
          it('decreases the owners balance', async function () {
            (await this.token.balanceOf(from)).should.be.bignumber.equal(this.fromBalances[from].sub(aggregatedValues[from]));
          });

          if (from != options.from) {
            if (withEIP717) {
              it('[EIP717] keeps allowance at max ', async function () {
                (await this.token.allowance(from, options.from)).should.be.bignumber.equal(MaxUInt256);
              });
            } else {
              it('decreases the spender allowance', async function () {
                (await this.token.allowance(from, options.from)).should.be.bignumber.equal(this.fromAllowances[from].sub(aggregatedValues[from]));
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
                    _value: withEIP717 ? MaxUInt256 : this.fromAllowances[from].sub(aggregatedValues[from]),
                  },
                  eventParamsOverrides
                );
              });
            }
          }
        }

        it('decreases the token(s) total supply', async function () {
          (await this.token.totalSupply()).should.be.bignumber.equal(initialSupply.sub(totalValue));
        });
      };

      const shouldBurnTokens = function (owners, values, options, withEIP717 = false) {
        beforeEach(async function () {
          this.fromAllowances = {};
          this.fromBalances = {};
          for (const from of owners) {
            this.fromAllowances[from] = await this.token.allowance(from, options.from);
            this.fromBalances[from] = await this.token.balanceOf(from);
          }
          this.receipt = await this.token.batchBurnFrom(owners, values, options);
        });
        burnWasSuccessful(owners, values, options, withEIP717);
      };

      const shouldBurnTokensBySender = function (owners, values) {
        context('when burn started by the owner', function () {
          shouldBurnTokens(owners, values, {from: owner});
        });

        context('when burn started by an approved sender', function () {
          shouldBurnTokens(owners, values, {from: spender});
        });

        context('when burn started by a sender with max approval', function () {
          shouldBurnTokens(owners, values, {from: maxSpender}, features.EIP717);
        });
      };

      context('when burning an empty list', function () {
        shouldBurnTokensBySender([], []);
      });

      context('when burning zero values', function () {
        shouldBurnTokensBySender([owner, owner, owner], [Zero, One, Zero]);
      });

      context('when burning the full allowance', function () {
        shouldBurnTokensBySender([owner], [initialAllowance]);
        shouldBurnTokensBySender([owner, owner], [initialAllowance.sub(One), One]);
      });
    });
  });
}

module.exports = {
  shouldBehaveLikeERC20Burnable,
};
