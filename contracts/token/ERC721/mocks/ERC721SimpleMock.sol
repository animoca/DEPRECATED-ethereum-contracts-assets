// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IForwarderRegistry} from "ethereum-universal-forwarder/src/solc_0.7/ERC2771/IForwarderRegistry.sol";
import {ManagedIdentity} from "@animoca/ethereum-contracts-core/contracts/metatx/ManagedIdentity.sol";
import {Recoverable} from "@animoca/ethereum-contracts-core/contracts/utils/Recoverable.sol";
import {UsingUniversalForwarding} from "ethereum-universal-forwarder/src/solc_0.7/ERC2771/UsingUniversalForwarding.sol";
import {MinterRole} from "@animoca/ethereum-contracts-core/contracts/access/MinterRole.sol";
import {ERC721Simple} from "./../ERC721Simple.sol";

/**
 * @title ERC721 Mock.
 */
contract ERC721SimpleMock is Recoverable, UsingUniversalForwarding, ERC721Simple, MinterRole {
    constructor(IForwarderRegistry forwarderRegistry, address universalForwarder)
        UsingUniversalForwarding(forwarderRegistry, universalForwarder)
        MinterRole(msg.sender)
    {}

    //=================================================== Minting (admin) ===================================================//

    /**
     * Unsafely mints a token.
     * @dev Reverts if the sender is not a minter.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if `tokenId` has already been minted.
     * @dev Emits an {IERC721-Transfer} event from the zero address.
     * @param to Address of the new token owner.
     * @param tokenId Identifier of the token to mint.
     */
    function mint(address to, uint256 tokenId) external {
        _requireMinter(_msgSender());
        _mint(to, tokenId);
    }

    /**
     * Burns a token.
     * @dev Reverts if the sender is not a minter.
     * @dev Reverts if `tokenId` does not exist.
     * @dev Emits an {IERC721-Transfer} event to the zero address.
     * @param tokenId Identifier of the token to burn.
     */
    function burn(uint256 tokenId) external {
        _requireMinter(_msgSender());
        _burn(tokenId);
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
