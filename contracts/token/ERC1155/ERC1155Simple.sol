// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {AddressIsContract} from "@animoca/ethereum-contracts-core/contracts/utils/types/AddressIsContract.sol";
import {IERC165} from "@animoca/ethereum-contracts-core/contracts/introspection/IERC165.sol";
import {IERC1155} from "./interfaces/IERC1155.sol";
import {IERC1155TokenReceiver} from "./interfaces/IERC1155TokenReceiver.sol";
import {ManagedIdentity} from "@animoca/ethereum-contracts-core/contracts/metatx/ManagedIdentity.sol";

/**
 * @title ERC1155 ERC1155 Base.
 * @dev The functions `safeTransferFrom(address,address,uint256,uint256,bytes)`
 *  and `safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)` need to be implemented by a child contract.
 * @dev The function `uri(uint256)` needs to be implemented by a child contract, for example with the help of `NFTBaseMetadataURI`.
 */
contract ERC1155Simple is ManagedIdentity, IERC165, IERC1155 {
    using AddressIsContract for address;

    /* owner => operator => approved */
    mapping(address => mapping(address => bool)) internal _operators;

    /* ID => owner => balance */
    mapping(uint256 => mapping(address => uint256)) internal _balances;

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC1155).interfaceId;
    }

    //======================================================= ERC1155 =======================================================//

    /// @inheritdoc IERC1155
    function balanceOf(address owner, uint256 id) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC1155: zero address");

        return _balances[id][owner];
    }

    /// @inheritdoc IERC1155
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view virtual override returns (uint256[] memory) {
        require(owners.length == ids.length, "ERC1155: inconsistent arrays");

        uint256[] memory balances = new uint256[](owners.length);

        for (uint256 i = 0; i != owners.length; ++i) {
            balances[i] = balanceOf(owners[i], ids[i]);
        }

        return balances;
    }

    /// @inheritdoc IERC1155
    function setApprovalForAll(address operator, bool approved) public virtual override {
        address sender = _msgSender();
        require(operator != sender, "ERC1155: self-approval");
        _operators[sender][operator] = approved;
        emit ApprovalForAll(sender, operator, approved);
    }

    /// @inheritdoc IERC1155
    function isApprovedForAll(address tokenOwner, address operator) public view virtual override returns (bool) {
        return _operators[tokenOwner][operator];
    }

    /// @inheritdoc IERC1155
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external virtual override {
        address operator = _msgSender();
        _transferFrom(operator, from, to, id, value);

        if (to.isContract()) {
            require(
                IERC1155TokenReceiver(to).onERC1155Received(operator, from, id, value, data) == IERC1155TokenReceiver.onERC1155Received.selector,
                "ERC1155: transfer refused"
            );
        }
    }

    /// @inheritdoc IERC1155
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external virtual override {
        address operator = _msgSender();
        _batchTransferFrom(operator, from, to, ids, values);

        if (to.isContract()) {
            require(
                IERC1155TokenReceiver(to).onERC1155BatchReceived(operator, from, ids, values, data) ==
                    IERC1155TokenReceiver.onERC1155BatchReceived.selector,
                "ERC1155: transfer refused"
            );
        }
    }

    //============================================ High-level Internal Functions ============================================//

    function _safeMint(
        address operator,
        address to,
        uint256 id,
        uint256 value
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to zero");

        _mintToken(to, id, value);

        emit TransferSingle(operator, address(0), to, id, value);

        if (to.isContract()) {
            require(
                IERC1155TokenReceiver(to).onERC1155Received(operator, address(0), id, value, "") == IERC1155TokenReceiver.onERC1155Received.selector,
                "ERC1155: transfer refused"
            );
        }
    }

    function _safeMint(
        address operator,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to zero");

        _mintToken(to, id, value);

        emit TransferSingle(operator, address(0), to, id, value);

        if (to.isContract()) {
            require(
                IERC1155TokenReceiver(to).onERC1155Received(operator, address(0), id, value, data) == IERC1155TokenReceiver.onERC1155Received.selector,
                "ERC1155: transfer refused"
            );
        }
    }

    function _safeBatchMint(
        address operator,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to zero");
        require(ids.length == values.length, "ERC1155: inconsistent arrays");

        for (uint256 i; i != ids.length; ++i) {
            _mintToken(to, ids[i], values[i]);
        }

        emit TransferBatch(operator, address(0), to, ids, values);

        if (to.isContract()) {
            require(
                IERC1155TokenReceiver(to).onERC1155BatchReceived(operator, address(0), ids, values, "") ==
                    IERC1155TokenReceiver.onERC1155BatchReceived.selector,
                "ERC1155: transfer refused"
            );
        }
    }

    function _safeBatchMint(
        address operator,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to zero");
        require(ids.length == values.length, "ERC1155: inconsistent arrays");

        for (uint256 i; i != ids.length; ++i) {
            _mintToken(to, ids[i], values[i]);
        }

        emit TransferBatch(operator, address(0), to, ids, values);

        if (to.isContract()) {
            require(
                IERC1155TokenReceiver(to).onERC1155BatchReceived(operator, address(0), ids, values, data) ==
                    IERC1155TokenReceiver.onERC1155BatchReceived.selector,
                "ERC1155: transfer refused"
            );
        }
    }

    function _burn(
        address operator,
        address from,
        uint256 id,
        uint256 value
    ) public virtual {
        _burnToken(from, id, value);
        emit TransferSingle(operator, from, address(0), id, value);
    }

    function _burnFrom(
        address from,
        uint256 id,
        uint256 value
    ) public virtual {
        address operator = _msgSender();
        require(_isOperatable(from, operator), "ERC1155: non-approved sender");
        _burn(operator, from, id, value);
    }

    function _batchBurn(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values
    ) public virtual {
        require(ids.length == values.length, "ERC1155: inconsistent arrays");

        for (uint256 i; i != ids.length; ++i) {
            _burnToken(from, ids[i], values[i]);
        }

        emit TransferBatch(operator, from, address(0), ids, values);
    }

    function _batchBurnFrom(
        address from,
        uint256[] calldata ids,
        uint256[] calldata values
    ) public virtual {
        address operator = _msgSender();
        require(_isOperatable(from, operator), "ERC1155: non-approved sender");
        _batchBurn(operator, from, ids, values);
    }

    //============================================== Helper Internal Functions ==============================================//

    function _transferFrom(address operator, address from, address to, uint256 id, uint256 value) internal virtual {
        require(to != address(0), "ERC1155: transfer to zero");
        require(_isOperatable(from, operator), "ERC1155: non-approved sender");

        _transferToken(from, to, id, value);

        emit TransferSingle(operator, from, to, id, value);
    }

    function _batchTransferFrom(address operator, address from, address to, uint256[] calldata ids, uint256[] calldata values) internal virtual {
        require(to != address(0), "ERC1155: transfer to zero");
        require(ids.length == values.length, "ERC1155: inconsistent arrays");

        require(_isOperatable(from, operator), "ERC1155: non-approved sender");

        for (uint256 i; i != ids.length; ++i) {
            _transferToken(from, to, ids[i], values[i]);
        }

        emit TransferBatch(operator, from, to, ids, values);
    }

    /**
     * Returns whether `sender` is authorised to make a transfer on behalf of `from`.
     * @param from The address to check operatibility upon.
     * @param sender The sender address.
     * @return True if sender is `from` or an operator for `from`, false otherwise.
     */
    function _isOperatable(address from, address sender) internal view virtual returns (bool) {
        return (from == sender) || _operators[from][sender];
    }

    function _transferToken(
        address from,
        address to,
        uint256 id,
        uint256 value
    ) internal virtual {
        require(value != 0, "ERC1155: zero value");
        uint256 fromBalance = _balances[id][from];
        uint256 newFromBalance = fromBalance - value;
        require(newFromBalance < fromBalance, "ERC1155: not enough balance");
        if (from != to) {
            uint256 toBalance = _balances[id][to];
            uint256 newToBalance = toBalance + value;
            require(newToBalance > toBalance, "ERC1155: balance overflow");

            _balances[id][from] = newFromBalance;
            _balances[id][to] += newToBalance;
        }
    }

    function _mintToken(
        address to,
        uint256 id,
        uint256 value
    ) internal virtual {
        require(value != 0, "ERC1155: zero value");
        uint256 balance = _balances[id][to];
        uint256 newBalance = balance + value;
        require(newBalance > balance, "ERC1155: balance overflow");
        _balances[id][to] = newBalance;
    }

    function _burnToken(
        address from,
        uint256 id,
        uint256 value
    ) internal virtual {
        require(value != 0, "ERC1155: zero value");
        uint256 balance = _balances[id][from];
        uint256 newBalance = balance - value;
        require(newBalance < balance, "ERC1155: not enough balance");
        _balances[id][from] = newBalance;
    }
}
