// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {ERC1155InventoryIdentifiersLib} from "./../ERC1155/ERC1155InventoryIdentifiersLib.sol";
import {IERC165} from "@animoca/ethereum-contracts-core/contracts/introspection/IERC165.sol";
import {IERC721} from "./../ERC721/interfaces/IERC721.sol";
import {IERC721Metadata} from "./../ERC721/interfaces/IERC721Metadata.sol";
import {IERC721BatchTransfer} from "./../ERC721/interfaces/IERC721BatchTransfer.sol";
import {IERC1155} from "./../ERC1155/interfaces/IERC1155.sol";
import {IERC1155Inventory} from "./../ERC1155/interfaces/IERC1155Inventory.sol";
import {IERC1155MetadataURI} from "./../ERC1155/interfaces/IERC1155MetadataURI.sol";
import {IERC1155InventoryFunctions} from "./../ERC1155/interfaces/IERC1155InventoryFunctions.sol";
import {IERC1155InventoryTotalSupply} from "./../ERC1155/interfaces/IERC1155InventoryTotalSupply.sol";
import {IERC1155721InventoryBurnable} from "./interfaces/IERC1155721InventoryBurnable.sol";
import {ERC1155721Inventory} from "./ERC1155721Inventory.sol";

/**
 * @title ERC1155721Inventory, an ERC1155Inventory with additional support for ERC721, burnable version.
 * @dev The function `uri(uint256)` needs to be implemented by a child contract, for example with the help of `NFTBaseMetadataURI`.
 */
abstract contract ERC1155721InventoryBurnable is IERC1155721InventoryBurnable, ERC1155721Inventory {
    using ERC1155InventoryIdentifiersLib for uint256;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 collectionMaskLength
    ) ERC1155721Inventory(name_, symbol_, collectionMaskLength) {}

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721BatchTransfer).interfaceId ||
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(IERC1155InventoryFunctions).interfaceId ||
            interfaceId == type(IERC1155InventoryTotalSupply).interfaceId ||
            interfaceId == type(IERC1155721InventoryBurnable).interfaceId;
    }

    //============================================= ERC1155721InventoryBurnable =============================================//

    /// @inheritdoc IERC1155721InventoryBurnable
    function burnFrom(
        address from,
        uint256 id,
        uint256 value
    ) public virtual override {
        address sender = _msgSender();
        bool operatable = _isOperatable(from, sender);

        if (id.isFungibleToken()) {
            _burnFungible(from, id, value, operatable);
        } else if (id.isNonFungibleToken(_collectionMaskLength)) {
            _burnNFT(from, id, value, operatable, false);
            emit Transfer(from, address(0), id);
        } else {
            revert("Inventory: not a token id");
        }

        emit TransferSingle(sender, from, address(0), id, value);
    }

    /// @inheritdoc IERC1155721InventoryBurnable
    function batchBurnFrom(
        address from,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual override {
        uint256 length = ids.length;
        require(length == values.length, "Inventory: inconsistent arrays");

        address sender = _msgSender();
        bool operatable = _isOperatable(from, sender);

        uint256 nfCollectionId;
        uint256 nfCollectionCount;
        uint256 nftsCount;
        for (uint256 i; i != length; ++i) {
            uint256 id = ids[i];
            if (id.isFungibleToken()) {
                _burnFungible(from, id, values[i], operatable);
            } else if (id.isNonFungibleToken(_collectionMaskLength)) {
                _burnNFT(from, id, values[i], operatable, true);
                emit Transfer(from, address(0), id);
                uint256 nextCollectionId = id.getNonFungibleCollection(_collectionMaskLength);
                if (nfCollectionId == 0) {
                    nfCollectionId = nextCollectionId;
                    nfCollectionCount = 1;
                } else {
                    if (nextCollectionId != nfCollectionId) {
                        _burnNFTUpdateCollection(from, nfCollectionId, nfCollectionCount);
                        nfCollectionId = nextCollectionId;
                        nftsCount += nfCollectionCount;
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
            _burnNFTUpdateCollection(from, nfCollectionId, nfCollectionCount);
            nftsCount += nfCollectionCount;
            // cannot underflow as balance is verified through ownership
            _nftBalances[from] -= nftsCount;
        }

        emit TransferBatch(sender, from, address(0), ids, values);
    }

    /// @inheritdoc IERC1155721InventoryBurnable
    function batchBurnFrom(address from, uint256[] memory nftIds) public virtual override {
        address sender = _msgSender();
        bool operatable = _isOperatable(from, sender);

        uint256 length = nftIds.length;
        uint256[] memory values = new uint256[](length);

        uint256 nfCollectionId;
        uint256 nfCollectionCount;
        for (uint256 i; i != length; ++i) {
            uint256 nftId = nftIds[i];
            values[i] = 1;
            _burnNFT(from, nftId, values[i], operatable, true);
            emit Transfer(from, address(0), nftId);
            uint256 nextCollectionId = nftId.getNonFungibleCollection(_collectionMaskLength);
            if (nfCollectionId == 0) {
                nfCollectionId = nextCollectionId;
                nfCollectionCount = 1;
            } else {
                if (nextCollectionId != nfCollectionId) {
                    _burnNFTUpdateCollection(from, nfCollectionId, nfCollectionCount);
                    nfCollectionId = nextCollectionId;
                    nfCollectionCount = 1;
                } else {
                    ++nfCollectionCount;
                }
            }
        }

        if (nfCollectionId != 0) {
            _burnNFTUpdateCollection(from, nfCollectionId, nfCollectionCount);
            _nftBalances[from] -= length;
        }

        emit TransferBatch(sender, from, address(0), nftIds, values);
    }

    //============================================== Helper Internal Functions ==============================================//

    function _burnFungible(
        address from,
        uint256 id,
        uint256 value,
        bool operatable
    ) internal {
        require(value != 0, "Inventory: zero value");
        require(operatable, "Inventory: non-approved sender");
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
        bool operatable,
        bool isBatch
    ) internal virtual {
        require(value == 1, "Inventory: wrong NFT value");
        uint256 owner = _owners[id];
        require(from == address(uint160(owner)), "Inventory: non-owned NFT");
        if (!operatable) {
            require((owner & _APPROVAL_BIT_TOKEN_OWNER_ != 0) && _msgSender() == _nftApprovals[id], "Inventory: non-approved sender");
        }
        _owners[id] = _BURNT_NFT_OWNER;

        if (!isBatch) {
            _burnNFTUpdateCollection(from, id.getNonFungibleCollection(_collectionMaskLength), 1);

            // cannot underflow as balance is verified through NFT ownership
            --_nftBalances[from];
        }
    }

    function _burnNFTUpdateCollection(
        address from,
        uint256 collectionId,
        uint256 amount
    ) internal virtual {
        // cannot underflow as balance is verified through NFT ownership
        _balances[collectionId][from] -= amount;
        _supplies[collectionId] -= amount;
    }
}
