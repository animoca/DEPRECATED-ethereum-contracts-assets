const {artifacts, accounts, web3} = require('hardhat');
const {createFixtureLoader} = require('@animoca/ethereum-contracts-core/test/utils/fixture');
const {expectEventWithParamsOverride} = require('@animoca/ethereum-contracts-core/test/utils/events');
const {BN, expectEvent, expectRevert} = require('@openzeppelin/test-helpers');
const {One, ZeroAddress, MaxUInt256, Zero} = require('@animoca/ethereum-contracts-core/src/constants');

const ReceiverType = require('../../ReceiverType');

const {makeFungibleCollectionId, makeNonFungibleCollectionId, makeNonFungibleTokenId, isNonFungibleToken, isFungible, getNonFungibleCollectionId} =
  require('@animoca/blockchain-inventory_metadata').inventoryIds;

const ERC1155TokenReceiverMock = artifacts.require('ERC1155TokenReceiverMock');
const ERC721ReceiverMock = artifacts.require('ERC721ReceiverMock');

function shouldBehaveLikeERC1155721Deliverable({
  contractName,
  nfMaskLength,
  revertMessages,
  eventParamsOverrides,
  interfaces,
  methods,
  deploy,
  mint,
}) {
  const [deployer, owner, _operator, _approved, other] = accounts;

  const {'safeDeliver(address[],uint256[],uint256[],bytes)': safeDeliver} = methods;

  if (safeDeliver === undefined) {
    console.log(
      `ERC1155721InventoryDeliverable: non-standard ERC1155721 method safeDeliver(address[],uint256[],uint256[],bytes)` +
        ` is not supported by ${contractName}, associated tests will be skipped`
    );
  }

  const fCollection1 = {
    id: makeFungibleCollectionId(1),
    supply: 10,
  };
  const fCollection2 = {
    id: makeFungibleCollectionId(2),
    supply: 11,
  };
  const fCollection3 = {
    id: makeFungibleCollectionId(3),
    supply: 12,
  };
  const unknownFCollection = {
    id: makeFungibleCollectionId(4),
    supply: 0,
  };
  const nfCollection = makeNonFungibleCollectionId(1, nfMaskLength);
  const nfCollectionOther = makeNonFungibleCollectionId(2, nfMaskLength);
  const unknownNFCollection = makeNonFungibleCollectionId(99, nfMaskLength);
  const nft1 = makeNonFungibleTokenId(1, 1, nfMaskLength);
  const nft2 = makeNonFungibleTokenId(2, 1, nfMaskLength);
  const nftOtherCollection = makeNonFungibleTokenId(1, 2, nfMaskLength);
  const unknownNft = makeNonFungibleTokenId(99, 99, nfMaskLength);

  describe('like a deliverable ERC1155721Inventory', function () {
    const fixtureLoader = createFixtureLoader(accounts, web3.eth.currentProvider);
    const fixture = async function () {
      this.token = await deploy(deployer);
      await mint(this.token, other, unknownFCollection.id, MaxUInt256, {from: deployer});
      this.receiver721 = await ERC721ReceiverMock.new(true, this.token.address);
      this.receiver1155 = await ERC1155TokenReceiverMock.new(true, this.token.address);
      this.refusingReceiver1155 = await ERC1155TokenReceiverMock.new(false, this.token.address);
    };

    beforeEach(async function () {
      await fixtureLoader(fixture, this);
    });

    const computeDeliveryContent = function (tokens) {
      const result = {
        supplies: {},
        balances: {},
        nftBalances: {},
      };

      for (const [recipient, id, value] of tokens) {
        if (result.supplies[id] == undefined) {
          result.supplies[id] = new BN(value);
        } else {
          result.supplies[id] = result.supplies[id].add(new BN(value));
        }
        if (result.balances[recipient] == undefined) {
          result.balances[recipient] = {};
        }
        if (result.balances[recipient][id] == undefined) {
          result.balances[recipient][id] = new BN(value);
        } else {
          result.balances[recipient][id] = result.balances[recipient][id].add(new BN(value));
        }

        if (isNonFungibleToken(id, nfMaskLength)) {
          if (result.nftBalances[recipient] == undefined) {
            result.nftBalances[recipient] = One;
          } else {
            result.nftBalances[recipient] = result.nftBalances[recipient].add(One);
          }
          const nfc = getNonFungibleCollectionId(id, nfMaskLength);
          if (result.supplies[nfc] == undefined) {
            result.supplies[nfc] = new BN(value);
          } else {
            result.supplies[nfc] = result.supplies[nfc].add(new BN(value));
          }
          if (result.balances[recipient] == undefined) {
            result.balances[recipient] = {};
          }
          if (result.balances[recipient][nfc] == undefined) {
            result.balances[recipient][nfc] = new BN(value);
          } else {
            result.balances[recipient][nfc] = result.balances[recipient][nfc].add(new BN(value));
          }
        }
      }

      return result;
    };

    const getRecipientAddress = function (recipient) {
      if (recipient == ReceiverType.NON_RECEIVER) {
        return this.token.address;
      } else if (recipient == ReceiverType.ERC721_RECEIVER) {
        return this.receiver721.address;
      } else if (recipient == ReceiverType.ERC1155_RECEIVER) {
        return this.receiver1155.address;
      }
      return recipient;
    };

    const deliveryWasSuccessful = function (recipients, ids, values, data, options) {
      const tokens = recipients.map((recipient, i) => [recipient, ids[i], values[i]]);
      const fungibleTokens = tokens.filter(([_recipient, id]) => isFungible(id));
      const nonFungibleTokens = tokens.filter(([_recipient, id]) => isNonFungibleToken(id, nfMaskLength));

      const delivered = computeDeliveryContent(tokens);

      const nftsSentToERC721Receiver = nonFungibleTokens.filter(([recipient]) => recipient == ReceiverType.ERC721_RECEIVER);
      const tokensSentToERC1155Receiver = tokens.filter(([recipient]) => recipient == ReceiverType.ERC1155_RECEIVER);

      if (tokens.length != 0) {
        it('increases the recipient(s) balance(s)', async function () {
          for (const [recipient, id] of tokens) {
            const recipientAddress = getRecipientAddress.call(this, recipient);
            (await this.token.balanceOf(recipientAddress, id)).should.be.bignumber.equal(delivered.balances[recipient][id]);
          }
        });

        if (interfaces.ERC1155InventoryTotalSupply) {
          it('[ERC1155InventoryTotalSupply] increases the token(s) total supply', async function () {
            for (const [_recipient, id, _value] of tokens) {
              (await this.token.totalSupply(id)).should.be.bignumber.equal(delivered.supplies[id]);
            }
          });
        }

        if (nonFungibleTokens.length != 0) {
          if (interfaces.ERC721 || interfaces.ERC1155Inventory) {
            it('[ERC721/ERC1155Inventory] gives the ownership of the Non-Fungible Token(s) to the recipient', async function () {
              for (const [recipient, id] of nonFungibleTokens) {
                (await this.token.ownerOf(id)).should.be.equal(getRecipientAddress.call(this, recipient));
              }
            });
          }
          if (interfaces.ERC1155Inventory) {
            it('[ERC1155Inventory] increases the recipient Non-Fungible Collection(s) balance(s)', async function () {
              for (const [recipient, id] of nonFungibleTokens) {
                const nfc = getNonFungibleCollectionId(id, nfMaskLength);
                (await this.token.balanceOf(getRecipientAddress.call(this, recipient), nfc)).should.be.bignumber.equal(
                  delivered.balances[recipient][nfc]
                );
              }
            });

            if (interfaces.ERC1155InventoryTotalSupply) {
              it('[ERC1155Inventory/ERC1155InventoryTotalSupply] increases the Non-Fungible Collection(s) total supply', async function () {
                for (const [_recipient, id] of nonFungibleTokens) {
                  const nfc = getNonFungibleCollectionId(id, nfMaskLength);
                  (await this.token.totalSupply(nfc)).should.be.bignumber.equal(delivered.supplies[nfc]);
                }
              });

              it('[ERC1155Inventory/ERC1155InventoryTotalSupply] sets the Non-Fungible Token(s) total supply to 1', async function () {
                for (const [_recipient, id] of nonFungibleTokens) {
                  (await this.token.totalSupply(id)).should.be.bignumber.equal('1');
                }
              });
            }
          }
          if (interfaces.ERC721 && nonFungibleTokens.length != 0) {
            it('[ERC721] sets an empty approval for the Non-Fungible Token(s)', async function () {
              for (const [_recipient, id, _value] of nonFungibleTokens) {
                (await this.token.getApproved(id)).should.be.equal(ZeroAddress);
              }
            });

            it('[ERC721] increases the recipient NFTs balance', async function () {
              for (const [recipient] of nonFungibleTokens) {
                (await this.token.balanceOf(getRecipientAddress.call(this, recipient))).should.be.bignumber.equal(delivered.nftBalances[recipient]);
              }
            });

            it('[ERC721] emits Transfer event(s) for Non-Fungible Tokens', function () {
              for (const [recipient, id, _value] of nonFungibleTokens) {
                expectEventWithParamsOverride(
                  this.receipt,
                  'Transfer',
                  {
                    _from: ZeroAddress,
                    _to: getRecipientAddress.call(this, recipient),
                    _tokenId: id,
                  },
                  eventParamsOverrides
                );
              }
            });

            if (nftsSentToERC721Receiver.length != 0) {
              it('[ERC721] should call onERC721Received', async function () {
                for (const [_recipient, id, _value] of nftsSentToERC721Receiver) {
                  await expectEvent.inTransaction(this.receipt.tx, ERC721ReceiverMock, 'Received', {
                    operator: options.from,
                    from: ZeroAddress,
                    tokenId: id,
                    data: data,
                  });
                }
              });
            }
          }
        }

        it('emits TransferSingle events', function () {
          for (const [recipient, id, value] of tokens) {
            expectEventWithParamsOverride(
              this.receipt,
              'TransferSingle',
              {
                _operator: options.from,
                _from: ZeroAddress,
                _to: getRecipientAddress.call(this, recipient),
                _id: id,
                _value: value,
              },
              eventParamsOverrides
            );
          }
        });

        if (tokensSentToERC1155Receiver.length != 0) {
          it('[ERC1155] should call onERC1155Received', async function () {
            for (const [_recipient, id, value] of tokensSentToERC1155Receiver) {
              await expectEvent.inTransaction(this.receipt.tx, ERC1155TokenReceiverMock, 'ReceivedSingle', {
                operator: options.from,
                from: ZeroAddress,
                id: id,
                value: value,
                data: data,
              });
            }
          });
        }
      }
    };

    describe('safeDeliver(address[],uint256[],uint256[],bytes)', function () {
      if (safeDeliver === undefined) {
        return;
      }

      const data = '0x42';
      const options = {from: deployer};
      describe('Pre-conditions', function () {
        it('reverts if the sender is not a Minter', async function () {
          await expectRevert(safeDeliver(this.token, [owner], [nft1], [1], data, {from: other}), revertMessages.NotMinter);
        });

        it('reverts with inconsistent arrays', async function () {
          await expectRevert(safeDeliver(this.token, [owner], [nft1, nft2], [1, 1], data, {from: deployer}), revertMessages.InconsistentArrays);
          await expectRevert(safeDeliver(this.token, [owner, owner], [nft1, nft2], [1], data, {from: deployer}), revertMessages.InconsistentArrays);
          await expectRevert(safeDeliver(this.token, [owner, owner], [nft1], [1], data, {from: deployer}), revertMessages.InconsistentArrays);
        });

        it('reverts if transferred to the zero address', async function () {
          await expectRevert(safeDeliver(this.token, [ZeroAddress], [nft1], [1], data, options), revertMessages.MintToZero);
        });

        it('reverts if a Fungible Token has a value equal 0', async function () {
          await expectRevert(safeDeliver(this.token, [other], [fCollection1.id], [0], data, options), revertMessages.ZeroValue);
        });

        it('reverts if a Fungible Token has an overflowing supply', async function () {
          await expectRevert(safeDeliver(this.token, [other], [unknownFCollection.id], [1], data, options), revertMessages.SupplyOverflow);
        });

        it('reverts if a Non-Fungible Token has a value different from 1', async function () {
          await expectRevert(safeDeliver(this.token, [other], [nft1], [0], data, options), revertMessages.WrongNFTValue);
          await expectRevert(safeDeliver(this.token, [other], [nft1], [2], data, options), revertMessages.WrongNFTValue);
        });

        it('reverts with an existing Non-Fungible Token', async function () {
          await safeDeliver(this.token, [owner], [unknownNft], [1], data, options);
          await expectRevert(safeDeliver(this.token, [owner], [unknownNft], [1], data, options), revertMessages.ExistingNFT);
        });

        if (interfaces.ERC1155Inventory) {
          it('[ERC1155Inventory] reverts if the id is a Non-Fungible Collection', async function () {
            await expectRevert(safeDeliver(this.token, [owner], [nfCollection], [1], data, options), revertMessages.NotToken);
          });
        }

        it('reverts when sent to a non-receiver contract', async function () {
          await expectRevert.unspecified(safeDeliver(this.token, [this.token.address], [nft1], [1], data, options));
        });

        it('reverts when sent to an ERC1155TokenReceiver which refuses the transfer', async function () {
          await expectRevert(
            safeDeliver(this.token, [this.refusingReceiver1155.address], [nft1], [1], data, options),
            revertMessages.TransferRejected
          );
        });
      });

      const shouldSafeDeliver = function (recipients, ids, values, data, options) {
        beforeEach(async function () {
          this.receipt = await safeDeliver(
            this.token,
            recipients.map((recipient) => getRecipientAddress.call(this, recipient)),
            ids,
            values,
            data,
            options
          );
        });
        deliveryWasSuccessful(recipients, ids, values, data, options);
      };
      context('with an empty list of tokens', function () {
        shouldSafeDeliver([], [], [], data, options);
      });
      context('with Fungible Tokens', function () {
        context('single minting', function () {
          shouldSafeDeliver([owner], [fCollection1.id], [1], data, options);
        });
        context('multiple minting', function () {
          shouldSafeDeliver(
            [owner, ReceiverType.ERC1155_RECEIVER, owner],
            [fCollection1.id, fCollection2.id, fCollection3.id],
            [fCollection1.supply, 1, fCollection3.supply],
            data,
            options
          );
        });
      });
      context('with Non-Fungible Tokens', function () {
        context('single token transfer', function () {
          shouldSafeDeliver([owner], [nft1], [1], data, options);
        });
        context('multiple tokens transfer', function () {
          shouldSafeDeliver(
            [owner, ReceiverType.ERC1155_RECEIVER, ReceiverType.ERC721_RECEIVER],
            [nft1, nft2, nftOtherCollection],
            [1, 1, 1],
            data,
            options
          );
        });
      });
      context('with Fungible and Non-Fungible Tokens', function () {
        context('multiple tokens sorted by Non-Fungible Collection transfer', function () {
          shouldSafeDeliver(
            [owner, owner, ReceiverType.ERC1155_RECEIVER, ReceiverType.ERC1155_RECEIVER, ReceiverType.ERC721_RECEIVER],
            [fCollection1.id, nft1, fCollection2.id, nftOtherCollection, nft2],
            [2, 1, fCollection2.supply, 1, 1],
            data,
            options
          );
        });
      });
    });
  });
}

module.exports = {
  shouldBehaveLikeERC1155721Deliverable,
};
