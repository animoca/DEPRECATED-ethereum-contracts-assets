// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

import {Ownable} from "@animoca/ethereum-contracts-core-1.0.1/contracts/access/Ownable.sol";
import {ITokenPredicate} from "@animoca/ethereum-contracts-core-1.0.1/contracts/bridging/ITokenPredicate.sol";
import {RLPReader} from "@animoca/ethereum-contracts-core-1.0.1/contracts/utils/RLPReader.sol";

abstract contract ERC20BasePredicate is ITokenPredicate, Ownable {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    event LockedERC20(address indexed depositor, address indexed depositReceiver, address indexed rootToken, uint256 amount);

    bytes32 public constant WITHDRAWN_EVENT_SIG = 0x7084f5476618d8e60b11ef0d7d3f06914655adb8793e28ff7f018d4c76d505d5;

    address public manager;

    function setManager(address rootChainManager) external {
        _requireOwnership(_msgSender());
        manager = rootChainManager;
    }

    function _requireManagerRole(address account) internal view {
        require(account == manager, "Predicate: only manager");
    }

    function _verifyWithdrawalLog(bytes memory log) internal pure returns (address withdrawer, uint256 amount) {
        RLPReader.RLPItem[] memory logRLPList = log.toRlpItem().toList();
        RLPReader.RLPItem[] memory logTopicRLPList = logRLPList[1].toList(); // topics

        require(
            bytes32(logTopicRLPList[0].toUint()) == WITHDRAWN_EVENT_SIG, // topic0 is event sig
            "Predicate: invalid signature"
        );

        withdrawer = logRLPList[2].toAddress();
        amount = logRLPList[3].toUint();
    }
}
