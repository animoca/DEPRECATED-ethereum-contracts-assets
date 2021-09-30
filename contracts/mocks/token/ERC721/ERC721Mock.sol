// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {ManagedIdentity, Recoverable} from "@animoca/ethereum-contracts-core-1.1.2/contracts/utils/Recoverable.sol";
import {IForwarderRegistry, UsingUniversalForwarding} from "ethereum-universal-forwarder/src/solc_0.7/ERC2771/UsingUniversalForwarding.sol";
import {IERC721Mintable} from "../../../token/ERC721/IERC721Mintable.sol";
import {IERC721Metadata, ERC721} from "../../../token/ERC721/ERC721.sol";
import {BaseMetadataURI} from "../../../metadata/BaseMetadataURI.sol";
import {MinterRole} from "@animoca/ethereum-contracts-core-1.1.2/contracts/access/MinterRole.sol";

/**
 * @title ERC721 Mock.
 */
contract ERC721Mock is Recoverable, UsingUniversalForwarding, ERC721, BaseMetadataURI, IERC721Mintable, MinterRole {
    constructor(IForwarderRegistry forwarderRegistry, address universalForwarder)
        ERC721("ERC721Mock", "E721")
        UsingUniversalForwarding(forwarderRegistry, universalForwarder)
        MinterRole(msg.sender)
    {}

    //=================================================== ERC721Metadata ====================================================//

    /// @inheritdoc IERC721Metadata
    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        require(address(uint160(_owners[tokenId])) != address(0), "ERC721: non-existing NFT");
        return _uri(tokenId);
    }

    //=================================================== ERC721Mintable ====================================================//

    /// @inheritdoc IERC721Mintable
    /// @dev Reverts if the sender is not a minter.
    function mint(address to, uint256 tokenId) external virtual override {
        _requireMinter(_msgSender());
        _mint(to, tokenId, "", false);
    }

    /// @inheritdoc IERC721Mintable
    /// @dev Reverts if the sender is not a minter.
    function batchMint(address to, uint256[] calldata tokenIds) external virtual override {
        _requireMinter(_msgSender());
        _batchMint(to, tokenIds);
    }

    /// @inheritdoc IERC721Mintable
    /// @dev Reverts if the sender is not a minter.
    function safeMint(
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external virtual override {
        _requireMinter(_msgSender());
        _mint(to, tokenId, data, true);
    }

    //======================================== Meta Transactions Internal Functions =========================================//

    function _msgSender() internal view virtual override(ManagedIdentity, UsingUniversalForwarding) returns (address payable) {
        return UsingUniversalForwarding._msgSender();
    }

    function _msgData() internal view virtual override(ManagedIdentity, UsingUniversalForwarding) returns (bytes memory ret) {
        return UsingUniversalForwarding._msgData();
    }

    //=============================================== Mock Coverage Functions ===============================================//

    function msgData() external view returns (bytes memory ret) {
        return _msgData();
    }
}
