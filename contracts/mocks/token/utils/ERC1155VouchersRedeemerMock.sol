// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IERC1155InventoryBurnable, IWrappedERC20, ERC1155VouchersRedeemer} from "../../../token/utils/ERC1155VouchersRedeemer.sol";

contract ERC1155VouchersRedeemerMock is ERC1155VouchersRedeemer {
    constructor(
        IERC1155InventoryBurnable vouchersContract,
        IWrappedERC20 tokenContract,
        address tokenHolder
    ) ERC1155VouchersRedeemer(vouchersContract, tokenContract, tokenHolder) {}

    function _voucherValue(uint256 tokenId) internal pure override returns (uint256) {
        return tokenId;
    }
}
