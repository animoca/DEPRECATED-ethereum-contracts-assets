const {artifacts, accounts} = require('hardhat');
const {expectEvent, expectRevert} = require('@openzeppelin/test-helpers');
const {constants} = require('@animoca/ethereum-contracts-core');
const {ZeroAddress} = constants;
const {createFixtureLoader} = require('@animoca/ethereum-contracts-core/test/utils/fixture');
const {shouldBehaveLikeERC20} = require('./behaviors/ERC20.behavior');

const implementation = {
  contractName: 'ERC20SimpleMock',
  revertMessages: {
    // ERC20
    ApproveToZero: 'ERC20: zero address spender',
    TransferExceedsBalance: 'ERC20: insufficient balance',
    TransferToZero: 'ERC20: to zero address',
    TransferExceedsAllowance: 'ERC20: insufficient allowance',
    TransferFromZero: 'ERC20: insufficient balance',
    InconsistentArrays: 'ERC20: inconsistent arrays',
    SupplyOverflow: 'ERC20: supply overflow',

    // ERC20Mintable
    MintToZero: 'ERC20: mint to zero',

    // ERC20Burnable
    BurnExceedsBalance: 'ERC20: insufficient balance',
    BurnExceedsAllowance: 'ERC20: insufficient allowance',

    // Admin
    NotMinter: 'MinterRole: not a Minter',
    NotContractOwner: 'Ownable: not the owner',
  },
  features: {
    EIP717: true, // unlimited approval
    AllowanceTracking: true,
  },
  interfaces: {
    ERC20: true,
  },
  methods: {
    'mint(address,uint256)': async (contract, account, value, overrides) => {
      return contract.mint(account, value, overrides);
    },
    'burn(uint256)': async (contract, value, overrides) => {
      return contract.burn(value, overrides);
    },
    'burnFrom(address,uint256)': async (contract, from, value, overrides) => {
      return contract.burnFrom(from, value, overrides);
    },
  },
  deploy: async function (initialHolders, initialBalances, deployer) {
    const forwarderRegistry = await artifacts.require('ForwarderRegistry').new({from: deployer});
    const contract = await artifacts.require('ERC20SimpleMock').new(forwarderRegistry.address, ZeroAddress, {from: deployer});
    for (let i = 0; i < initialHolders.length; ++i) {
      await contract.mint(initialHolders[i], initialBalances[i], {from: deployer});
    }
    return contract;
  },
};

const [deployer, other] = accounts;

describe('ERC20SimpleMock', function () {
  this.timeout(0);

  context('_msgData()', function () {
    it('it is called for 100% coverage', async function () {
      const token = await implementation.deploy([], [], deployer);
      await token.msgData();
    });
  });

  describe('burn(address,uint256)', function () {
    const amount = '1';

    beforeEach(async function () {
      this.token = await implementation.deploy([other], [amount], deployer);
    });

    it('reverts if not called by a minter', async function () {
      await expectRevert(this.token.methods['burn(address,uint256)'](other, amount, {from: other}), implementation.revertMessages.NotMinter);
    });

    it('reverts if the account has an insufficient balance', async function () {
      await expectRevert(
        this.token.methods['burn(address,uint256)'](other, '2', {from: deployer}),
        implementation.revertMessages.TransferExceedsBalance
      );
    });

    context('when successful', function () {
      beforeEach(async function () {
        this.receipt = await this.token.methods['burn(address,uint256)'](other, amount, {from: deployer});
      });

      it('decreases the total supply', async function () {
        (await this.token.totalSupply()).should.be.bignumber.equal('0');
      });

      it('decreases the account balance', async function () {
        (await this.token.balanceOf(other)).should.be.bignumber.equal('0');
      });

      it('emits a Transfer event', async function () {
        expectEvent(this.receipt, 'Transfer', {
          _from: other,
          _to: ZeroAddress,
          _value: amount,
        });
      });
    });
  });

  shouldBehaveLikeERC20(implementation);
});
