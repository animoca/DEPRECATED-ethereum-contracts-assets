const {accounts, web3} = require('hardhat');
const {createFixtureLoader} = require('@animoca/ethereum-contracts-core/test/utils/fixture');
const {BN} = require('@openzeppelin/test-helpers');

const {behaviors} = require('@animoca/ethereum-contracts-core');
const interfaces20 = require('../../../../../src/interfaces/ERC165/ERC20');

function shouldBehaveLikeERC20Detailed(implementation) {
  const {name, symbol, decimals, deploy} = implementation;
  const [deployer] = accounts;

  describe('like a detailed ERC20', function () {
    const fixtureLoader = createFixtureLoader(accounts, web3.eth.currentProvider);
    const fixture = async function () {
      this.token = await deploy([], [], deployer);
    };

    beforeEach(async function () {
      await fixtureLoader(fixture, this);
    });

    describe('name()', function () {
      it('returns the correct name', async function () {
        (await this.token.name()).should.be.equal(name);
      });
    });

    describe('symbol()', function () {
      it('returns the correct symbol', async function () {
        (await this.token.symbol()).should.be.equal(symbol);
      });
    });

    describe('decimals()', function () {
      it('returns the correct amount of decimals', async function () {
        (await this.token.decimals()).should.be.bignumber.equal(decimals);
      });
    });

    behaviors.shouldSupportInterfaces([interfaces20.ERC20Detailed]);
  });
}

module.exports = {
  shouldBehaveLikeERC20Detailed,
};
