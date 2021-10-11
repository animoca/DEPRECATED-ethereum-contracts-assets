const {artifacts, accounts} = require('hardhat');
const interfaces1155 = require('../../../../src/interfaces/ERC165/ERC1155');
const {constants, behaviors} = require('@animoca/ethereum-contracts-core');
const {ZeroAddress} = constants;

describe('ERC1155TokenReceiverMock', function () {
  const [deployer] = accounts;

  beforeEach(async function () {
    this.contract = await artifacts.require('ERC1155TokenReceiverMock').new(true, ZeroAddress, {from: deployer});
  });

  behaviors.shouldSupportInterfaces([interfaces1155.ERC1155TokenReceiver]);
});
