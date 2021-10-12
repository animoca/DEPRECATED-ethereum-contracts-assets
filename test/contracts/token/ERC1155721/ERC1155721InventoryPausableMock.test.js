const {artifacts, accounts} = require('hardhat');
const {constants} = require('@animoca/ethereum-contracts-core');
const {ZeroAddress} = constants;
const {shouldBehaveLikeERC1155721} = require('./behaviors/ERC1155721.behavior');

const implementation = {
  contractName: 'ERC1155721InventoryPausableMock',
  nfMaskLength: 32,
  name: 'ERC1155721InventoryBurnableMock',
  symbol: 'INVB',
  revertMessages: {
    // ERC721
    SelfApproval: 'Inventory: self-approval',

    // ERC1155
    WrongCollectionMaskLength: 'Inventory: wrong mask length',
    SelfApprovalForAll: 'Inventory: self-approval',
    ZeroAddress: 'Inventory: zero address',
    NonApproved: 'Inventory: non-approved sender',
    TransferToZero: 'Inventory: transfer to zero',
    MintToZero: 'Inventory: mint to zero',
    ZeroValue: 'Inventory: zero value',
    InconsistentArrays: 'Inventory: inconsistent arrays',
    InsufficientBalance: 'Inventory: not enough balance',
    TransferRejected: 'Inventory: transfer refused',
    SupplyOverflow: 'Inventory: supply overflow',
    NotMinter: 'MinterRole: not a Minter',

    // ERC1155Inventory
    ExistingCollection: 'Inventory: existing collection',
    ExistingOrBurntNFT: 'Inventory: existing/burnt NFT',
    NotCollection: 'Inventory: not a collection',
    NotToken: 'Inventory: not a token id',
    NonExistingNFT: 'Inventory: non-existing NFT',
    NonOwnedNFT: 'Inventory: non-owned NFT',
    WrongNFTValue: 'Inventory: wrong NFT value',
    NotNFT: 'Inventory: not an NFT',

    // Pausable
    AlreadyPaused: 'Pausable: paused',
    AlreadyUnpaused: 'Pausable: not paused',

    // Admin
    NotPauser: 'Ownable: not the owner',
    NotMinter: 'MinterRole: not a Minter',
    NotContractOwner: 'Ownable: not the owner',
  },
  interfaces: {
    ERC721: true,
    ERC721Metadata: true,
    ERC1155: true,
    ERC1155MetadataURI: true,
    ERC1155Inventory: true,
    ERC1155InventoryTotalSupply: true,
    ERC1155InventoryCreator: true,
    ERC1155721InventoryBurnable: true,
    Pausable: true,
  },
  features: {BaseMetadataURI: true},
  methods: {
    // ERC721
    'batchTransferFrom(address,address,uint256[])': async function (contract, from, to, nftIds, overrides) {
      return contract.batchTransferFrom(from, to, nftIds, overrides);
    },
    'mint(address,uint256)': async function (contract, to, nftId, overrides) {
      return contract.mint(to, nftId, overrides);
    },
    'safeMint(address,uint256,bytes)': async function (contract, to, nftId, data, overrides) {
      return contract.methods['safeMint(address,uint256,bytes)'](to, nftId, data, overrides);
    },
    'batchMint(address,uint256[])': async function (contract, to, nftIds, overrides) {
      return contract.batchMint(to, nftIds, overrides);
    },
    'batchBurnFrom(address,uint256[])': async function (contract, from, nftIds, overrides) {
      return contract.methods['batchBurnFrom(address,uint256[])'](from, nftIds, overrides);
    },

    // ERC1155
    'safeMint(address,uint256,uint256,bytes)': async function (contract, to, id, value, data, overrides) {
      return contract.methods['safeMint(address,uint256,uint256,bytes)'](to, id, value, data, overrides);
    },
    'safeBatchMint(address,uint256[],uint256[],bytes)': async function (contract, to, ids, values, data, overrides) {
      return contract.safeBatchMint(to, ids, values, data, overrides);
    },
    'burnFrom(address,uint256,uint256)': async function (contract, from, id, value, overrides) {
      return contract.burnFrom(from, id, value, overrides);
    },
    'batchBurnFrom(address,uint256[],uint256[])': async function (contract, from, ids, values, overrides) {
      return contract.methods['batchBurnFrom(address,uint256[],uint256[])'](from, ids, values, overrides);
    },

    // ERC1155InventoryCreator
    'createCollection(uint256)': async function (contract, collectionId, overrides) {
      return contract.createCollection(collectionId, overrides);
    },

    // ERC1155721Deliverable
    'safeDeliver(address[],uint256[],uint256[],bytes)': async function (contract, tos, ids, values, data, overrides) {
      return contract.safeDeliver(tos, ids, values, data, overrides);
    },
  },
  deploy: async function (deployer, collectionMaskLength = 32) {
    const registry = await artifacts.require('ForwarderRegistry').new({from: deployer});
    const forwarder = await artifacts.require('UniversalForwarder').new({from: deployer});
    return artifacts.require('ERC1155721InventoryPausableMock').new(registry.address, ZeroAddress, collectionMaskLength, {from: deployer});
  },
  mint: async function (contract, to, id, value, overrides) {
    return contract.methods['safeMint(address,uint256,uint256,bytes)'](to, id, value, '0x', overrides);
  },
};

const [deployer] = accounts;

describe('ERC1155721InventoryPausableMock', function () {
  this.timeout(0);

  context('_msgData()', function () {
    it('it is called for 100% coverage', async function () {
      const token = await implementation.deploy(deployer);
      await token.msgData();
    });
  });

  shouldBehaveLikeERC1155721(implementation);
});
