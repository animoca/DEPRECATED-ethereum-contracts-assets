const {accounts, web3} = require('hardhat');
const {expectRevert} = require('@openzeppelin/test-helpers');
const {createFixtureLoader} = require('@animoca/ethereum-contracts-core/test/utils/fixture');
const {makeFungibleCollectionId, makeNonFungibleCollectionId, makeNonFungibleTokenId} =
  require('@animoca/blockchain-inventory_metadata').inventoryIds;
const {behaviors} = require('@animoca/ethereum-contracts-core');
const interfaces = require('../../../../../src/interfaces/ERC165/ERC1155');

function shouldBehaveLikeERC1155MetadataURI({nfMaskLength, revertMessages, features, deploy}) {
  const [deployer, other] = accounts;

  const fCollection = makeFungibleCollectionId(1);
  const nfCollection = makeNonFungibleCollectionId(1, nfMaskLength);
  const nft = makeNonFungibleTokenId(1, 1, nfMaskLength);

  describe('like an ERC1155MetadataURI', function () {
    const fixtureLoader = createFixtureLoader(accounts, web3.eth.currentProvider);
    const fixture = async function () {
      this.token = await deploy(deployer);
    };

    beforeEach(async function () {
      await fixtureLoader(fixture, this);
    });

    describe('uri(uint256)', function () {
      it('should return a non-empty URI', async function () {
        (await this.token.uri(fCollection)).should.not.be.equal('');
        (await this.token.uri(nfCollection)).should.not.be.equal('');
        (await this.token.uri(nft)).should.not.be.equal('');
      });

      if (features.BaseMetadataURI) {
        describe('[BaseMetadataURI] setBaseMetadataURI(string)', function () {
          const newBaseMetadataURI = 'test/';
          it('reverts if not called by the contract owner', async function () {
            await expectRevert(this.token.setBaseMetadataURI(newBaseMetadataURI, {from: other}), revertMessages.NotContractOwner);
          });
          it('udates the base token URI', async function () {
            await this.token.setBaseMetadataURI(newBaseMetadataURI, {from: deployer});
            const nft = '1';
            (await this.token.uri(nft)).should.be.equal(newBaseMetadataURI + nft);
          });
        });
      }
    });

    behaviors.shouldSupportInterfaces([interfaces.ERC1155MetadataURI]);
  });
}

module.exports = {
  shouldBehaveLikeERC1155MetadataURI,
};
