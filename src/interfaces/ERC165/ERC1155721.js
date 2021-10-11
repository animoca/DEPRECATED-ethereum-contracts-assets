const {makeInterfaceId} = require('@openzeppelin/test-helpers');

const ERC1155721InventoryBurnable_Functions = [
  'burnFrom(address,uint256,uint256)',
  'batchBurnFrom(address,uint256[],uint256[])',
  'batchBurnFrom(address,uint256[])',
];

module.exports = {
  ERC1155721InventoryBurnable: {
    name: 'ERC1155721InventoryBurnable',
    functions: ERC1155721InventoryBurnable_Functions,
    id: makeInterfaceId.ERC165(ERC1155721InventoryBurnable_Functions),
  }, // 0x6059f1b4
};
