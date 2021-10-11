module.exports = {
  // place here any user configuration which will override any pre-loaded configuration items (via lodash deep-merge)
  solidity: {
    overrides: {
      'contracts/mocks/token/ERC1155721/ERC1155721InventoryPausableMock.sol': {
        version: '0.7.6',
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },
    },
  },
};
