module.exports = {
  solidity: {
    overrides: {
      'contracts/token/ERC1155721/mocks/ERC1155721InventoryBurnableMock.sol': {
        version: '0.7.6',
        settings: {
          optimizer: {
            enabled: true,
            runs: 750,
          },
        },
      },
      'contracts/token/ERC1155721/mocks/ERC1155721InventoryPausableMock.sol': {
        version: '0.7.6',
        settings: {
          optimizer: {
            enabled: true,
            runs: 250,
          },
        },
      },
    },
  },
};
