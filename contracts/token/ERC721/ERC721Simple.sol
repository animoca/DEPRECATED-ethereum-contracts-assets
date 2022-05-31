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

    uint256 internal constant _APPROVAL_BIT_TOKEN_OWNER_ = 1 << 160;

    /* owner => operator => approved */
    mapping(address => mapping(address => bool)) internal _operators;

    /* tokenId => owner */
    mapping(uint256 => uint256) internal _owners;

    /* owner => balance */
    mapping(address => uint256) internal _balances;

    /* tokenId => operator */
    mapping(uint256 => address) internal _approvals;

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC721).interfaceId;
    }

    //======================================================= ERC721 ========================================================//

    /// @inheritdoc IERC721
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: zero address");
        return _balances[owner];
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
            _approvals[tokenId] = to;
        }
        emit Approval(ownerAddress, to, tokenId);
    }

    /// @inheritdoc IERC721
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        uint256 owner = _owners[tokenId];
        require(address(uint160(owner)) != address(0), "ERC721: non-existing NFT");
        if (owner & _APPROVAL_BIT_TOKEN_OWNER_ != 0) {
            return _approvals[tokenId];
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
        _transferFrom(_msgSender(), from, to, tokenId);
    }

    /// @inheritdoc IERC721
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        address operator = _msgSender();
        _transferFrom(operator, from, to, tokenId);
        if (to.isContract()) {
            require(
                IERC721Receiver(to).onERC721Received(operator, from, tokenId, "") == IERC721Receiver.onERC721Received.selector,
                "ERC721: transfer refused"
            );
        }
    }

    /// @inheritdoc IERC721
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) public virtual override {
        address operator = _msgSender();
        _transferFrom(operator, from, to, tokenId);
        if (to.isContract()) {
            require(
                IERC721Receiver(to).onERC721Received(operator, from, tokenId, data) == IERC721Receiver.onERC721Received.selector,
                "ERC721: transfer refused"
            );
        }
    }

    //============================================ High-level Internal Functions ============================================//

    function _transferFrom(
        address operator,
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(to != address(0), "ERC721: transfer to zero");

        uint256 owner = _owners[tokenId];
        if (!_isOperatable(from, operator)) {
            require((owner & _APPROVAL_BIT_TOKEN_OWNER_ != 0) && operator == _approvals[tokenId], "ERC721: non-approved sender");
        }

        require(from == address(uint160(owner)), "ERC721: non-owned NFT");

        if (from != to) {
            _owners[tokenId] = uint256(uint160(to));
            // cannot underflow as balance is verified through ownership
            --_balances[from];
            // cannot overflow due to the cost of minting individual tokens
            ++_balances[to];
        } else if (owner & _APPROVAL_BIT_TOKEN_OWNER_ != 0) {
            // reset the approval
            _owners[tokenId] = uint256(uint160(to));
        }

        emit Transfer(from, to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to zero");
        _requireMintable(tokenId);
        _owners[tokenId] = uint256(uint160(to));

        // cannot overflow due to the cost of minting individual tokens
        ++_balances[to];

        emit Transfer(address(0), to, tokenId);
    }

    function _safeMint(
        address operator,
        address to,
        uint256 tokenId
    ) internal virtual {
        _mint(to, tokenId);
        if (to.isContract()) {
            require(
                IERC721Receiver(to).onERC721Received(operator, address(0), tokenId, "") == IERC721Receiver.onERC721Received.selector,
                "ERC721: transfer refused"
            );
        }
    }

    function _safeMint(
        address operator,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) internal virtual {
        _mint(to, tokenId);
        if (to.isContract()) {
            require(
                IERC721Receiver(to).onERC721Received(operator, address(0), tokenId, data) == IERC721Receiver.onERC721Received.selector,
                "ERC721: transfer refused"
            );
        }
    }

    function _burnFrom(address from, uint256 tokenId) internal virtual {
        uint256 owner = _owners[tokenId];
        address operator = _msgSender();
        if (!_isOperatable(from, operator)) {
            require((owner & _APPROVAL_BIT_TOKEN_OWNER_ != 0) && operator == _approvals[tokenId], "ERC721: non-approved sender");
        }

        _burnToken(address(uint160(owner)), from, tokenId);
    }

    //============================================== Internal Helper Functions ==============================================//

    /**
     * Returns whether `sender` is authorised to make a transfer on behalf of `from`.
     * @param from The address to check operatibility upon.
     * @param sender The sender address.
     * @return True if sender is `from` or an operator for `from`, false otherwise.
     */
    function _isOperatable(address from, address sender) internal view virtual returns (bool) {
        return (from == sender) || _operators[from][sender];
    }

    function _burnToken(
        address owner,
        address from,
        uint256 tokenId
    ) internal virtual {
        require(from == owner, "ERC721: non-owned NFT");
        _setBurntTokenOwner(tokenId);

        // cannot underflow as balance is verified through NFT ownership
        --_balances[from];

        emit Transfer(from, address(0), tokenId);
    }

    function _requireMintable(uint256 tokenId) internal virtual {
        require(_owners[tokenId] == 0, "ERC721: existing NFT");
    }

    function _setBurntTokenOwner(uint256 tokenId) internal virtual {
        _owners[tokenId] = 0;
    }
}
