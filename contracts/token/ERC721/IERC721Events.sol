// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC721 Non-Fungible Token Standard, basic interface (events).
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 * @dev This interface only contains the standard events, see IERC721 for the functions.
 * @dev Note: The ERC-165 identifier for this interface is 0x80ac58cd.
 */
interface IERC721Events {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
}
