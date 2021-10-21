// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {AddressIsContract} from "@animoca/ethereum-contracts-core/contracts/utils/types/AddressIsContract.sol";
import {ERC1155InventoryIdentifiersLib} from "./../ERC1155/ERC1155InventoryIdentifiersLib.sol";
import {IERC165} from "@animoca/ethereum-contracts-core/contracts/introspection/IERC165.sol";
import {IERC721} from "./../ERC721/interfaces/IERC721.sol";
import {IERC721Metadata} from "./../ERC721/interfaces/IERC721Metadata.sol";
import {IERC721BatchTransfer} from "./../ERC721/interfaces/IERC721BatchTransfer.sol";
import {IERC721Receiver} from "./../ERC721/interfaces/IERC721Receiver.sol";
import {IERC1155MetadataURI} from "./../ERC1155/interfaces/IERC1155MetadataURI.sol";
import {IERC1155TokenReceiver} from "./../ERC1155/interfaces/IERC1155TokenReceiver.sol";
import {IERC1155Inventory} from "./../ERC1155/interfaces/IERC1155Inventory.sol";
import {IERC1155721Inventory} from "./interfaces/IERC1155721Inventory.sol";
import {ERC1155InventoryBase} from "./../ERC1155/ERC1155InventoryBase.sol";

/**
 * @title ERC1155721Inventory, an ERC1155Inventory with additional support for ERC721.
 * @dev The function `uri(uint256)` needs to be implemented by a child contract, for example with the help of `NFTBaseMetadataURI`.
 */
