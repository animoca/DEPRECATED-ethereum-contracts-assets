const {makeInterfaceId} = require('@openzeppelin/test-helpers');

const ERC20_Functions = [
  'totalSupply()',
  'balanceOf(address)',
  'transfer(address,uint256)',
  'allowance(address,address)',
  'approve(address,uint256)',
  'transferFrom(address,address,uint256)',
];

const ERC20Burnable_Functions = ['burn(uint256)', 'burnFrom(address,uint256)'];

const ERC20Detailed_Functions = ['name()', 'symbol()', 'decimals()'];

const ERC20Metadata_Functions = ['tokenURI()'];

const ERC20Allowance_Functions = ['increaseAllowance(address,uint256)', 'decreaseAllowance(address,uint256)'];

const ERC20BatchTransfers_Functions = ['batchTransfer(address[],uint256[])', 'batchTransferFrom(address,address[],uint256[])'];

const ERC20Receiver_Functions = ['onERC20Received(address,address,uint256,bytes)'];

const ERC20Safe_Functions = ['safeTransfer(address,uint256,bytes)', 'safeTransferFrom(address,address,uint256,bytes)'];

const ERC20Permit_Functions = ['permit(address,address,uint256,uint256,uint8,bytes32,bytes32)', 'nonces(address)', 'DOMAIN_SEPARATOR()'];

module.exports = {
  ERC20: {
    name: 'ERC20',
    functions: ERC20_Functions,
    id: makeInterfaceId.ERC165(ERC20_Functions),
  }, // '0x36372b07'
  ERC20Burnable: {
    name: 'ERC20Burnable',
    functions: ERC20Burnable_Functions,
    id: makeInterfaceId.ERC165(ERC20Burnable_Functions),
  }, // '0x3b5a0bf8'
  ERC20Detailed: {
    name: 'ERC20Detailed',
    functions: ERC20Detailed_Functions,
    id: makeInterfaceId.ERC165(ERC20Detailed_Functions),
  }, // '0xa219a025'
  ERC20Metadata: {
    name: 'ERC20Metadata',
    functions: ERC20Metadata_Functions,
    id: makeInterfaceId.ERC165(ERC20Metadata_Functions),
  }, // '0x3c130d90'
  ERC20Allowance: {
    name: 'ERC20Allowance',
    functions: ERC20Allowance_Functions,
    id: makeInterfaceId.ERC165(ERC20Allowance_Functions),
  }, // '0x9d075186'
  ERC20BatchTransfers: {
    name: 'ERC20BatchTransfers',
    functions: ERC20BatchTransfers_Functions,
    id: makeInterfaceId.ERC165(ERC20BatchTransfers_Functions),
  }, // '0xc05327e6'
  ERC20SafeTransfers: {
    name: 'ERC20SafeTransfers',
    functions: ERC20Safe_Functions,
    id: makeInterfaceId.ERC165(ERC20Safe_Functions),
  }, // '0x53f41a97'
  ERC20Permit: {
    name: 'ERC20Permit',
    functions: ERC20Permit_Functions,
    id: makeInterfaceId.ERC165(ERC20Permit_Functions),
  }, // '0x9d8ff7da'
  ERC20Receiver: {
    name: 'ERC20Receiver',
    functions: ERC20Receiver_Functions,
    id: makeInterfaceId.ERC165(ERC20Receiver_Functions),
  }, // 0x4fc35859
};
