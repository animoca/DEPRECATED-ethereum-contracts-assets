const {shouldBehaveLikeERC20} = require('./contracts/token/ERC20/behaviors/ERC20.behavior');
const {shouldBehaveLikeERC721} = require('./contracts/token/ERC721/behaviors/ERC721.behavior');
const {shouldBehaveLikeERC1155} = require('./contracts/token/ERC1155/behaviors/ERC1155.behavior');

module.exports = {
  shouldBehaveLikeERC20,
  shouldBehaveLikeERC721,
  shouldBehaveLikeERC1155,
};
