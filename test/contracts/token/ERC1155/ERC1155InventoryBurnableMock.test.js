const {artifacts} = require('hardhat');
const {shouldBehaveLikeERC1155} = require('./behaviors/ERC1155.behavior');

const implementation = {
  contractName: 'ERC1155InventoryBurnableMock',
  nfMaskLength: 32,
  revertMessages: {
    // ERC1155
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
  },
  interfaces: {
    ERC1155: true,
    ERC1155MetadataURI: true,
    ERC1155Inventory: true,
    ERC1155InventoryTotalSupply: true,
    ERC1155InventoryCreator: true,
    ERC1155InventoryBurnable: true,
  },
  methods: {
    'safeMint(address,uint256,uint256,bytes)': async function (contract, to, id, value, data, overrides) {
      return contract.safeMint(to, id, value, data, overrides);
    },
    'safeBatchMint(address,uint256[],uint256[],bytes)': async function (contract, to, ids, values, data, overrides) {
      return contract.safeBatchMint(to, ids, values, data, overrides);
    },
    'burnFrom(address,uint256,uint256)': async function (contract, from, id, value, overrides) {
      return contract.burnFrom(from, id, value, overrides);
    },
    'batchBurnFrom(address,uint256[],uint256[])': async function (contract, from, ids, values, overrides) {
      return contract.batchBurnFrom(from, ids, values, overrides);
    },
    'createCollection(uint256)': async function (contract, collectionId, overrides) {
      return contract.createCollection(collectionId, overrides);
    },
  },
  deploy: async function (deployer) {
    return artifacts.require('ERC1155InventoryBurnableMock').new({from: deployer});
  },
  mint: async function (contract, to, id, value, overrides) {
    return contract.methods['safeMint(address,uint256,uint256,bytes)'](to, id, value, '0x', overrides);
  },
};

describe('ERC1155InventoryBurnableMock', function () {
  this.timeout(0);
  shouldBehaveLikeERC1155(implementation);
});
