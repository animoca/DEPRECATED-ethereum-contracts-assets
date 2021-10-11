const {accounts, web3} = require('hardhat');
const {createFixtureLoader} = require('@animoca/ethereum-contracts-core/test/utils/fixture');
const {expectEventWithParamsOverride} = require('@animoca/ethereum-contracts-core/test/utils/events');
const {BN, expectEvent, expectRevert} = require('@openzeppelin/test-helpers');

const {constants} = require('@animoca/ethereum-contracts-core');
const {Zero, One, Two, MaxUInt256, ZeroAddress} = constants;

function shouldBehaveLikeERC20Mintable(implementation) {
  const {contractName, revertMessages, eventParamsOverrides, methods, deploy} = implementation;
  const {'mint(address,uint256)': mint, 'batchMint(address[],uint256[])': batchMint} = methods;
  const [deployer, recipient1, recipient2] = accounts;

  if (mint === undefined) {
    console.log(
      `ERC20Mintable: non-standard ERC20 method mint(address,uint256) is not supported by ${contractName}, associated tests will be skipped`
    );
  }

  if (batchMint === undefined) {
    console.log(
      `ERC20Mintable: non-standard ERC20 method batchMint(address[],uint256[]) is not supported by ${contractName}, associated tests will be skipped`
    );
  }

  describe('like a mintable ERC20', function () {
    const fixtureLoader = createFixtureLoader(accounts, web3.eth.currentProvider);
    const fixture = async function () {
      this.token = await deploy([], [], deployer);
    };

    beforeEach(async function () {
      await fixtureLoader(fixture, this);
    });

    describe('mint(address,uint256)', function () {
      if (mint === undefined) {
        return;
      }

      it('reverts if sent by a non-minter', async function () {
        await expectRevert(mint(this.token, recipient1, One, {from: recipient1}), revertMessages.NotMinter);
      });

      it('reverts if minted to the zero address', async function () {
        await expectRevert(mint(this.token, ZeroAddress, One, {from: deployer}), revertMessages.MintToZero);
      });

      it('reverts if minting would overflow the total supply', async function () {
        await mint(this.token, recipient1, MaxUInt256, {from: deployer});
        await expectRevert(mint(this.token, recipient2, One, {from: deployer}), revertMessages.SupplyOverflow);
      });

      const mintWasSuccessful = function (to, value) {
        it('mints the specified amount', async function () {
          (await this.token.balanceOf(to)).should.be.bignumber.equal(value);
        });

        it('increases the total supply', async function () {
          (await this.token.totalSupply()).should.be.bignumber.equal(value);
        });

        it('emits a Transfer event', async function () {
          expectEventWithParamsOverride(
            this.receipt,
            'Transfer',
            {
              _from: ZeroAddress,
              _to: to,
              _value: value,
            },
            eventParamsOverrides
          );
        });
      };

      const shouldMintTokens = function (to, value) {
        beforeEach(async function () {
          this.receipt = await mint(this.token, to, value, {from: deployer});
        });
        mintWasSuccessful(to, value);
      };

      context('when minting zero value', function () {
        shouldMintTokens(recipient1, Zero);
      });

      context('when minting some tokens', function () {
        shouldMintTokens(recipient1, One);
      });

      context('when minting the maximum supply', function () {
        shouldMintTokens(recipient1, MaxUInt256);
      });
    });

    describe('batchMint(address[],uint256[])', function () {
      if (batchMint === undefined) {
        return;
      }

      it('reverts if sent by a non-minter', async function () {
        await expectRevert(batchMint(this.token, [recipient1], [One], {from: recipient1}), revertMessages.NotMinter);
      });

      it('reverts with inconsistent arrays', async function () {
        await expectRevert(batchMint(this.token, [recipient1, recipient2], [One], {from: deployer}), revertMessages.InconsistentArrays);
        await expectRevert(batchMint(this.token, [], [One], {from: deployer}), revertMessages.InconsistentArrays);
      });

      it('reverts if minted to the zero address', async function () {
        await expectRevert(batchMint(this.token, [ZeroAddress], [One], {from: deployer}), revertMessages.MintToZero);
      });

      it('reverts if minting would overflow the total supply', async function () {
        await batchMint(this.token, [recipient1], [MaxUInt256], {from: deployer});
        await expectRevert(batchMint(this.token, [recipient2], [One], {from: deployer}), revertMessages.SupplyOverflow);
      });

      it('reverts if cumulative values overflow', async function () {
        await expectRevert(
          batchMint(this.token, [recipient1, recipient2], [One, MaxUInt256], {from: deployer}),
          revertMessages.BatchMintValuesOverflow
        );
      });

      const mintWasSuccessful = function (recipients, values) {
        let aggregatedValues = {};
        let totalValue = Zero;
        for (let i = 0; i < recipients.length; ++i) {
          const to = recipients[i];
          const value = values[i];

          it('emits a Transfer event', function () {
            expectEventWithParamsOverride(
              this.receipt,
              'Transfer',
              {
                _from: ZeroAddress,
                _to: to,
                _value: value,
              },
              eventParamsOverrides
            );
          });

          aggregatedValues[to] = aggregatedValues[to] ? aggregatedValues[to].add(value) : value;
          totalValue = totalValue.add(value);
        }

        for (const to of Object.keys(aggregatedValues)) {
          const value = aggregatedValues[to];

          it('increases the recipient balance', async function () {
            (await this.token.balanceOf(to)).should.be.bignumber.equal(value);
          });
        }

        it('increases the total supply', async function () {
          (await this.token.totalSupply()).should.be.bignumber.equal(totalValue);
        });
      };

      const shouldMintTokens = function (recipients, values) {
        beforeEach(async function () {
          this.receipt = await batchMint(this.token, recipients, values, {from: deployer});
        });
        mintWasSuccessful(recipients, values);
      };

      context('when minting nothing', function () {
        shouldMintTokens([], []);
      });

      context('when minting some tokens', function () {
        shouldMintTokens([recipient1, recipient2], [One, Two]);
      });

      context('when minting some tokens including zero values', function () {
        shouldMintTokens([recipient1, recipient1, recipient2], [One, Zero, One]);
      });

      context('when minting the maximum supply', function () {
        shouldMintTokens([recipient1], [MaxUInt256]);
      });
    });
  });
}

module.exports = {
  shouldBehaveLikeERC20Mintable,
};
