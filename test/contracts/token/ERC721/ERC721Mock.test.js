const {artifacts, accounts} = require('hardhat');
const {constants} = require('@animoca/ethereum-contracts-core');
const {ZeroAddress} = constants;
const {shouldBehaveLikeERC721} = require('./behaviors/ERC721.behavior');

const implementation = {
  contractName: 'ERC721Mock',
  nfMaskLength: 32,
  name: 'ERC721Mock',
  symbol: 'E721',
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
    ExistingOrBurntNFT: 'ERC721: existing/burnt NFT',

    // Admin
    NotMinter: 'MinterRole: not a Minter',
    NotContractOwner: 'Ownable: not the owner',
  },
  interfaces: {ERC721: true, ERC721Metadata: true, ERC721BatchTransfer: true},
  features: {BaseMetadataURI: true},
  methods: {
    'batchTransferFrom(address,address,uint256[])': async function (contract, from, to, tokenIds, overrides) {
      return contract.batchTransferFrom(from, to, tokenIds, overrides);
    },
    'mint(address,uint256)': async function (contract, to, tokenId, overrides) {
      return contract.mint(to, tokenId, overrides);
    },
    'safeMint(address,uint256,bytes)': async function (contract, to, tokenId, data, overrides) {
      return contract.methods['safeMint(address,uint256,bytes)'](to, tokenId, data, overrides);
    },
    'batchMint(address,uint256[])': async function (contract, to, tokenIds, overrides) {
      return contract.batchMint(to, tokenIds, overrides);
    },
  },
  deploy: async function (deployer) {
    const registry = await artifacts.require('ForwarderRegistry').new({from: deployer});
    const forwarder = await artifacts.require('UniversalForwarder').new({from: deployer});
    return artifacts.require('ERC721Mock').new(registry.address, ZeroAddress, {from: deployer});
  },
  mint: async function (contract, to, id, _value, overrides) {
    return contract.methods['safeMint(address,uint256,bytes)'](to, id, '0x', overrides);
  },
};

const [deployer] = accounts;

describe('ERC721Mock', function () {
  this.timeout(0);

  context('_msgData()', function () {
    it('it is called for 100% coverage', async function () {
      const token = await implementation.deploy(deployer);
      await token.msgData();
    });
  });

  shouldBehaveLikeERC721(implementation);
});
