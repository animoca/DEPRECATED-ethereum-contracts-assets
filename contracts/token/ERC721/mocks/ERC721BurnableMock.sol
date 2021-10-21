// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IForwarderRegistry} from "ethereum-universal-forwarder/src/solc_0.7/ERC2771/IForwarderRegistry.sol";
import {IERC721Metadata} from "./../interfaces/IERC721Metadata.sol";
import {IERC721Mintable} from "./../interfaces/IERC721Mintable.sol";
import {IERC721Burnable} from "./../interfaces/IERC721Burnable.sol";
import {ManagedIdentity} from "@animoca/ethereum-contracts-core/contracts/metatx/ManagedIdentity.sol";
import {Recoverable} from "@animoca/ethereum-contracts-core/contracts/utils/Recoverable.sol";
import {UsingUniversalForwarding} from "ethereum-universal-forwarder/src/solc_0.7/ERC2771/UsingUniversalForwarding.sol";
import {MinterRole} from "@animoca/ethereum-contracts-core/contracts/access/MinterRole.sol";
import {ERC721Burnable} from "./../ERC721Burnable.sol";
import {NFTBaseMetadataURI} from "./../../../metadata/NFTBaseMetadataURI.sol";

/**
 * @title ERC721 Burnable Mock.
 */
contract ERC721BurnableMock is Recoverable, UsingUniversalForwarding, ERC721Burnable, IERC721Mintable, NFTBaseMetadataURI, MinterRole {
    constructor(IForwarderRegistry forwarderRegistry, address universalForwarder)
        ERC721Burnable("ERC721BurnableMock", "E721B")
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
