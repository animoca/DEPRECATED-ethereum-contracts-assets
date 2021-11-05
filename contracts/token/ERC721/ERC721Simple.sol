// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {AddressIsContract} from "@animoca/ethereum-contracts-core/contracts/utils/types/AddressIsContract.sol";
import {IERC165} from "@animoca/ethereum-contracts-core/contracts/introspection/IERC165.sol";
import {IERC721} from "./interfaces/IERC721.sol";
import {IERC721Events} from "./interfaces/IERC721Events.sol";
import {IERC721Receiver} from "./interfaces/IERC721Receiver.sol";
import {ManagedIdentity} from "@animoca/ethereum-contracts-core/contracts/metatx/ManagedIdentity.sol";

/**
 * @title ERC721 Non Fungible Token Contract, simple implementation.
 */
contract ERC721Simple is ManagedIdentity, IERC165, IERC721, IERC721Events {
    using AddressIsContract for address;

    bytes4 internal constant _ERC721_RECEIVED = type(IERC721Receiver).interfaceId;

    uint256 internal constant _APPROVAL_BIT_TOKEN_OWNER_ = 1 << 160;

    /* owner => operator => approved */
    mapping(address => mapping(address => bool)) internal _operators;

    /* NFT ID => owner */
    mapping(uint256 => uint256) internal _owners;

    /* owner => NFT balance */
    mapping(address => uint256) internal _nftBalances;

    /* NFT ID => operator */
    mapping(uint256 => address) internal _nftApprovals;

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC721).interfaceId;
    }

    //======================================================= ERC721 ========================================================//

    /// @inheritdoc IERC721
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: zero address");
        return _nftBalances[owner];
    }

    /// @inheritdoc IERC721
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = address(uint160(_owners[tokenId]));
        require(owner != address(0), "ERC721: non-existing NFT");
        return owner;
    }

    /// @inheritdoc IERC721
    function approve(address to, uint256 tokenId) public virtual override {
        uint256 owner = _owners[tokenId];
        require(owner != 0, "ERC721: non-existing NFT");
        address ownerAddress = address(uint160(owner));
        require(to != ownerAddress, "ERC721: self-approval");
        require(_isOperatable(ownerAddress, _msgSender()), "ERC721: non-approved sender");
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
        require(address(uint160(owner)) != address(0), "ERC721: non-existing NFT");
        if (owner & _APPROVAL_BIT_TOKEN_OWNER_ != 0) {
            return _nftApprovals[tokenId];
        } else {
            return address(0);
        }
    }

    /// @inheritdoc IERC721
    function setApprovalForAll(address operator, bool approved) public virtual override {
        address sender = _msgSender();
        require(operator != sender, "ERC721: self-approval");
        _operators[sender][operator] = approved;
        emit ApprovalForAll(sender, operator, approved);
    }

    /// @inheritdoc IERC721
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operators[owner][operator];
    }

    /// @inheritdoc IERC721
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transferFrom(
            from,
            to,
            tokenId,
            "",
            /* safe */
            false
        );
    }

    /// @inheritdoc IERC721
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transferFrom(
            from,
            to,
            tokenId,
            "",
            /* safe */
            true
        );
    }

    /// @inheritdoc IERC721
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        _transferFrom(
            from,
            to,
            tokenId,
            data,
            /* safe */
            true
        );
    }

    //============================================ High-level Internal Functions ============================================//

    function _transferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data,
        bool safe
    ) internal virtual {
        require(to != address(0), "ERC721: transfer to zero");
        address sender = _msgSender();
        bool operatable = _isOperatable(from, sender);

        uint256 owner = _owners[tokenId];
        require(from == address(uint160(owner)), "ERC721: non-owned NFT");
        if (!operatable) {
            require((owner & _APPROVAL_BIT_TOKEN_OWNER_ != 0) && _msgSender() == _nftApprovals[tokenId], "ERC721: non-approved sender");
        }
        _owners[tokenId] = uint256(uint160(to));

        if (from != to) {
            // cannot underflow as balance is verified through ownership
            --_nftBalances[from];
            //  cannot overflow as supply cannot overflow
            ++_nftBalances[to];
        }

        emit Transfer(from, to, tokenId);

        if (safe && to.isContract()) {
            require(IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) == _ERC721_RECEIVED, "ERC721: transfer refused");
        }
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to zero");
        require(_owners[tokenId] == 0, "ERC721: existing NFT");

        _owners[tokenId] = uint256(uint160(to));

        // cannot overflow due to the cost of minting individual tokens
        ++_nftBalances[to];

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = address(uint160(_owners[tokenId]));

        require(owner != address(0), "ERC721: non-existing NFT");

        _owners[tokenId] = 0;

        // cannot underflow as balance is verified through NFT ownership
        --_nftBalances[owner];

        emit Transfer(owner, address(0), tokenId);
    }

    //============================================== Internal Helper Functions ==============================================//

    /**
     * Returns whether `sender` is authorised to make a transfer on behalf of `from`.
     * @param from The address to check operatibility upon.
     * @param sender The sender address.
     * @return True if sender is `from` or an operator for `from`, false otherwise.
     */
    function _isOperatable(address from, address sender) internal view returns (bool) {
        return (from == sender) || _operators[from][sender];
    }
}
