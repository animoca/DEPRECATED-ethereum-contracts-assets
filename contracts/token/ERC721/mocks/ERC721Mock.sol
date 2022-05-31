// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IForwarderRegistry} from "ethereum-universal-forwarder/src/solc_0.7/ERC2771/IForwarderRegistry.sol";
import {IERC721Metadata} from "./../interfaces/IERC721Metadata.sol";
import {IERC721Mintable} from "./../interfaces/IERC721Mintable.sol";
import {ManagedIdentity} from "@animoca/ethereum-contracts-core/contracts/metatx/ManagedIdentity.sol";
import {Recoverable} from "@animoca/ethereum-contracts-core/contracts/utils/Recoverable.sol";
import {UsingUniversalForwarding} from "ethereum-universal-forwarder/src/solc_0.7/ERC2771/UsingUniversalForwarding.sol";
import {MinterRole} from "@animoca/ethereum-contracts-core/contracts/access/MinterRole.sol";
import {ERC721} from "./../ERC721.sol";
import {NFTBaseMetadataURI} from "./../../../metadata/NFTBaseMetadataURI.sol";

/**
 * @title ERC721 Mock.
 */
contract ERC721Mock is Recoverable, UsingUniversalForwarding, ERC721, NFTBaseMetadataURI, IERC721Mintable, MinterRole {
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
        _mint(to, tokenId);
    }

    /// @inheritdoc IERC721Mintable
    /// @dev Reverts if the sender is not a minter.
    function batchMint(address to, uint256[] calldata tokenIds) external virtual override {
        _requireMinter(_msgSender());
        _batchMint(to, tokenIds);
    }

    /// @dev Reverts if the sender is not a minter.
    function safeMint(
        address to,
        uint256 tokenId
    ) external virtual {
        address operator = _msgSender();
        _requireMinter(operator);
        _safeMint(operator, to, tokenId);
    }

    /// @inheritdoc IERC721Mintable
    /// @dev Reverts if the sender is not a minter.
    function safeMint(
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external virtual override {
        address operator = _msgSender();
        _requireMinter(operator);
        _safeMint(operator, to, tokenId, data);
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