abstract contract ERC1155721Inventory is IERC1155721Inventory, IERC721Metadata, ERC1155InventoryBase {
    using ERC1155InventoryIdentifiersLib for uint256;
    using AddressIsContract for address;

    uint256 internal constant _APPROVAL_BIT_TOKEN_OWNER_ = 1 << 160;

    string internal _name;
    string internal _symbol;

    /* owner => NFT balance */
    mapping(address => uint256) internal _nftBalances;

    /* NFT ID => operator */
    mapping(uint256 => address) internal _nftApprovals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 collectionMaskLength
    ) ERC1155InventoryBase(collectionMaskLength) {
        _name = name_;
        _symbol = symbol_;
    }

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721BatchTransfer).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    //=================================================== ERC721Metadata ====================================================//

    /// @inheritdoc IERC721Metadata
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /// @inheritdoc IERC721Metadata
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /// @inheritdoc IERC721Metadata
    function tokenURI(uint256 nftId) external view virtual override returns (string memory) {
        require(address(uint160(_owners[nftId])) != address(0), "Inventory: non-existing NFT");
        return uri(nftId);
    }

    //================================================= ERC1155MetadataURI ==================================================//

    /// @inheritdoc IERC1155MetadataURI
    function uri(uint256) public view virtual override returns (string memory);

    //======================================================= ERC721 ========================================================//

    /// @inheritdoc IERC721
    function balanceOf(address tokenOwner) external view virtual override returns (uint256) {
        require(tokenOwner != address(0), "Inventory: zero address");
        return _nftBalances[tokenOwner];
    }

    /// @inheritdoc IERC721
    function approve(address to, uint256 tokenId) public virtual override {
        uint256 owner = _owners[tokenId];
        require(owner != 0, "Inventory: non-existing NFT");
        address ownerAddress = address(uint160(owner));
        require(to != ownerAddress, "Inventory: self-approval");
        require(_isOperatable(ownerAddress, _msgSender()), "Inventory: non-approved sender");
        if (to == address(0)) {
            if (owner & _APPROVAL_BIT_TOKEN_OWNER_ != 0) {
                // remove the approval bit if it is present
                _owners[tokenId] = uint256(ownerAddress);
            }
        } else {
            uint256 ownerWithApprovalBit = owner | _APPROVAL_BIT_TOKEN_OWNER_;
            if (owner != ownerWithApprovalBit) {
                // add the approval bit if it is not present
                _owners[tokenId] = ownerWithApprovalBit;
            }
            _nftApprovals[tokenId] = to;
        }
        emit Approval(ownerAddress, to, tokenId);
    }

    /// @inheritdoc IERC721
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        uint256 owner = _owners[tokenId];
        require(address(uint160(owner)) != address(0), "Inventory: non-existing NFT");
        if (owner & _APPROVAL_BIT_TOKEN_OWNER_ != 0) {
            return _nftApprovals[tokenId];
        } else {
            return address(0);
        }
    }

    /// @inheritdoc IERC1155721Inventory
    function transferFrom(
        address from,
        address to,
        uint256 nftId
    ) public virtual override {
        _transferFrom(
            from,
            to,
            nftId,
            "",
            /* safe */
            false
        );
    }

    /// @inheritdoc IERC1155721Inventory
    function safeTransferFrom(
        address from,
        address to,
        uint256 nftId
    ) public virtual override {
        _transferFrom(
            from,
            to,
            nftId,
            "",
            /* safe */
            true
        );
    }

    /// @inheritdoc IERC1155721Inventory
    function safeTransferFrom(
        address from,
        address to,
        uint256 nftId,
        bytes memory data
    ) public virtual override {
        _transferFrom(
            from,
            to,
            nftId,
            data,
            /* safe */
            true
        );
    }

    /// @inheritdoc IERC1155721Inventory
    function batchTransferFrom(
        address from,
        address to,
        uint256[] memory nftIds
    ) public virtual override {
        require(to != address(0), "Inventory: transfer to zero");
        address sender = _msgSender();
        bool operatable = _isOperatable(from, sender);

        uint256 length = nftIds.length;
        uint256[] memory values = new uint256[](length);

        uint256 nfCollectionId;
        uint256 nfCollectionCount;
        for (uint256 i; i != length; ++i) {
            uint256 nftId = nftIds[i];
            values[i] = 1;
            _transferNFT(from, to, nftId, 1, operatable, true);
            emit Transfer(from, to, nftId);
            uint256 nextCollectionId = nftId.getNonFungibleCollection(_collectionMaskLength);
            if (nfCollectionId == 0) {
                nfCollectionId = nextCollectionId;
                nfCollectionCount = 1;
            } else {
                if (nextCollectionId != nfCollectionId) {
                    _transferNFTUpdateCollection(from, to, nfCollectionId, nfCollectionCount);
                    nfCollectionId = nextCollectionId;
                    nfCollectionCount = 1;
                } else {
                    ++nfCollectionCount;
                }
            }
        }

        if (nfCollectionId != 0) {
            _transferNFTUpdateCollection(from, to, nfCollectionId, nfCollectionCount);
            _transferNFTUpdateBalances(from, to, length);
        }

        emit TransferBatch(_msgSender(), from, to, nftIds, values);
        if (to.isContract() && _isERC1155TokenReceiver(to)) {
            _callOnERC1155BatchReceived(from, to, nftIds, values, "");
        }
    }

    //======================================================= ERC1155 =======================================================//

    /// @inheritdoc IERC1155721Inventory
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public virtual override(IERC1155Inventory, IERC1155721Inventory) {
        address sender = _msgSender();
        require(to != address(0), "Inventory: transfer to zero");
        bool operatable = _isOperatable(from, sender);

        if (id.isFungibleToken()) {
            _transferFungible(from, to, id, value, operatable);
        } else if (id.isNonFungibleToken(_collectionMaskLength)) {
            _transferNFT(from, to, id, value, operatable, false);
            emit Transfer(from, to, id);
        } else {
            revert("Inventory: not a token id");
        }

        emit TransferSingle(sender, from, to, id, value);
        if (to.isContract()) {
            _callOnERC1155Received(from, to, id, value, data);
        }
    }

    /// @inheritdoc IERC1155721Inventory
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public virtual override(IERC1155Inventory, IERC1155721Inventory) {
        _safeBatchTransferFrom(from, to, ids, values, data);
    }

    //================================================== ERC721 && ERC1155 ==================================================//

    /// @inheritdoc IERC1155721Inventory
    function setApprovalForAll(address operator, bool approved) public virtual override(IERC1155721Inventory, ERC1155InventoryBase) {
        super.setApprovalForAll(operator, approved);
    }

    /// @inheritdoc IERC1155721Inventory
    function isApprovedForAll(address tokenOwner, address operator)
        public
        view
        virtual
        override(IERC1155721Inventory, ERC1155InventoryBase)
        returns (bool)
    {
        return super.isApprovedForAll(tokenOwner, operator);
    }

    //============================================== ERC721 && ERC1155Inventory ===============================================//

    /// @inheritdoc IERC1155721Inventory
    function ownerOf(uint256 nftId) public view virtual override(IERC1155721Inventory, ERC1155InventoryBase) returns (address) {
        return super.ownerOf(nftId);
    }

    //============================================ High-level Internal Functions ============================================//

    /**
     * Safely or unsafely transfers some token (ERC721-compatible).
     * @dev For `safe` transfer, see {IERC1155721Inventory-transferFrom(address,address,uint256)}.
     * @dev For un`safe` transfer, see {IERC1155721Inventory-safeTransferFrom(address,address,uint256,bytes)}.
     */
    function _transferFrom(
        address from,
        address to,
        uint256 nftId,
        bytes memory data,
        bool safe
    ) internal {
        require(to != address(0), "Inventory: transfer to zero");
        address sender = _msgSender();
        bool operatable = _isOperatable(from, sender);

        _transferNFT(from, to, nftId, 1, operatable, false);

        emit Transfer(from, to, nftId);
        emit TransferSingle(sender, from, to, nftId, 1);
        if (to.isContract()) {
            if (_isERC1155TokenReceiver(to)) {
                _callOnERC1155Received(from, to, nftId, 1, data);
            } else if (safe) {
                _callOnERC721Received(from, to, nftId, data);
            }
        }
    }

    /**
     * Safely transfers a batch of tokens (ERC1155-compatible).
     * @dev See {IERC1155721Inventory-safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)}.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal {
        require(to != address(0), "Inventory: transfer to zero");
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
                _transferFungible(from, to, id, values[i], operatable);
            } else if (id.isNonFungibleToken(_collectionMaskLength)) {
                _transferNFT(from, to, id, values[i], operatable, true);
                emit Transfer(from, to, id);
                uint256 nextCollectionId = id.getNonFungibleCollection(_collectionMaskLength);
                if (nfCollectionId == 0) {
                    nfCollectionId = nextCollectionId;
                    nfCollectionCount = 1;
                } else {
                    if (nextCollectionId != nfCollectionId) {
                        _transferNFTUpdateCollection(from, to, nfCollectionId, nfCollectionCount);
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
            _transferNFTUpdateCollection(from, to, nfCollectionId, nfCollectionCount);
            nftsCount += nfCollectionCount;
            _transferNFTUpdateBalances(from, to, nftsCount);
        }

        emit TransferBatch(_msgSender(), from, to, ids, values);
        if (to.isContract()) {
            _callOnERC1155BatchReceived(from, to, ids, values, data);
        }
    }

    /**
     * Safely or unsafely mints some token (ERC721-compatible).
     * @dev For `safe` mint, see {IERC1155721InventoryMintable-mint(address,uint256)}.
     * @dev For un`safe` mint, see {IERC1155721InventoryMintable-safeMint(address,uint256,bytes)}.
     */
    function _mint(
        address to,
        uint256 nftId,
        bytes memory data,
        bool safe
    ) internal {
        require(to != address(0), "Inventory: mint to zero");
        require(nftId.isNonFungibleToken(_collectionMaskLength), "Inventory: not an NFT");

        _mintNFT(to, nftId, 1, false);

        emit Transfer(address(0), to, nftId);
        emit TransferSingle(_msgSender(), address(0), to, nftId, 1);
        if (to.isContract()) {
            if (_isERC1155TokenReceiver(to)) {
                _callOnERC1155Received(address(0), to, nftId, 1, data);
            } else if (safe) {
                _callOnERC721Received(address(0), to, nftId, data);
            }
        }
    }

    /**
     * Unsafely mints a batch of Non-Fungible Tokens (ERC721-compatible).
     * @dev See {IERC1155721InventoryMintable-batchMint(address,uint256[])}.
     */
    function _batchMint(address to, uint256[] memory nftIds) internal {
        require(to != address(0), "Inventory: mint to zero");

        uint256 length = nftIds.length;
        uint256[] memory values = new uint256[](length);

        uint256 nfCollectionId;
        uint256 nfCollectionCount;
        for (uint256 i; i != length; ++i) {
            uint256 nftId = nftIds[i];
            require(nftId.isNonFungibleToken(_collectionMaskLength), "Inventory: not an NFT");
            values[i] = 1;
            _mintNFT(to, nftId, 1, true);
            emit Transfer(address(0), to, nftId);
            uint256 nextCollectionId = nftId.getNonFungibleCollection(_collectionMaskLength);
            if (nfCollectionId == 0) {
                nfCollectionId = nextCollectionId;
                nfCollectionCount = 1;
            } else {
                if (nextCollectionId != nfCollectionId) {
                    _balances[nfCollectionId][to] += nfCollectionCount;
                    _supplies[nfCollectionId] += nfCollectionCount;
                    nfCollectionId = nextCollectionId;
                    nfCollectionCount = 1;
                } else {
                    ++nfCollectionCount;
                }
            }
        }

        _balances[nfCollectionId][to] += nfCollectionCount;
        _supplies[nfCollectionId] += nfCollectionCount;
        _nftBalances[to] += length;

        emit TransferBatch(_msgSender(), address(0), to, nftIds, values);
        if (to.isContract() && _isERC1155TokenReceiver(to)) {
            _callOnERC1155BatchReceived(address(0), to, nftIds, values, "");
        }
    }

    /**
     * Safely mints some token (ERC1155-compatible).
     * @dev See {IERC1155721InventoryMintable-safeMint(address,uint256,uint256,bytes)}.
     */
    function _safeMint(
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "Inventory: mint to zero");
        address sender = _msgSender();
        if (id.isFungibleToken()) {
            _mintFungible(to, id, value);
        } else if (id.isNonFungibleToken(_collectionMaskLength)) {
            _mintNFT(to, id, value, false);
            emit Transfer(address(0), to, id);
        } else {
            revert("Inventory: not a token id");
        }

        emit TransferSingle(sender, address(0), to, id, value);
        if (to.isContract()) {
            _callOnERC1155Received(address(0), to, id, value, data);
        }
    }

    /**
     * Safely mints a batch of tokens (ERC1155-compatible).
     * @dev See {IERC1155721InventoryMintable-safeBatchMint(address,uint256[],uint256[],bytes)}.
     */
    function _safeBatchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "Inventory: mint to zero");
        uint256 length = ids.length;
        require(length == values.length, "Inventory: inconsistent arrays");

        uint256 nfCollectionId;
        uint256 nfCollectionCount;
        uint256 nftsCount;
        for (uint256 i; i != length; ++i) {
            uint256 id = ids[i];
            uint256 value = values[i];
            if (id.isFungibleToken()) {
                _mintFungible(to, id, value);
            } else if (id.isNonFungibleToken(_collectionMaskLength)) {
                _mintNFT(to, id, value, true);
                emit Transfer(address(0), to, id);
                uint256 nextCollectionId = id.getNonFungibleCollection(_collectionMaskLength);
                if (nfCollectionId == 0) {
                    nfCollectionId = nextCollectionId;
                    nfCollectionCount = 1;
                } else {
                    if (nextCollectionId != nfCollectionId) {
                        _balances[nfCollectionId][to] += nfCollectionCount;
                        _supplies[nfCollectionId] += nfCollectionCount;
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
            _balances[nfCollectionId][to] += nfCollectionCount;
            _supplies[nfCollectionId] += nfCollectionCount;
            nftsCount += nfCollectionCount;
            _nftBalances[to] += nftsCount;
        }

        emit TransferBatch(_msgSender(), address(0), to, ids, values);
        if (to.isContract()) {
            _callOnERC1155BatchReceived(address(0), to, ids, values, data);
        }
    }

    /**
     * Safely mints some tokens to a list of recipients.
     * @dev See {IERC1155721Deliverable-safeDeliver(address[],uint256[],uint256[],bytes)}.
     */
    function _safeDeliver(
        address[] calldata recipients,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) internal {
        uint256 length = recipients.length;
        require(length == ids.length && length == values.length, "Inventory: inconsistent arrays");

        address sender = _msgSender();
        for (uint256 i; i != length; ++i) {
            address to = recipients[i];
            require(to != address(0), "Inventory: mint to zero");
            uint256 id = ids[i];
            uint256 value = values[i];
            if (id.isFungibleToken()) {
                _mintFungible(to, id, value);
                emit TransferSingle(sender, address(0), to, id, value);
                if (to.isContract()) {
                    _callOnERC1155Received(address(0), to, id, value, data);
                }
            } else if (id.isNonFungibleToken(_collectionMaskLength)) {
                _mintNFT(to, id, value, false);
                emit Transfer(address(0), to, id);
                emit TransferSingle(sender, address(0), to, id, 1);
                if (to.isContract()) {
                    if (_isERC1155TokenReceiver(to)) {
                        _callOnERC1155Received(address(0), to, id, 1, data);
                    } else {
                        _callOnERC721Received(address(0), to, id, data);
                    }
                }
            } else {
                revert("Inventory: not a token id");
            }
        }
    }

    //============================================== Helper Internal Functions ==============================================//

    function _mintFungible(
        address to,
        uint256 id,
        uint256 value
    ) internal {
        require(value != 0, "Inventory: zero value");
        uint256 supply = _supplies[id];
        uint256 newSupply = supply + value;
        require(newSupply > supply, "Inventory: supply overflow");
        _supplies[id] = newSupply;
        // cannot overflow as supply cannot overflow
        _balances[id][to] += value;
    }

    function _mintNFT(
        address to,
        uint256 id,
        uint256 value,
        bool isBatch
    ) internal {
        require(value == 1, "Inventory: wrong NFT value");
        require(_owners[id] == 0, "Inventory: existing/burnt NFT");

        _owners[id] = uint256(uint160(to));

        if (!isBatch) {
            uint256 collectionId = id.getNonFungibleCollection(_collectionMaskLength);
            // it is virtually impossible that a Non-Fungible Collection supply
            // overflows due to the cost of minting individual tokens
            ++_supplies[collectionId];
            ++_balances[collectionId][to];
            ++_nftBalances[to];
        }
    }

    function _transferFungible(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bool operatable
    ) internal {
        require(operatable, "Inventory: non-approved sender");
        require(value != 0, "Inventory: zero value");
        uint256 balance = _balances[id][from];
        require(balance >= value, "Inventory: not enough balance");
        if (from != to) {
            _balances[id][from] = balance - value;
            // cannot overflow as supply cannot overflow
            _balances[id][to] += value;
        }
    }

    function _transferNFT(
        address from,
        address to,
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
        _owners[id] = uint256(uint160(to));
        if (!isBatch) {
            _transferNFTUpdateBalances(from, to, 1);
            _transferNFTUpdateCollection(from, to, id.getNonFungibleCollection(_collectionMaskLength), 1);
        }
    }

    function _transferNFTUpdateBalances(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (from != to) {
            // cannot underflow as balance is verified through ownership
            _nftBalances[from] -= amount;
            //  cannot overflow as supply cannot overflow
            _nftBalances[to] += amount;
        }
    }

    function _transferNFTUpdateCollection(
        address from,
        address to,
        uint256 collectionId,
        uint256 amount
    ) internal virtual {
        if (from != to) {
            // cannot underflow as balance is verified through ownership
            _balances[collectionId][from] -= amount;
            // cannot overflow as supply cannot overflow
            _balances[collectionId][to] += amount;
        }
    }

    /**
     * Queries whether a contract implements ERC1155TokenReceiver.
     * @param _contract address of the contract.
     * @return wheter the given contract implements ERC1155TokenReceiver.
     */
    function _isERC1155TokenReceiver(address _contract) internal view returns (bool) {
        bool success;
        bool result;
        bytes memory staticCallData = abi.encodeWithSelector(type(IERC165).interfaceId, type(IERC1155TokenReceiver).interfaceId);
        assembly {
            let call_ptr := add(0x20, staticCallData)
            let call_size := mload(staticCallData)
            let output := mload(0x40) // Find empty storage location using "free memory pointer"
            mstore(output, 0x0)
            success := staticcall(10000, _contract, call_ptr, call_size, output, 0x20) // 32 bytes
            result := mload(output)
        }
        // (10000 / 63) "not enough for supportsInterface(...)" // consume all gas, so caller can potentially know that there was not enough gas
        assert(gasleft() > 158);
        return success && result;
    }

    /**
     * Calls {IERC721Receiver-onERC721Received} on a target contract.
     * @dev Reverts if `to` is not a contract.
     * @dev Reverts if the call to the target fails or is refused.
     * @param from Previous token owner.
     * @param to New token owner.
     * @param nftId Identifier of the token transferred.
     * @param data Optional data to send along with the receiver contract call.
     */
    function _callOnERC721Received(
        address from,
        address to,
        uint256 nftId,
        bytes memory data
    ) internal {
        require(
            IERC721Receiver(to).onERC721Received(_msgSender(), from, nftId, data) == type(IERC721Receiver).interfaceId,
            "Inventory: transfer refused"
        );
    }
}
