const {accounts, web3} = require('hardhat');
const {createFixtureLoader} = require('@animoca/ethereum-contracts-core/test/utils/fixture');
const {expectRevert} = require('@openzeppelin/test-helpers');

const {behaviors} = require('@animoca/ethereum-contracts-core');
const interfaces20 = require('../../../../../src/interfaces/ERC165/ERC20');

function shouldBehaveLikeERC20Metadata(implementation) {
  const {tokenURI, deploy, revertMessages} = implementation;
  const [deployer, other] = accounts;

  describe('like an ERC20Metadata', function () {
    const fixtureLoader = createFixtureLoader(accounts, web3.eth.currentProvider);
    const fixture = async function () {
      this.token = await deploy([], [], deployer);
      await this.token.setTokenURI(tokenURI, {from: deployer});
    };

    beforeEach(async function () {
      await fixtureLoader(fixture, this);
    });

    describe('tokenURI()', function () {
      it('returns the token URI', async function () {
        (await this.token.tokenURI()).should.be.equal(tokenURI);
      });
    });

    describe('setTokenURI()', function () {
      const newTokenURI = 'test';
      it('reverts if not called by the contract owner', async function () {
        await expectRevert(this.token.setTokenURI(newTokenURI, {from: other}), revertMessages.NotContractOwner);
      });
      it('updates the token URI', async function () {
        await this.token.setTokenURI(newTokenURI, {from: deployer});
        (await this.token.tokenURI()).should.be.equal(newTokenURI);
      });
    });

    behaviors.shouldSupportInterfaces([interfaces20.ERC20Metadata]);
  });
}

module.exports = {
  shouldBehaveLikeERC20Metadata,
};
