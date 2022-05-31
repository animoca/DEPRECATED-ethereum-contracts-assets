const {artifacts, accounts} = require('hardhat');
const {expectEvent, expectRevert} = require('@openzeppelin/test-helpers');
const {constants} = require('@animoca/ethereum-contracts-core');
const {ZeroAddress} = constants;
const {shouldBehaveLikeERC1155} = require('./behaviors/ERC1155.behavior');

const implementation = {
  contractName: 'ERC1155SimpleMock',
  nfMaskLength: 32,
  revertMessages: {
    // ERC1155
    SelfApprovalForAll: 'ERC1155: self-approval',
    ZeroAddress: 'ERC1155: zero address',
    NonApproved: 'ERC1155: non-approved sender',
    TransferToZero: 'ERC1155: transfer to zero',
    MintToZero: 'ERC1155: mint to zero',
    ZeroValue: 'ERC1155: zero value',
    InconsistentArrays: 'ERC1155: inconsistent arrays',
    InsufficientBalance: 'ERC1155: not enough balance',
    BalanceOverflow: 'ERC1155: balance overflow',
    TransferRejected: 'ERC1155: transfer refused',

    // Admin
    NotMinter: 'MinterRole: not a Minter',
    // NotContractOwner: 'Ownable: not the owner',
  },
  interfaces: {
    ERC1155: true,
    ERC1155InventoryBurnable: true,
  },
  features: {},
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
  },
  deploy: async function (deployer) {
    const registry = await artifacts.require('ForwarderRegistry').new({from: deployer});
    return artifacts.require('ERC1155SimpleMock').new(registry.address, ZeroAddress, {from: deployer});
  },
  mint: async function (contract, to, id, value, overrides) {
    return contract.methods['safeMint(address,uint256,uint256,bytes)'](to, id, value, '0x', overrides);
  },
};

const [deployer, other] = accounts;

describe('ERC1155SimpleMock', function () {
  this.timeout(0);

  context('_msgData()', function () {
    it('it is called for 100% coverage', async function () {
      const token = await implementation.deploy(deployer);
      await token.msgData();
    });
  });

  describe('burn(address,uint256,uint256)', function () {
    const token1 = {
      id: '1',
      value: '1',
    };

    beforeEach(async function () {
      this.token = await implementation.deploy(deployer);
      await implementation.mint(this.token, other, token1.id, token1.value, {from: deployer});
    });

    it('reverts if not called by a minter', async function () {
      await expectRevert(
        this.token.methods['burn(address,uint256,uint256)'](other, token1.id, token1.value, {from: other}),
        implementation.revertMessages.NotMinter
      );
    });

    it('reverts if the account has an insufficient balance', async function () {
      await expectRevert(
        this.token.methods['burn(address,uint256,uint256)'](other, token1.id, '2', {from: deployer}),
        implementation.revertMessages.InsufficientBalance
      );
    });

    context('when successful', function () {
      beforeEach(async function () {
        this.receipt = await this.token.methods['burn(address,uint256,uint256)'](other, token1.id, token1.value, {from: deployer});
      });

      it('decreases the account balance', async function () {
        (await this.token.balanceOf(other, token1.id)).should.be.bignumber.equal('0');
      });

      it('emits a TransferSingle event', async function () {
        expectEvent(this.receipt, 'TransferSingle', {
          _operator: deployer,
          _from: other,
          _to: ZeroAddress,
          _id: token1.id,
          _value: token1.value,
        });
      });
    });
  });

  describe('batchBurn(address,uint256[],uint256[])', function () {
    const token1 = {
      id: '1',
      value: '1',
    };
    const token2 = {
      id: '2',
      value: '1',
    };

    beforeEach(async function () {
      this.token = await implementation.deploy(deployer);
      await implementation.mint(this.token, other, token1.id, token1.value, {from: deployer});
      await implementation.mint(this.token, other, token2.id, token2.value, {from: deployer});
    });

    it('reverts if not called by a minter', async function () {
      await expectRevert(
        this.token.methods['batchBurn(address,uint256[],uint256[])'](other, [token1.id], [token1.value], {from: other}),
        implementation.revertMessages.NotMinter
      );
    });

    it('reverts if the account has an insufficient balance', async function () {
      await expectRevert(
        this.token.methods['batchBurn(address,uint256[],uint256[])'](other, [token1.id], ['2'], {from: deployer}),
        implementation.revertMessages.InsufficientBalance
      );
      await expectRevert(
        this.token.methods['batchBurn(address,uint256[],uint256[])'](other, [token1.id, token2.id], [token1.value, '2'], {from: deployer}),
        implementation.revertMessages.InsufficientBalance
      );
    });

    context('when successful', function () {
      beforeEach(async function () {
        this.receipt = await this.token.methods['batchBurn(address,uint256[],uint256[])'](
          other,
          [token1.id, token2.id],
          [token1.value, token2.value],
          {from: deployer}
        );
      });

      it('decreases the account balance', async function () {
        (await this.token.balanceOf(other, token1.id)).should.be.bignumber.equal('0');
        (await this.token.balanceOf(other, token2.id)).should.be.bignumber.equal('0');
      });

      it('emits a TransferBatch event', async function () {
        expectEvent(this.receipt, 'TransferBatch', {
          _operator: deployer,
          _from: other,
          _to: ZeroAddress,
          _ids: [token1.id, token2.id],
          _values: [token1.value, token2.value],
        });
      });
    });
  });

  shouldBehaveLikeERC1155(implementation);
});
