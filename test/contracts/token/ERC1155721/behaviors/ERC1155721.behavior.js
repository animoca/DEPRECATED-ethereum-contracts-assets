const {shouldBehaveLikeERC721} = require('../../ERC721/behaviors/ERC721.behavior');
const {shouldBehaveLikeERC1155} = require('../../ERC1155/behaviors/ERC1155.behavior');
const {shouldBehaveLikeERC1155721Deliverable} = require('./ERC1155721.deliverable.behavior');

function shouldBehaveLikeERC1155721(implementation) {
  describe('like an ERC1155721', function () {
    shouldBehaveLikeERC721(implementation);
    shouldBehaveLikeERC1155(implementation);
    shouldBehaveLikeERC1155721Deliverable(implementation);
  });
}

module.exports = {
  shouldBehaveLikeERC1155721,
};
