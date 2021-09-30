const {artifacts, accounts} = require('hardhat');
const interfaces721 = require('../../../../src/interfaces/ERC165/ERC721');
const {constants, behaviors} = require('@animoca/ethereum-contracts-core');
const {ZeroAddress} = constants;

describe('ERC721ReceiverMock', function () {
  const [deployer] = accounts;

  beforeEach(async function () {
    this.contract = await artifacts.require('ERC721ReceiverMock').new(true, ZeroAddress, {from: deployer});
  });

  behaviors.shouldSupportInterfaces([interfaces721.ERC721Receiver]);
});
