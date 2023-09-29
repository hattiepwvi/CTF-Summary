// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "openzeppelin-contracts-06/math/SafeMath.sol";

contract Reentrance {
    using SafeMath for uint256;
    mapping(address => uint) public balances;

    // 捐赠给 地址
    function donate(address _to) public payable {
        balances[_to] = balances[_to].add(msg.value);
    }

    // 查余额
    function balanceOf(address _who) public view returns (uint balance) {
        return balances[_who];
    }

    // 取余额：msg.sender 余额 >= 0;
    // 向 msg.sender 转账
    function withdraw(uint _amount) public {
        if (balances[msg.sender] >= _amount) {
            (bool result, ) = msg.sender.call{value: _amount}("");
            if (result) {
                _amount;
            }
            // 转账完成之后才更新余额，所以会有重攻击的风险；
            // 转账的时候会触发 receive 或 fallback, 如果在 receive 和fallback 里再次调用 withdraw, 因为余额还没有更新，所以会继续调用 call;
            balances[msg.sender] -= _amount;
        }
    }

    receive() external payable {}
}
