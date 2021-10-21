const {accounts, web3} = require('hardhat');
const {createFixtureLoader} = require('@animoca/ethereum-contracts-core/test/utils/fixture');
const {expectRevert} = require('@openzeppelin/test-helpers');
const interfaces1155 = require('../../../../../src/interfaces/ERC165/ERC1155');
const {behaviors} = require('@animoca/ethereum-contracts-core');

const {makeFungibleCollectionId, makeNonFungibleCollectionId, makeNonFungibleTokenId} =
  require('@animoca/blockchain-inventory_metadata').inventoryIds;

function shouldBehaveLikeERC1155Inventory({nfMaskLength, revertMessages, interfaces, deploy, mint}) {
  const [deployer, owner] = accounts;

  const fCollection1 = {
    id: makeFungibleCollectionId(1),
    supply: 10,
  };
  const fCollection2 = {
    id: makeFungibleCollectionId(2),
    supply: 11,
  };
  const fCollection3 = {
    id: makeFungibleCollectionId(3),
    supply: 12,
  };
  const nfCollection = makeNonFungibleCollectionId(1, nfMaskLength);
  const nfCollectionOther = makeNonFungibleCollectionId(2, nfMaskLength);
  const unknownNFCollection = makeNonFungibleCollectionId(99, nfMaskLength);
  const nft1 = makeNonFungibleTokenId(1, 1, nfMaskLength);
  const nft2 = makeNonFungibleTokenId(2, 1, nfMaskLength);
  const nftOtherCollection = makeNonFungibleTokenId(1, 2, nfMaskLength);
  const unknownNft = makeNonFungibleTokenId(99, 99, nfMaskLength);

  describe('like an ERC1155StandardInventory', function () {
    const fixtureLoader = createFixtureLoader(accounts, web3.eth.currentProvider);
    const fixture = async function () {
      this.token = await deploy(deployer);
      await mint(this.token, owner, fCollection1.id, fCollection1.supply, {from: deployer});
      await mint(this.token, owner, fCollection2.id, fCollection2.supply, {from: deployer});
      await mint(this.token, owner, fCollection3.id, fCollection3.supply, {from: deployer});
      await mint(this.token, owner, nft1, 1, {from: deployer});
      await mint(this.token, owner, nft2, 1, {from: deployer});
      await mint(this.token, owner, nftOtherCollection, 1, {from: deployer});
    };

    beforeEach(async function () {
      await fixtureLoader(fixture, this);
    });

    describe('like an ERC1155Inventory', function () {
      context('constructor', function () {
        it('it reverts with a wrong collection mask length', async function () {
          await expectRevert(deploy(deployer, 0), revertMessages.WrongCollectionMaskLength);
          await expectRevert(deploy(deployer, 256), revertMessages.WrongCollectionMaskLength);
        });
      });

      describe('isFungible(uint256)', function () {
        context('when id is a Fungible Token', function () {
          it('returns true', async function () {
            (await this.token.isFungible(fCollection1.id)).should.be.equal(true);
          });
        });
        context('when id is a Non-Fungible Collection', function () {
          it('returns false', async function () {
            (await this.token.isFungible(nfCollection)).should.be.equal(false);
          });
        });
        context('when id is an existing Non-Fungible Token', function () {
          it('returns false', async function () {
            (await this.token.isFungible(nft1)).should.be.equal(false);
          });
        });
        context('when id is a non-existing Non-Fungible Token', function () {
          it('returns false', async function () {
            (await this.token.isFungible(unknownNft)).should.be.equal(false);
          });
        });
      });

      describe('collectionOf(uint256)', function () {
        context('when id is a Fungible Token', function () {
          it('throws', async function () {
            await expectRevert(this.token.collectionOf(fCollection1.id), revertMessages.NotNFT);
          });
        });
        context('when id is a Non-Fungible Collection', function () {
          it('throws', async function () {
            await expectRevert(this.token.collectionOf(nfCollection), revertMessages.NotNFT);
          });
        });
        context('when id is an existing Non-Fungible Token', function () {
          it('returns the collection', async function () {
            (await this.token.collectionOf(nft1)).toString(10).should.be.equal(nfCollection);
          });
        });
        context('when id is a non-existing Non-Fungible Token', function () {
          it('returns the collection', async function () {
            (await this.token.collectionOf(unknownNft)).toString(10).should.be.equal(unknownNFCollection);
          });
        });
      });

      describe('ownerOf(uint256)', function () {
        context('when id is a Fungible Token', function () {
          it('throws', async function () {
            await expectRevert(this.token.ownerOf(fCollection1.id), revertMessages.NonExistingNFT);
          });
        });
        context('when id is a Non-Fungible Collection', function () {
          it('throws', async function () {
            await expectRevert(this.token.ownerOf(nfCollection), revertMessages.NonExistingNFT);
          });
        });
        context('when id is an existing Non-Fungible Token', function () {
          it('returns the owner', async function () {
            (await this.token.ownerOf(nft1)).toString(10).should.be.equal(owner);
          });
        });
        context('when id is a non-existing Non-Fungible Token', function () {
          it('throws', async function () {
            await expectRevert(this.token.ownerOf(unknownNft), revertMessages.NonExistingNFT);
          });
        });
      });

      if (interfaces.ERC1155InventoryTotalSupply) {
        describe('[ERC1155InventoryTotalSupply] totalSupply(uint256)', function () {
          context('for an Non-Fungible Token', function () {
            it('returns 1 for an existing Non-Fungible Token id', async function () {
              (await this.token.totalSupply(nft1)).should.be.bignumber.equal('1');
            });
            it('returns 0 for a non-existing Non-Fungible Token id', async function () {
              (await this.token.totalSupply(unknownNft)).should.be.bignumber.equal('0');
            });
          });

          context('for a Non-Fungible Collection', function () {
            it('returns the Non-Fungible Collection total supply', async function () {
              (await this.token.totalSupply(nfCollection)).should.be.bignumber.equal('2');
              (await this.token.totalSupply(nfCollectionOther)).should.be.bignumber.equal('1');
            });
          });

          context('for a Fungible Token', function () {
            it('returns the Fungible Token total supply', async function () {
              (await this.token.totalSupply(fCollection1.id)).should.be.bignumber.equal(fCollection1.supply.toString());
            });
          });
        });
      }

      behaviors.shouldSupportInterfaces([interfaces1155.ERC1155Inventory]);

      if (interfaces.ERC1155InventoryTotalSupply) {
        behaviors.shouldSupportInterfaces([interfaces1155.ERC1155InventoryTotalSupply]);
      }
    });
  });
}

module.exports = {
  shouldBehaveLikeERC1155Inventory,
};
