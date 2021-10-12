// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {ERC1155InventoryIdentifiersLib} from "./ERC1155InventoryIdentifiersLib.sol";
import {ManagedIdentity} from "@animoca/ethereum-contracts-core-1.1.2/contracts/metatx/ManagedIdentity.sol";
import {IERC165} from "@animoca/ethereum-contracts-core-1.1.2/contracts/introspection/IERC165.sol";
import {IERC1155, IERC1155InventoryFunctions, IERC1155Inventory} from "./IERC1155Inventory.sol";
import {IERC1155MetadataURI} from "./../ERC1155/IERC1155MetadataURI.sol";
import {IERC1155InventoryTotalSupply} from "./../ERC1155/IERC1155InventoryTotalSupply.sol";
import {IERC1155TokenReceiver} from "./../ERC1155/IERC1155TokenReceiver.sol";

/**
 * @title ERC1155 Inventory Base.
 * @dev The functions `safeTransferFrom(address,address,uint256,uint256,bytes)`
 *  and `safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)` need to be implemented by a child contract.
 * @dev The function `uri(uint256)` needs to be implemented by a child contract, for example with the help of `BaseMetadataURI`.
 */
abstract contract ERC1155InventoryBase is ManagedIdentity, IERC165, IERC1155Inventory, IERC1155MetadataURI, IERC1155InventoryTotalSupply {
    using ERC1155InventoryIdentifiersLib for uint256;

    uint256 internal immutable _collectionMaskLength;

    // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 internal constant _ERC1155_RECEIVED = 0xf23a6e61;

    // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
    bytes4 internal constant _ERC1155_BATCH_RECEIVED = 0xbc197c81;

    // Burnt Non-Fungible Token owner's magic value
    uint256 internal constant _BURNT_NFT_OWNER = 0xdead000000000000000000000000000000000000000000000000000000000000;

    /* owner => operator => approved */
    mapping(address => mapping(address => bool)) internal _operators;

    /* collection ID => owner => balance */
    mapping(uint256 => mapping(address => uint256)) internal _balances;

    /* collection ID => supply */
    mapping(uint256 => uint256) internal _supplies;

    /* NFT ID => owner */
    mapping(uint256 => uint256) internal _owners;

    /* collection ID => creator */
    mapping(uint256 => address) internal _creators;

    constructor(uint256 collectionMaskLength) {
        require(collectionMaskLength != 0 && collectionMaskLength < 256, "Inventory: wrong mask length");
        _collectionMaskLength = collectionMaskLength;
    }

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(IERC1155InventoryFunctions).interfaceId ||
            interfaceId == type(IERC1155InventoryTotalSupply).interfaceId;
    }

    //======================================================= ERC1155 =======================================================//

    /// @inheritdoc IERC1155Inventory
    function balanceOf(address owner, uint256 id) public view virtual override returns (uint256) {
        require(owner != address(0), "Inventory: zero address");

        if (id.isNonFungibleToken(_collectionMaskLength)) {
            return address(uint160(_owners[id])) == owner ? 1 : 0;
        }

        return _balances[id][owner];
    }

    /// @inheritdoc IERC1155Inventory
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view virtual override returns (uint256[] memory) {
        require(owners.length == ids.length, "Inventory: inconsistent arrays");

        uint256[] memory balances = new uint256[](owners.length);

        for (uint256 i = 0; i != owners.length; ++i) {
            balances[i] = balanceOf(owners[i], ids[i]);
        }

        return balances;
    }

    /// @inheritdoc IERC1155
    function setApprovalForAll(address operator, bool approved) public virtual override {
        address sender = _msgSender();
        require(operator != sender, "Inventory: self-approval");
        _operators[sender][operator] = approved;
        emit ApprovalForAll(sender, operator, approved);
    }

    /// @inheritdoc IERC1155
    function isApprovedForAll(address tokenOwner, address operator) public view virtual override returns (bool) {
        return _operators[tokenOwner][operator];
    }

    //================================================== ERC1155Inventory ===================================================//

    /// @inheritdoc IERC1155Inventory
    function isFungible(uint256 id) external pure virtual override returns (bool) {
        return id.isFungibleToken();
    }

    /// @inheritdoc IERC1155Inventory
    function collectionOf(uint256 nftId) external view virtual override returns (uint256) {
        require(nftId.isNonFungibleToken(_collectionMaskLength), "Inventory: not an NFT");
        return nftId.getNonFungibleCollection(_collectionMaskLength);
    }

    /// @inheritdoc IERC1155Inventory
    function ownerOf(uint256 nftId) public view virtual override returns (address) {
        address owner = address(uint160(_owners[nftId]));
        require(owner != address(0), "Inventory: non-existing NFT");
        return owner;
    }

    //============================================= ERC1155InventoryTotalSupply =============================================//

    /// @inheritdoc IERC1155InventoryTotalSupply
    function totalSupply(uint256 id) external view virtual override returns (uint256) {
        if (id.isNonFungibleToken(_collectionMaskLength)) {
            return address(uint160(_owners[id])) == address(0) ? 0 : 1;
        } else {
            return _supplies[id];
        }
    }

    //============================================ High-level Internal Functions ============================================//

    /**
     * Creates a collection (optional).
     * @dev Reverts if `collectionId` does not represent a collection.
     * @dev Reverts if `collectionId` has already been created.
     * @dev Emits a {IERC1155Inventory-CollectionCreated} event.
     * @param collectionId Identifier of the collection.
     */
    function _createCollection(uint256 collectionId) internal virtual {
        require(!collectionId.isNonFungibleToken(_collectionMaskLength), "Inventory: not a collection");
        require(_creators[collectionId] == address(0), "Inventory: existing collection");
        _creators[collectionId] = _msgSender();
        emit CollectionCreated(collectionId, collectionId.isFungibleToken());
    }

    function _creator(uint256 collectionId) internal view virtual returns (address) {
        require(!collectionId.isNonFungibleToken(_collectionMaskLength), "Inventory: not a collection");
        return _creators[collectionId];
    }

    //============================================== Helper Internal Functions ==============================================//

    /**
     * Returns whether `sender` is authorised to make a transfer on behalf of `from`.
     * @param from The address to check operatibility upon.
     * @param sender The sender address.
     * @return True if sender is `from` or an operator for `from`, false otherwise.
     */
    function _isOperatable(address from, address sender) internal view virtual returns (bool) {
        return (from == sender) || _operators[from][sender];
    }

    /**
     * Calls {IERC1155TokenReceiver-onERC1155Received} on a target contract.
     * @dev Reverts if `to` is not a contract.
     * @dev Reverts if the call to the target fails or is refused.
     * @param from Previous token owner.
     * @param to New token owner.
     * @param id Identifier of the token transferred.
     * @param value Amount of token transferred.
     * @param data Optional data to send along with the receiver contract call.
     */
    function _callOnERC1155Received(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) internal {
        require(IERC1155TokenReceiver(to).onERC1155Received(_msgSender(), from, id, value, data) == _ERC1155_RECEIVED, "Inventory: transfer refused");
    }

    /**
     * Calls {IERC1155TokenReceiver-onERC1155batchReceived} on a target contract.
     * @dev Reverts if `to` is not a contract.
     * @dev Reverts if the call to the target fails or is refused.
     * @param from Previous tokens owner.
     * @param to New tokens owner.
     * @param ids Identifiers of the tokens to transfer.
     * @param values Amounts of tokens to transfer.
     * @param data Optional data to send along with the receiver contract call.
     */
    function _callOnERC1155BatchReceived(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal {
        require(
            IERC1155TokenReceiver(to).onERC1155BatchReceived(_msgSender(), from, ids, values, data) == _ERC1155_BATCH_RECEIVED,
            "Inventory: transfer refused"
        );
    }
}
