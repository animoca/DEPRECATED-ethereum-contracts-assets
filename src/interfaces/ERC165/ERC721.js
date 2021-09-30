const {makeInterfaceId} = require('@openzeppelin/test-helpers');

const ERC721_Functions = [
  'balanceOf(address)',
  'ownerOf(uint256)',
  'approve(address,uint256)',
  'getApproved(uint256)',
  'setApprovalForAll(address,bool)',
  'isApprovedForAll(address,address)',
  'transferFrom(address,address,uint256)',
  'safeTransferFrom(address,address,uint256)',
  'safeTransferFrom(address,address,uint256,bytes)',
];

const ERC721Metadata_Functions = ['name()', 'symbol()', 'tokenURI(uint256)'];

const ERC721BatchTransfer_Functions = ['batchTransferFrom(address,address,uint256[])'];

const ERC721Burnable_Functions = ['burnFrom(address,uint256)', 'batchBurnFrom(address,uint256[])'];

const ERC721Receiver_Functions = ['onERC721Received(address,address,uint256,bytes)'];

module.exports = {
  ERC721: {
    name: 'ERC721',
    functions: ERC721_Functions,
    id: makeInterfaceId.ERC165(ERC721_Functions),
  }, // '0x80ac58cd'

  ERC721Metadata: {
    name: 'ERC721Metadata',
    functions: ERC721Metadata_Functions,
    id: makeInterfaceId.ERC165(ERC721Metadata_Functions),
  }, // 0x5b5e139f

  ERC721BatchTransfer: {
    name: 'ERC721Burnable',
    functions: ERC721BatchTransfer_Functions,
    id: makeInterfaceId.ERC165(ERC721BatchTransfer_Functions),
  }, // 0xf3993d11

  ERC721Burnable: {
    name: 'ERC721Burnable',
    functions: ERC721Burnable_Functions,
    id: makeInterfaceId.ERC165(ERC721Burnable_Functions),
  }, // 0x8b8b4ef5

  ERC721Receiver: {
    name: 'ERC721Receiver',
    functions: ERC721Receiver_Functions,
    id: makeInterfaceId.ERC165(ERC721Receiver_Functions),
  }, // 0x150b7a02
};
