// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IForwarderRegistry} from "ethereum-universal-forwarder/src/solc_0.7/ERC2771/IForwarderRegistry.sol";
import {IERC165} from "@animoca/ethereum-contracts-core/contracts/introspection/IERC165.sol";
import {IERC1155InventoryMintable} from "./../interfaces/IERC1155InventoryMintable.sol";
import {IERC1155InventoryBurnable} from "./../interfaces/IERC1155InventoryBurnable.sol";
import {ManagedIdentity} from "@animoca/ethereum-contracts-core/contracts/metatx/ManagedIdentity.sol";
import {Recoverable} from "@animoca/ethereum-contracts-core/contracts/utils/Recoverable.sol";
import {UsingUniversalForwarding} from "ethereum-universal-forwarder/src/solc_0.7/ERC2771/UsingUniversalForwarding.sol";
import {MinterRole} from "@animoca/ethereum-contracts-core/contracts/access/MinterRole.sol";
import {ERC1155Simple} from "./../ERC1155Simple.sol";

/**
 * @title ERC1155 Inventory Burnable Mock.
 */
contract ERC1155SimpleMock is Recoverable, UsingUniversalForwarding, ERC1155Simple, IERC1155InventoryMintable, IERC1155InventoryBurnable, MinterRole {
    constructor(IForwarderRegistry forwarderRegistry, address universalForwarder)
        UsingUniversalForwarding(forwarderRegistry, universalForwarder)
        MinterRole(msg.sender)
    {}

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC1155InventoryBurnable).interfaceId || super.supportsInterface(interfaceId);
    }

    //============================================== ERC1155InventoryMintable ===============================================//

    /// @inheritdoc IERC1155InventoryMintable
    /// @dev Reverts if the sender is not a minter.
    function safeMint(
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external virtual override {
        address operator = _msgSender();
        _requireMinter(operator);
        _safeMint(operator, to, id, value, data);
    }

    /// @inheritdoc IERC1155InventoryMintable
    /// @dev Reverts if the sender is not a minter.
    function safeBatchMint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external virtual override {
        address operator = _msgSender();
        _requireMinter(operator);
        _safeBatchMint(operator, to, ids, values, data);
    }

    function burn(
        address from,
        uint256 id,
        uint256 value
    ) external virtual {
        address operator = _msgSender();
        _requireMinter(operator);
        _burn(operator, from, id, value);
    }

    function batchBurn(
        address from,
        uint256[] calldata ids,
        uint256[] calldata values
    ) external virtual {
        address operator = _msgSender();
        _requireMinter(operator);
        _batchBurn(operator, from, ids, values);
    }

    //============================================== ERC1155InventoryBurnable ===============================================//

    /// @inheritdoc IERC1155InventoryBurnable
    function burnFrom(
        address from,
        uint256 id,
        uint256 value
    ) external virtual override {
        _burnFrom(from, id, value);
    }

    /// @inheritdoc IERC1155InventoryBurnable
    function batchBurnFrom(
        address from,
        uint256[] calldata ids,
        uint256[] calldata values
    ) external virtual override {
        _batchBurnFrom(from, ids, values);
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
