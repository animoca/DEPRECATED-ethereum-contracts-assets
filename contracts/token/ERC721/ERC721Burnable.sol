// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IERC165} from "@animoca/ethereum-contracts-core/contracts/introspection/IERC165.sol";
import {IERC721Burnable} from "./interfaces/IERC721Burnable.sol";
import {ERC721} from "./ERC721.sol";

/**
 * @title ERC721 Non Fungible Token Contract, burnable version.
 * @dev The function `tokenURI(uin256)` needs to be implemented by a child contract, for example with the help of `NFTBaseMetadataURI`.
 */
abstract contract ERC721Burnable is IERC721Burnable, ERC721 {
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC721Burnable).interfaceId || super.supportsInterface(interfaceId);
    }

    //=================================================== ERC721Burnable ====================================================//

    /// @inheritdoc IERC721Burnable
    function burnFrom(address from, uint256 tokenId) public virtual override {
        address sender = _msgSender();
        bool operatable = _isOperatable(from, sender);

        _burnNFT(from, tokenId, operatable, false);
        emit Transfer(from, address(0), tokenId);
    }

    /// @inheritdoc IERC721Burnable
    function batchBurnFrom(address from, uint256[] memory tokenIds) public virtual override {
        address sender = _msgSender();
        bool operatable = _isOperatable(from, sender);

        uint256 length = tokenIds.length;

        for (uint256 i; i != length; ++i) {
            uint256 tokenId = tokenIds[i];
            _burnNFT(from, tokenId, operatable, true);
            emit Transfer(from, address(0), tokenId);
        }

        if (length != 0) {
            _nftBalances[from] -= length;
        }
    }

    //============================================== Helper Internal Functions ==============================================//

    function _burnNFT(
        address from,
        uint256 id,
        bool operatable,
        bool isBatch
    ) internal virtual {
        uint256 owner = _owners[id];
        require(from == address(uint160(owner)), "ERC721: non-owned NFT");
        if (!operatable) {
            require((owner & _APPROVAL_BIT_TOKEN_OWNER_ != 0) && _msgSender() == _nftApprovals[id], "ERC721: non-approved sender");
        }
        _owners[id] = _BURNT_NFT_OWNER;

        if (!isBatch) {
            // cannot underflow as balance is verified through NFT ownership
            --_nftBalances[from];
        }
    }
}
