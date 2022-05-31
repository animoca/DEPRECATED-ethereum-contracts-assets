const {artifacts, accounts} = require('hardhat');
const {expectEvent, expectRevert} = require('@openzeppelin/test-helpers');
const {constants} = require('@animoca/ethereum-contracts-core');
const {ZeroAddress} = constants;
const {shouldBehaveLikeERC721} = require('./behaviors/ERC721.behavior');

const implementation = {
  contractName: 'ERC721SimpleMock',
  nfMaskLength: 32,
  revertMessages: {
    // ERC721
    NonApproved: 'ERC721: non-approved sender',
    SelfApproval: 'ERC721: self-approval',
    SelfApprovalForAll: 'ERC721: self-approval',
    ZeroAddress: 'ERC721: zero address',
    TransferToZero: 'ERC721: transfer to zero',
    MintToZero: 'ERC721: mint to zero',
    TransferRejected: 'ERC721: transfer refused',
    NonExistingNFT: 'ERC721: non-existing NFT',
    NonOwnedNFT: 'ERC721: non-owned NFT',
    ExistingNFT: 'ERC721: existing NFT',

    // Admin
    NotMinter: 'MinterRole: not a Minter',
    NotContractOwner: 'Ownable: not the owner',
  },
  interfaces: {ERC721: true},
  features: {},
  methods: {
    'mint(address,uint256)': async function (contract, to, tokenId, overrides) {
      return contract.mint(to, tokenId, overrides);
    },
    'safeMint(address,uint256,bytes)': async function (contract, to, tokenId, data, overrides) {
      return contract.safeMint(to, tokenId, data, overrides);
    },
    'burnFrom(address,uint256)': async function (contract, from, id, overrides) {
      return contract.burnFrom(from, id, overrides);
    },
  },
  deploy: async function (deployer) {
    const forwarderRegistry = await artifacts.require('ForwarderRegistry').new({from: deployer});
    return artifacts.require('ERC721SimpleMock').new(forwarderRegistry.address, ZeroAddress, {from: deployer});
  },
  mint: async function (contract, to, id, _value, overrides) {
    return contract.mint(to, id, overrides);
  },
};

const [deployer, other] = accounts;

describe('ERC721SimpleMock', function () {
  this.timeout(0);

  describe('_msgData()', function () {
    it('it is called for 100% coverage', async function () {
      const token = await implementation.deploy(deployer);
      await token.msgData();
    });
  });

  describe('burn(address,uint256)', function () {
    const tokenId = '1';
    const otherTokenId = '2';

    beforeEach(async function () {
      this.token = await implementation.deploy(deployer);
      await implementation.mint(this.token, other, tokenId, null, {from: deployer});
    });

    it('reverts if not called by a minter', async function () {
      await expectRevert(this.token.burn(other, tokenId, {from: other}), implementation.revertMessages.NotMinter);
    });

    it('reverts if the token does not exist', async function () {
      await expectRevert(this.token.burn(ZeroAddress, otherTokenId, {from: deployer}), implementation.revertMessages.NonExistingNFT);
    });

    it('reverts if from is not the owner', async function () {
      await expectRevert(this.token.burn(deployer, tokenId, {from: deployer}), implementation.revertMessages.NonOwnedNFT);
    });

    context('when successful', function () {
      beforeEach(async function () {
        this.receipt = await this.token.burn(other, tokenId, {from: deployer});
      });

      it('unsets the owner', async function () {
        await expectRevert(this.token.ownerOf(tokenId), implementation.revertMessages.NonExistingNFT);
      });

      it('decreases the account balance', async function () {
        (await this.token.balanceOf(other)).should.be.bignumber.equal('0');
      });

      it('emits a Transfer event', async function () {
        expectEvent(this.receipt, 'Transfer', {
          _from: other,
          _to: ZeroAddress,
          _tokenId: tokenId,
        });
      });
    });
  });

  shouldBehaveLikeERC721(implementation);
});
