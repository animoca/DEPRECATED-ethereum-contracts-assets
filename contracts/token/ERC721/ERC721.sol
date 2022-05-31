// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {AddressIsContract} from "@animoca/ethereum-contracts-core/contracts/utils/types/AddressIsContract.sol";
import {IERC165} from "@animoca/ethereum-contracts-core/contracts/introspection/IERC165.sol";
import {IERC721} from "./interfaces/IERC721.sol";
import {IERC721Metadata} from "./interfaces/IERC721Metadata.sol";
import {IERC721BatchTransfer} from "./interfaces/IERC721BatchTransfer.sol";
import {IERC721Receiver} from "./interfaces/IERC721Receiver.sol";
import {ManagedIdentity} from "@animoca/ethereum-contracts-core/contracts/metatx/ManagedIdentity.sol";
import {ERC721Simple} from "./ERC721Simple.sol";

/**
 * @title ERC721 Non Fungible Token Contract.
 * @dev The function `tokenURI(uint256)` needs to be implemented by a child contract, for example with the help of `NFTBaseMetadataURI`.
 */
abstract contract ERC721 is ERC721Simple, IERC721Metadata, IERC721BatchTransfer {
    using AddressIsContract for address;

    string internal _name;
    string internal _symbol;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    // todo
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721BatchTransfer).interfaceId;
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

    //================================================= ERC721BatchTransfer =================================================//

    /// @inheritdoc IERC721BatchTransfer
    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIds
    ) public virtual override {
        require(to != address(0), "ERC721: transfer to zero");
        address sender = _msgSender();
        bool operatable = _isOperatable(from, sender);

        uint256 length = tokenIds.length;

        for (uint256 i; i != length; ++i) {
            uint256 tokenId = tokenIds[i];
            uint256 owner = _owners[tokenId];
            require(from == address(uint160(owner)), "ERC721: non-owned NFT");
            if (!operatable) {
                require((owner & _APPROVAL_BIT_TOKEN_OWNER_ != 0) && sender == _approvals[tokenId], "ERC721: non-approved sender");
            }
            _owners[tokenId] = uint256(uint160(to));
            emit Transfer(from, to, tokenId);
        }

        if (length != 0 && from != to) {
            // cannot underflow as balance is verified through ownership
            _balances[from] -= length;
            // cannot overflow due to the cost of minting individual tokens
            _balances[to] += length;
        }
    }

    //============================================ High-level Internal Functions ============================================//

    function _batchMint(address to, uint256[] calldata tokenIds) internal {
        require(to != address(0), "ERC721: mint to zero");

        uint256 length = tokenIds.length;
        for (uint256 i; i != length; ++i) {
            uint256 tokenId = tokenIds[i];
            _requireMintable(tokenId);
            _owners[tokenId] = uint256(uint160(to));
            emit Transfer(address(0), to, tokenId);
        }

        // cannot overflow due to the cost of minting individual tokens
        if (length != 0) {
            _balances[to] += length;
        }
    }
}
