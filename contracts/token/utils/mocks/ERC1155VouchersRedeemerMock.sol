// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IWrappedERC20} from "@animoca/ethereum-contracts-core/contracts/utils/ERC20Wrapper.sol";
import {IERC1155InventoryBurnable} from "./../../../token/ERC1155/interfaces/IERC1155InventoryBurnable.sol";
import {ERC1155VouchersRedeemer} from "./../ERC1155VouchersRedeemer.sol";

contract ERC1155VouchersRedeemerMock is ERC1155VouchersRedeemer {
    constructor(
        IERC1155InventoryBurnable vouchers,
        IWrappedERC20 deliverable,
        address tokenHolder
    ) ERC1155VouchersRedeemer(vouchers, deliverable, tokenHolder) {}

    function _voucherValue(uint256 tokenId) internal pure override returns (uint256) {
        return tokenId;
    }
}
