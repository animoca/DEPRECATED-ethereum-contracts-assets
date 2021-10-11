const {artifacts, accounts} = require('hardhat');
const interfaces721 = require('../../../../src/interfaces/ERC165/ERC721');
const interfaces1155 = require('../../../../src/interfaces/ERC165/ERC1155');
const {constants, behaviors} = require('@animoca/ethereum-contracts-core');
const {ZeroAddress} = constants;

describe('ERC1155721ReceiverMock', function () {
  const [deployer] = accounts;

  beforeEach(async function () {
    this.contract = await artifacts.require('ERC1155721ReceiverMock').new(true, true, ZeroAddress, {from: deployer});
  });

  behaviors.shouldSupportInterfaces([interfaces721.ERC721Receiver, interfaces1155.ERC1155TokenReceiver]);
});
