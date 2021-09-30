const {artifacts, accounts, web3} = require('hardhat');
const {createFixtureLoader} = require('@animoca/ethereum-contracts-core/test/utils/fixture');
const {constants} = require('@animoca/ethereum-contracts-core');
const {expectRevert, expectEvent} = require('@openzeppelin/test-helpers');
const {Zero, One, Two, MaxUInt256, ZeroAddress} = constants;
const {Withdrawn_EventSig} = require('../../../src/constants');
const {AbiCoder, RLP} = require('ethers/utils');

const abi = new AbiCoder();

const [deployer, holder, rootChainManager] = accounts;

describe('ERC20EscrowPredicate', function () {
  const fixtureLoader = createFixtureLoader(accounts, web3.eth.currentProvider);

  const fixture = async function () {
    this.predicate = await artifacts.require('ERC20EscrowPredicate').new(rootChainManager, {from: deployer});

    const forwarder = await artifacts.require('UniversalForwarder').new();
    const registry = await artifacts.require('ForwarderRegistry').new();
    this.token = await artifacts.require('ERC20Mock').new([holder], [One], registry.address, forwarder.address, {from: deployer});
  };

  beforeEach(async function () {
    await fixtureLoader(fixture, this);
  });

  describe('lockTokens(address,address,address,bytes)', function () {
    it('reverts if the sender is not the rootChainManager', async function () {
      const depositData = abi.encode(['uint256'], ['1']);
      await expectRevert(this.predicate.lockTokens(holder, holder, this.token.address, depositData, {from: holder}), 'Predicate: only manager');
    });

    it('reverts if the predicate does not have enough allowance', async function () {
      const depositData = abi.encode(['uint256'], ['1']);
      await expectRevert(
        this.predicate.lockTokens(holder, holder, this.token.address, depositData, {from: rootChainManager}),
        'ERC20: insufficient allowance'
      );
    });

    it('reverts if the depositor does not have enough balance', async function () {
      await this.token.approve(this.predicate.address, Two, {from: holder});
      const depositData = abi.encode(['uint256'], ['2']);
      await expectRevert(
        this.predicate.lockTokens(holder, holder, this.token.address, depositData, {from: rootChainManager}),
        'ERC20: insufficient balance'
      );
    });

    context('when successful', function () {
      beforeEach(async function () {
        await this.token.approve(this.predicate.address, Two, {from: holder});
        const depositData = abi.encode(['uint256'], ['1']);
        this.receipt = await this.predicate.lockTokens(holder, holder, this.token.address, depositData, {from: rootChainManager});
      });

      it('escrows the token amount', async function () {
        (await this.token.balanceOf(holder)).should.be.bignumber.equal(Zero);
        (await this.token.balanceOf(this.predicate.address)).should.be.bignumber.equal(One);
      });

      it('emits a LockedERC20 event', async function () {
        expectEvent(this.receipt, 'LockedERC20', {
          depositor: holder,
          depositReceiver: holder,
          rootToken: this.token.address,
          amount: One,
        });
      });
    });
  });

  describe('exitTokens(address,address,bytes)', function () {
    const eventLog = RLP.encode(['0x0', [Withdrawn_EventSig], abi.encode(['address', 'uint256'], [holder, '0x' + One.toString(16)])]);

    it('reverts if the sender is not the rootChainManager', async function () {
      await expectRevert(this.predicate.exitTokens(ZeroAddress, this.token.address, eventLog, {from: holder}), 'Predicate: only manager');
    });

    it('reverts if the predicate does not have enough balance', async function () {
      await expectRevert(
        this.predicate.exitTokens(ZeroAddress, this.token.address, eventLog, {from: rootChainManager}),
        'ERC20: insufficient balance'
      );
    });

    it('reverts if the event log is wrong', async function () {
      await this.token.approve(this.predicate.address, One, {from: holder});
      const wrongEventLog = RLP.encode([
        '0x0',
        ['0x7084f5476618d8e60b11ef0d7d3f06914655adb8793e28ff7f018d4c76d50000'],
        abi.encode(['address', 'uint256'], [holder, '0x' + One.toString(16)]),
      ]);

      await expectRevert(
        this.predicate.exitTokens(ZeroAddress, this.token.address, wrongEventLog, {from: rootChainManager}),
        'Predicate: invalid signature'
      );
    });

    context('when successful', function () {
      beforeEach(async function () {
        await this.token.approve(this.predicate.address, One, {from: holder});
        const depositData = abi.encode(['uint256'], ['1']);
        await this.predicate.lockTokens(holder, holder, this.token.address, depositData, {from: rootChainManager});
        this.receipt = await this.predicate.exitTokens(ZeroAddress, this.token.address, eventLog, {from: rootChainManager});
      });

      it('un-escrows the token amount', async function () {
        (await this.token.balanceOf(holder)).should.be.bignumber.equal(One);
        (await this.token.balanceOf(this.predicate.address)).should.be.bignumber.equal(Zero);
      });
    });
  });
});
