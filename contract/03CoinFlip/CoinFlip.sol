// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 *  1、entropy 熵： 一开始有序，慢慢分散
 *
 *
 */
contract CoinFlip {
    uint256 public consecutiveWins; //连续赢的次数
    // 上一个区块的哈希值
    uint256 lastHash;
    // FACTOR用于计算硬币翻转的结果：factor 可视为加密的种子数据，随机的种子数据被放入 hash 中（这里不是随机的，所以有问题）
    uint256 FACTOR =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor() {
        consecutiveWins = 0;
    }

    function flip(bool _guess) public returns (bool) {
        // 上一个区块的哈希值blockhash再转换成 uint256 类型。
        uint256 blockValue = uint256(blockhash(block.number - 1));

        // lastHash 和 blockValue 如果相等，则抛出异常。
        if (lastHash == blockValue) {
            revert();
        }

        // 将lastHash更新为blockValue，
        lastHash = blockValue;
        // 使用FACTOR来计算硬币翻转的结果
        uint256 coinFlip = blockValue / FACTOR;
        // 硬币翻转的结果等于1，则side为真，否则为假, 把结果赋值给 side：bool sid = (coinFlip == 1 ? true : false);
        bool side = coinFlip == 1 ? true : false;

        // side 与传入的参数 _guess 相等，则表示猜测正确，consecutiveWins加1，并返回真
        // 否则，将consecutiveWins重置为0，并返回假。
        if (side == _guess) {
            consecutiveWins++;
            return true;
        } else {
            consecutiveWins = 0;
            return false;
        }
    }
}
