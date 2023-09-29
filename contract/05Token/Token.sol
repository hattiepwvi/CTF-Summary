// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Token {
    mapping(address => uint) balances; // 查余额的 mapping
    uint public totalSupply; // 总供应量

    // 将初始供应量分配给合约创建者，并将其余额存储在"balances"映射中。
    constructor(uint _initialSupply) public {
        balances[msg.sender] = totalSupply = _initialSupply;
    }

    // integer overflow 整数下溢：0 - 1 不是得到更低的数，而是得到最大数
    // unit 无符号整数如果是负数会被解释成一个非常大的正整数，这可能导致整数溢出。
    // 可以使用SafeMath库来进行安全的整数运算。SafeMath库提供了一些函数，用于确保在进行整数运算时不会发生溢出
    // 用hack 合约调用该合约转账给 hack 合约的 msg.sender, 因为 hack 合约没有任何代币，合约余额会减少直到最大值

    function transfer(address _to, uint _value) public returns (bool) {
        require(balances[msg.sender] - _value >= 0);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        return true;
    }

    // balance是函数的返回值的名称，它并不是一个变量或属性
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }
}
