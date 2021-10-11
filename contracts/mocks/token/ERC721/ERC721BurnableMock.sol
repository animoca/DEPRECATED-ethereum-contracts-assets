// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {ManagedIdentity, Recoverable} from "@animoca/ethereum-contracts-core-1.1.2/contracts/utils/Recoverable.sol";
import {IForwarderRegistry, UsingUniversalForwarding} from "ethereum-universal-forwarder-1.0.0/src/solc_0.7/ERC2771/UsingUniversalForwarding.sol";
import {IERC721, IERC721Metadata, IERC721BatchTransfer, IERC721Burnable, ERC721, ERC721Burnable} from "../../../token/ERC721/ERC721Burnable.sol";
import {IERC721Mintable} from "../../../token/ERC721/IERC721Mintable.sol";
import {BaseMetadataURI} from "../../../metadata/BaseMetadataURI.sol";
import {MinterRole} from "@animoca/ethereum-contracts-core-1.1.2/contracts/access/MinterRole.sol";

/**
 * @title ERC721 Burnable Mock.
 */
contract ERC721BurnableMock is Recoverable, UsingUniversalForwarding, ERC721Burnable, IERC721Mintable, BaseMetadataURI, MinterRole {
    constructor(IForwarderRegistry forwarderRegistry, address universalForwarder)
        ERC721("ERC721BurnableMock", "E721B")
        UsingUniversalForwarding(forwarderRegistry, universalForwarder)
        MinterRole(msg.sender)
    {}

    //=================================================== ERC721Metadata ====================================================//

    /// @inheritdoc IERC721Metadata
    function tokenURI(uint256 nftId) external view virtual override returns (string memory) {
        require(address(uint160(_owners[nftId])) != address(0), "ERC721: non-existing NFT");
        return _uri(nftId);
    }

    //=================================================== ERC721Mintable ====================================================//

    /// @inheritdoc IERC721Mintable
    /// @dev Reverts if the sender is not a minter.
    function mint(address to, uint256 nftId) public virtual override {
        _requireMinter(_msgSender());
        _mint(to, nftId, "", false);
    }

    /// @inheritdoc IERC721Mintable
    /// @dev Reverts if the sender is not a minter.
    function batchMint(address to, uint256[] memory nftIds) public virtual override {
        _requireMinter(_msgSender());
        _batchMint(to, nftIds);
    }

    /// @inheritdoc IERC721Mintable
    /// @dev Reverts if the sender is not a minter.
    function safeMint(
        address to,
        uint256 nftId,
        bytes memory data
    ) public virtual override {
        _requireMinter(_msgSender());
        _mint(to, nftId, data, true);
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
