const {accounts, web3} = require('hardhat');
const {createFixtureLoader} = require('@animoca/ethereum-contracts-core/test/utils/fixture');
const {BN} = require('@openzeppelin/test-helpers');

const {behaviors} = require('@animoca/ethereum-contracts-core');
const interfaces20 = require('../../../../../src/interfaces/ERC165/ERC20');

function shouldBehaveLikeERC20Metadata(implementation) {
  const {tokenURI, deploy} = implementation;
  const [deployer] = accounts;

  describe('like an ERC20Metadata', function () {
    const fixtureLoader = createFixtureLoader(accounts, web3.eth.currentProvider);
    const fixture = async function () {
      this.token = await deploy([], [], deployer);
    };

    beforeEach(async function () {
      await fixtureLoader(fixture, this);
    });

    describe('tokenURI()', function () {
      it('returns the token URI', async function () {
        (await this.token.tokenURI()).should.be.equal(tokenURI);
      });
    });

    behaviors.shouldSupportInterfaces([interfaces20.ERC20Metadata]);
  });
}

module.exports = {
  shouldBehaveLikeERC20Metadata,
};
