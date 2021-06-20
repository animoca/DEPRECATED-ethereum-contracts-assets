const {accounts, web3} = require('hardhat');
const {createFixtureLoader} = require('@animoca/ethereum-contracts-core/test/utils/fixture');
const {BN, expectEvent, expectRevert} = require('@openzeppelin/test-helpers');
const Account = require('../../../../utils/account');
const Signing = require('../../../../utils/signing');

const {behaviors} = require('@animoca/ethereum-contracts-core');

const interfaces20 = require('../../../../../src/interfaces/ERC165/ERC20');
const {Zero, One, ZeroAddress} = require('@animoca/ethereum-contracts-core/src/constants');

function shouldBehaveLikeERC20Permit(implementation) {
  const {features, revertMessages, deploy} = implementation;
  const [deployer, owner, spender, other] = accounts;

  const initialSupply = new BN(100);
  const noDeadline = new BN(-1).toTwos(256);

  describe('like a permit ERC20', function () {
    const fixtureLoader = createFixtureLoader(accounts, web3.eth.currentProvider);
    const fixture = async function () {
      this.token = await deploy([owner], [initialSupply], deployer);
      this.chainId = await web3.eth.getChainId();
    };

    beforeEach(async function () {
      await fixtureLoader(fixture, this);
    });

    before(async function () {
      this.privateKey = await Account.getPrivateKeyHardhat(owner);
    });

    const getTypedData = async function (params = {}) {
      return {
        types: {
          EIP712Domain: [
            {name: 'name', type: 'string'},
            {name: 'version', type: 'string'},
            {name: 'chainId', type: 'uint256'},
            {name: 'verifyingContract', type: 'address'},
          ],
          Permit: [
            {name: 'owner', type: 'address'},
            {name: 'spender', type: 'address'},
            {name: 'value', type: 'uint256'},
            {name: 'nonce', type: 'uint256'},
            {name: 'deadline', type: 'uint256'},
          ],
        },
        primaryType: 'Permit',
        domain: {
          name: params.name || implementation.name,
          version: params.version || '1',
          chainId: params.chainId || this.chainId,
          verifyingContract: params.verifyingContract || this.token.address,
        },
        message: {
          owner: params.owner || owner,
          spender: params.spender || spender,
          value: params.value || One,
          nonce: params.nonce || (await this.token.nonces(params.owner || owner)),
          deadline: params.deadline || noDeadline,
        },
      };
    };

    describe('permit(address,address,uint256,uint256,uint8,bytes32,bytes32)', function () {
      context('when the permit is valid', function () {
        const value = One;
        const deadline = noDeadline;

        beforeEach(async function () {
          this.nonce = await this.token.nonces(owner);
          const typedData = await getTypedData.bind(this)({value, nonce: this.nonce, deadline});
          this.signature = Signing.signTypedData(typedData, this.privateKey);
        });

        context('when calling permit() with a zero address owner', function () {
          it('reverts', async function () {
            await expectRevert(
              this.token.permit(ZeroAddress, spender, value, deadline, this.signature.v, this.signature.r, this.signature.s),
              revertMessages.PermitFromZero
            );
          });
        });

        context('when calling permit() with matching parameters to the permit', function () {
          beforeEach(async function () {
            this.receipt = await this.token.permit(owner, spender, value, deadline, this.signature.v, this.signature.r, this.signature.s);
          });

          it('updates the permit nonce of the owner correctly', async function () {
            (await this.token.nonces(owner)).should.be.bignumber.equal(this.nonce.add(One));
          });

          it('approves the spender allowance from the owner', async function () {
            (await this.token.allowance(owner, spender)).should.be.bignumber.equal(value);
          });

          it('emits the Approval event', async function () {
            expectEvent(this.receipt, 'Approval', {_owner: owner, _spender: spender, _value: value});
          });
        });
      });

      context('when the permit is invalid', function () {
        context('when the permit is for a different token name', function () {
          it('reverts', async function () {
            const name = other;
            const value = One;
            const deadline = noDeadline;
            const typedData = await getTypedData.bind(this)({name, value, deadline});
            signature = Signing.signTypedData(typedData, this.privateKey);
            await expectRevert(
              this.token.permit(owner, spender, value, deadline, signature.v, signature.r, signature.s),
              revertMessages.PermitInvalid
            );
          });
        });

        context('when the permit is for a different token version', function () {
          it('reverts', async function () {
            const version = Zero;
            const value = One;
            const deadline = noDeadline;
            const typedData = await getTypedData.bind(this)({version, value, deadline});
            signature = Signing.signTypedData(typedData, this.privateKey);
            await expectRevert(
              this.token.permit(owner, spender, value, deadline, signature.v, signature.r, signature.s),
              revertMessages.PermitInvalid
            );
          });
        });

        context('when the permit is for a different chain', function () {
          it('reverts', async function () {
            const chainId = 123456;
            const value = One;
            const deadline = noDeadline;
            const typedData = await getTypedData.bind(this)({chainId, value, deadline});
            signature = Signing.signTypedData(typedData, this.privateKey);
            await expectRevert(
              this.token.permit(owner, spender, value, deadline, signature.v, signature.r, signature.s),
              revertMessages.PermitInvalid
            );
          });
        });

        context('when the permit is for a different token contract', function () {
          it('reverts', async function () {
            const verifyingContract = ZeroAddress;
            const value = One;
            const deadline = noDeadline;
            const typedData = await getTypedData.bind(this)({verifyingContract, value, deadline});
            signature = Signing.signTypedData(typedData, this.privateKey);
            await expectRevert(
              this.token.permit(owner, spender, value, deadline, signature.v, signature.r, signature.s),
              revertMessages.PermitInvalid
            );
          });
        });

        context('when the permit is for a different owner', function () {
          it('reverts', async function () {
            const otherOwner = other;
            const value = One;
            const deadline = noDeadline;
            const typedData = await getTypedData.bind(this)({value, deadline, owner: otherOwner});
            signature = Signing.signTypedData(typedData, this.privateKey);
            await expectRevert(
              this.token.permit(owner, spender, value, deadline, signature.v, signature.r, signature.s),
              revertMessages.PermitInvalid
            );
          });
        });

        context('when the permit is for a different spender', function () {
          it('reverts', async function () {
            const otherSpender = other;
            const value = One;
            const deadline = noDeadline;
            const typedData = await getTypedData.bind(this)({value, deadline, spender: otherSpender});
            signature = Signing.signTypedData(typedData, this.privateKey);
            await expectRevert(
              this.token.permit(owner, spender, value, deadline, signature.v, signature.r, signature.s),
              revertMessages.PermitInvalid
            );
          });
        });

        context('when the permit is for a different value', function () {
          it('reverts', async function () {
            const otherValue = Zero;
            const value = One;
            const deadline = noDeadline;
            const typedData = await getTypedData.bind(this)({value: otherValue, deadline});
            signature = Signing.signTypedData(typedData, this.privateKey);
            await expectRevert(
              this.token.permit(owner, spender, value, deadline, signature.v, signature.r, signature.s),
              revertMessages.PermitInvalid
            );
          });
        });

        context('when the permit is for a different nonce', function () {
          it('reverts', async function () {
            const nonce = (await this.token.nonces(owner)).add(One);
            const value = One;
            const deadline = noDeadline;
            const typedData = await getTypedData.bind(this)({value, nonce, deadline});
            signature = Signing.signTypedData(typedData, this.privateKey);
            await expectRevert(
              this.token.permit(owner, spender, value, deadline, signature.v, signature.r, signature.s),
              revertMessages.PermitInvalid
            );
          });
        });

        context('when the permit is for a different deadline', function () {
          it('reverts', async function () {
            const otherDeadline = noDeadline.sub(One);
            const value = One;
            const deadline = noDeadline;
            const typedData = await getTypedData.bind(this)({value, deadline: otherDeadline});
            signature = Signing.signTypedData(typedData, this.privateKey);
            await expectRevert(
              this.token.permit(owner, spender, value, deadline, signature.v, signature.r, signature.s),
              revertMessages.PermitInvalid
            );
          });
        });

        context('when the permit expiry has passed', function () {
          it('reverts', async function () {
            const value = One;
            const deadline = One;
            const typedData = await getTypedData.bind(this)({value, deadline});
            signature = Signing.signTypedData(typedData, this.privateKey);
            await expectRevert(this.token.permit(owner, spender, One, deadline, signature.v, signature.r, signature.s), revertMessages.PermitExpired);
          });
        });
      });
    });

    describe('nonces(address)', function () {
      context('when the nonce is for an account with no previous permits', function () {
        it('returns the zero nonce', async function () {
          (await this.token.nonces(other)).should.be.bignumber.equal(Zero);
        });
      });

      context('when the nonce is for an account with previous permits', function () {
        it('returns the next nonce', async function () {
          this.nonce = await this.token.nonces(owner);
          const typedData = await getTypedData.bind(this)({owner: owner, nonce: this.nonce});
          const signature = Signing.signTypedData(typedData, this.privateKey);
          await this.token.permit(owner, spender, One, noDeadline, signature.v, signature.r, signature.s);
          (await this.token.nonces(owner)).should.be.bignumber.equal(this.nonce.add(One));
        });
      });
    });

    describe('DOMAIN_SEPARATOR()', function () {
      it('returns the correct domain separator', async function () {
        const typedData = await getTypedData.bind(this)();
        const domainSeparator = `0x${Signing.domainSeparator(typedData)}`;
        (await this.token.DOMAIN_SEPARATOR()).should.be.equal(domainSeparator);
      });
    });

    if (features.ERC165) {
      behaviors.shouldSupportInterfaces([interfaces20.ERC20Permit]);
    }
  });
}

module.exports = {
  shouldBehaveLikeERC20Permit,
};
