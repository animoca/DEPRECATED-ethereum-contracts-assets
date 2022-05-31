// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {ERC1155InventoryIdentifiersLib} from "./ERC1155InventoryIdentifiersLib.sol";
import {IERC165} from "@animoca/ethereum-contracts-core/contracts/introspection/IERC165.sol";
import {IERC1155} from "./interfaces/IERC1155.sol";
import {IERC1155MetadataURI} from "./interfaces/IERC1155MetadataURI.sol";
import {IERC1155InventoryFunctions} from "./interfaces/IERC1155InventoryFunctions.sol";
import {IERC1155InventoryTotalSupply} from "./interfaces/IERC1155InventoryTotalSupply.sol";
import {IERC1155InventoryBurnable} from "./interfaces/IERC1155InventoryBurnable.sol";
import {ERC1155Inventory} from "./ERC1155Inventory.sol";

/**
 * @title ERC1155Inventory, burnable version.
 * @dev The function `uri(uint256)` needs to be implemented by a child contract, for example with the help of `NFTBaseMetadataURI`.
 */
abstract contract ERC1155InventoryBurnable is IERC1155InventoryBurnable, ERC1155Inventory {
    using ERC1155InventoryIdentifiersLib for uint256;

    constructor(uint256 collectionMaskLength) ERC1155Inventory(collectionMaskLength) {}

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(IERC1155InventoryFunctions).interfaceId ||
            interfaceId == type(IERC1155InventoryTotalSupply).interfaceId ||
            interfaceId == type(IERC1155InventoryBurnable).interfaceId;
    }

    //============================================== ERC1155InventoryBurnable ===============================================//

    /// @inheritdoc IERC1155InventoryBurnable
    function burnFrom(
        address from,
        uint256 id,
        uint256 value
    ) public virtual override {
        address sender = _msgSender();
        require(_isOperatable(from, sender), "Inventory: non-approved sender");

        if (id.isFungibleToken()) {
            _burnFungible(from, id, value);
        } else if (id.isNonFungibleToken(_collectionMaskLength)) {
            _burnNFT(from, id, value, false);
        } else {
            revert("Inventory: not a token id");
        }

        emit TransferSingle(sender, from, address(0), id, value);
    }

    /// @inheritdoc IERC1155InventoryBurnable
    function batchBurnFrom(
        address from,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual override {
        uint256 length = ids.length;
        require(length == values.length, "Inventory: inconsistent arrays");

        address sender = _msgSender();
        require(_isOperatable(from, sender), "Inventory: non-approved sender");

        uint256 nfCollectionId;
        uint256 nfCollectionCount;
        for (uint256 i; i != length; ++i) {
            uint256 id = ids[i];
            uint256 value = values[i];
            if (id.isFungibleToken()) {
                _burnFungible(from, id, value);
            } else if (id.isNonFungibleToken(_collectionMaskLength)) {
                _burnNFT(from, id, value, true);
                uint256 nextCollectionId = id.getNonFungibleCollection(_collectionMaskLength);
                if (nfCollectionId == 0) {
                    nfCollectionId = nextCollectionId;
                    nfCollectionCount = 1;
                } else {
                    if (nextCollectionId != nfCollectionId) {
                        _balances[nfCollectionId][from] -= nfCollectionCount;
                        _supplies[nfCollectionId] -= nfCollectionCount;
                        nfCollectionId = nextCollectionId;
                        nfCollectionCount = 1;
                    } else {
                        ++nfCollectionCount;
                    }
                }
            } else {
                revert("Inventory: not a token id");
            }
        }

        if (nfCollectionId != 0) {
            _balances[nfCollectionId][from] -= nfCollectionCount;
            _supplies[nfCollectionId] -= nfCollectionCount;
        }

        emit TransferBatch(sender, from, address(0), ids, values);
    }

    //============================================== Helper Internal Functions ==============================================//

    function _burnFungible(
        address from,
        uint256 id,
        uint256 value
    ) internal {
        require(value != 0, "Inventory: zero value");
        uint256 balance = _balances[id][from];
        require(balance >= value, "Inventory: not enough balance");
        _balances[id][from] = balance - value;
        // Cannot underflow
        _supplies[id] -= value;
    }

    function _burnNFT(
        address from,
        uint256 id,
        uint256 value,
        bool isBatch
    ) internal {
        require(value == 1, "Inventory: wrong NFT value");
        require(from == address(uint160(_owners[id])), "Inventory: non-owned NFT");
        _owners[id] = _BURNT_NFT_OWNER;

        if (!isBatch) {
            uint256 collectionId = id.getNonFungibleCollection(_collectionMaskLength);
            // cannot underflow as balance is confirmed through ownership
            --_balances[collectionId][from];
            // Cannot underflow
            --_supplies[collectionId];
        }
    }
}
