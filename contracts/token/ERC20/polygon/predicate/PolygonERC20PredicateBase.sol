// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {IPolygonTokenPredicate} from "../../../common/polygon/interfaces/IPolygonTokenPredicate.sol";
import {RLPReader} from "@animoca/ethereum-contracts-core/contracts/utils/RLPReader.sol";

/**
 * @title ERC20 Predicate Base (for Polygon).
 * Polygon bridging ERC20 predicate which works with a `Withdrawn(address account, uint256 value)` event.
 * @dev This contract should be deployed on the Root Chain (Ethereum).
 * @dev The functions `lockTokens(address,address,address,bytes)` and `exitTokens(address,address,byte)` need to be implemented by a child contract.
 */
abstract contract PolygonERC20PredicateBase is IPolygonTokenPredicate {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    event LockedERC20(address indexed depositor, address indexed depositReceiver, address indexed rootToken, uint256 amount);

    // keccak256("Withdrawn(address account, uint256 value)");
    bytes32 public constant WITHDRAWN_EVENT_SIG = 0x7084f5476618d8e60b11ef0d7d3f06914655adb8793e28ff7f018d4c76d505d5;

    // see https://github.com/maticnetwork/pos-portal/blob/master/contracts/root/RootChainManager/RootChainManager.sol
    address public rootChainManager;

    /**
     * Constructor
     * @param rootChainManager_ the Polygon/MATIC RootChainManager proxy address.
     */
    constructor(address rootChainManager_) {
        rootChainManager = rootChainManager_;
    }

    //============================================== Helper Internal Functions ==============================================//

    function _requireManagerRole(address account) internal view {
        require(account == rootChainManager, "Predicate: only manager");
    }

    function _verifyWithdrawalLog(bytes memory log) internal pure returns (address withdrawer, uint256 amount) {
        RLPReader.RLPItem[] memory logRLPList = log.toRlpItem().toList();
        RLPReader.RLPItem[] memory logTopicRLPList = logRLPList[1].toList(); // topics

        require(
            bytes32(logTopicRLPList[0].toUint()) == WITHDRAWN_EVENT_SIG, // topic0 is event sig
            "Predicate: invalid signature"
        );

        bytes memory logData = logRLPList[2].toBytes();
        (withdrawer, amount) = abi.decode(logData, (address, uint256));
    }
}
