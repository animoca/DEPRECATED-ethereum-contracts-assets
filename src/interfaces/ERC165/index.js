const ERC20Interfaces = require('./ERC20');
const ERC721Interfaces = require('./ERC721');
const ERC1155Interfaces = require('./ERC1155');
const ERC1155721Interfaces = require('./ERC1155721');
const MetadataInterfaces = require('./Metadata');

module.exports = {
  ...ERC20Interfaces,
  ...ERC721Interfaces,
  ...ERC1155Interfaces,
  ...ERC1155721Interfaces,
  ...MetadataInterfaces,
};
console.log(module.exports);
