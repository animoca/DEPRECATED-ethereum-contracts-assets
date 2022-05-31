const {accounts, web3} = require('hardhat');
const {createFixtureLoader} = require('@animoca/ethereum-contracts-core/test/utils/fixture');
const {expectRevert} = require('@openzeppelin/test-helpers');
const {makeNonFungibleTokenId} = require('@animoca/blockchain-inventory_metadata').inventoryIds;

const {behaviors} = require('@animoca/ethereum-contracts-core');
const interfaces = require('../../../../../src/interfaces/ERC165/ERC721');

function shouldBehaveLikeERC721Metadata({nfMaskLength, name, symbol, revertMessages, features, deploy, mint}) {
  const [deployer, owner] = accounts;

  const nft1 = makeNonFungibleTokenId(1, 1, nfMaskLength);
  const nft2 = makeNonFungibleTokenId(2, 1, nfMaskLength);

  describe('like an ERC721Metadata', function () {
    const fixtureLoader = createFixtureLoader(accounts, web3.eth.currentProvider);
    const fixture = async function () {
      this.token = await deploy(deployer);
      await mint(this.token, owner, nft1, 1, {from: deployer});
    };

    beforeEach(async function () {
      await fixtureLoader(fixture, this);
    });

    it('has a name', async function () {
      (await this.token.name()).should.be.equal(name);
    });

    it('has a symbol', async function () {
      (await this.token.symbol()).should.be.equal(symbol);
    });

    describe('tokenURI', function () {
      it('tokenURI()', async function () {
        await this.token.tokenURI(nft1);
        await expectRevert(this.token.tokenURI(nft2), revertMessages.NonExistingNFT);
      });

      if (features.BaseMetadataURI) {
        describe('[BaseMetadataURI] setBaseMetadataURI(string)', function () {
          const newBaseMetadataURI = 'test/';
          it('reverts if not called by the contract owner', async function () {
            await expectRevert(this.token.setBaseMetadataURI(newBaseMetadataURI, {from: owner}), revertMessages.NotContractOwner);
          });
          it('udates the base token URI', async function () {
            await this.token.setBaseMetadataURI(newBaseMetadataURI, {from: deployer});
            (await this.token.tokenURI(nft1)).should.be.equal(newBaseMetadataURI + nft1.toString());
          });
        });
      }
    });

    behaviors.shouldSupportInterfaces([interfaces.ERC721Metadata]);
  });
}

module.exports = {
  shouldBehaveLikeERC721Metadata,
};
