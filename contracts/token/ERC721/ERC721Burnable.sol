// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IERC165} from "@animoca/ethereum-contracts-core/contracts/introspection/IERC165.sol";
import {IERC721} from "./interfaces/IERC721.sol";
import {IERC721Metadata} from "./interfaces/IERC721Metadata.sol";
import {IERC721BatchTransfer} from "./interfaces/IERC721BatchTransfer.sol";
import {IERC721Burnable} from "./interfaces/IERC721Burnable.sol";
import {ERC721} from "./ERC721.sol";

/**
 * @title ERC721 Non Fungible Token Contract, burnable version.
 * @dev The function `tokenURI(uin256)` needs to be implemented by a child contract, for example with the help of `NFTBaseMetadataURI`.
 */
abstract contract ERC721Burnable is IERC721Burnable, ERC721 {
    // Burnt Non-Fungible Token owner's magic value
    uint256 internal constant _BURNT_NFT_OWNER = 0xdead000000000000000000000000000000000000000000000000000000000000;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721BatchTransfer).interfaceId ||
            interfaceId == type(IERC721Burnable).interfaceId;
    }

    //=================================================== ERC721Burnable ====================================================//

    /// @inheritdoc IERC721Burnable
    function burnFrom(address from, uint256 tokenId) public virtual override {
        _burnFrom(from, tokenId);
    }

    /// @inheritdoc IERC721Burnable
    function batchBurnFrom(address from, uint256[] calldata tokenIds) public virtual override {
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

           _setBurntTokenOwner(tokenId);

            emit Transfer(from, address(0), tokenId);
        }

        if (length != 0) {
            // cannot underflow as balance is verified through ownership
            _balances[from] -= length;
        }
    }

    //============================================== Helper Internal Functions ==============================================//

    function _setBurntTokenOwner(uint256 tokenId) internal virtual override {
        // Burnt Non-Fungible Token owner's magic value to make burnt tokens non-mintable
        _owners[tokenId] = _BURNT_NFT_OWNER;
    }

    function _requireMintable(uint256 tokenId) internal virtual override {
        uint256 owner = _owners[tokenId];
        require(owner != _BURNT_NFT_OWNER, "ERC721: burnt NFT");
        require(owner == 0, "ERC721: existing NFT");
    }
}
