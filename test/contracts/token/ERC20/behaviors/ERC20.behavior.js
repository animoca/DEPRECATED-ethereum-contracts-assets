const {shouldBehaveLikeERC20Allowance} = require('./ERC20.allowance.behavior');
const {shouldBehaveLikeERC20Burnable} = require('./ERC20.burnable.behavior');
const {shouldBehaveLikeERC20Detailed} = require('./ERC20.detailed.behavior');
const {shouldBehaveLikeERC20Metadata} = require('./ERC20.metadata.behavior');
const {shouldBehaveLikeERC20Mintable} = require('./ERC20.mintable.behavior');
const {shouldBehaveLikeERC20BatchTransfers} = require('./ERC20.batchtransfers.behavior');
const {shouldBehaveLikeERC20Permit} = require('./ERC20.permit.behavior');
const {shouldBehaveLikeERC20Safe} = require('./ERC20.safe.behavior');
const {shouldBehaveLikeERC20Standard} = require('./ERC20.standard.behavior');

function shouldBehaveLikeERC20(implementation) {
  describe('like an ERC20', function () {
    if (implementation.interfaces.ERC20) {
      shouldBehaveLikeERC20Standard(implementation);
    }

    if (implementation.interfaces.ERC20Detailed) {
      shouldBehaveLikeERC20Detailed(implementation);
    }

    if (implementation.interfaces.ERC20Metadata) {
      shouldBehaveLikeERC20Metadata(implementation);
    }

    if (implementation.interfaces.ERC20Allowance) {
      shouldBehaveLikeERC20Allowance(implementation);
    }

    if (implementation.interfaces.ERC20BatchTransfer) {
      shouldBehaveLikeERC20BatchTransfers(implementation);
    }

    if (implementation.interfaces.ERC20Permit) {
      shouldBehaveLikeERC20Permit(implementation);
    }

    if (implementation.interfaces.ERC20Safe) {
      shouldBehaveLikeERC20Safe(implementation);
    }

    shouldBehaveLikeERC20Burnable(implementation);
    shouldBehaveLikeERC20Mintable(implementation);
  });
}

module.exports = {
  shouldBehaveLikeERC20,
};
