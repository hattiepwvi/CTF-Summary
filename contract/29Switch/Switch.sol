// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * ************ Switch ************
 * 1、Goal: switchOn = true;
 *   1）思路： 使用 CALLDATA 的方法调用 flipSwitch()函数（将 turnSwitchOn() 方法设置为选择器传入 flipSwitch() 方法）
 *         - onlyOff 修饰符：selector 是大小为 1 的 bytes32 数组
 *         - msg.sender == address(this) 让合约自己调用自己的函数： 使用call
 * 2、calldata 是传入 call 的 16进制数据：函数选择器和传入函数的参数 inputs;
 *   1）静态 calldata 的值（数据大小固定）： 4 个字节的 selector + 每 32 个字节一个 inputs 参数
 *       - Remix 的 inputs(可以复制函数的Calldata): 0x1d8a0cc800000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000002
 *   2） 动态的 calldata 值：off 偏移量（数据的位置） + 数据（大小 + actual inputs）；本题中的 actual inputs 为 turnSwitchOn 函数; 数据的位置是数据从哪里开始，16进制的 20 相当于 10进制的32；大小比如 4字节
 *         - calldatacopy(selector, 位置, 数据大小) 也就是call 第68个字符的位置的4个字节是函数选择器；
 *         - 实际操作
 *            - 获取函数选择器的方法：写在合约里状态变量里，部署到 Remix 上获取(不用小狐狸钱包就用普通的 Remix 账户) 0x76227e12
 *            - 将函数选择器 0x76227e12 输入flipSwitch() 里获取动态的 calldata 值是不满足require 条件的： 0x30c13ade0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000476227e1200000000000000000000000000000000000000000000000000000000
 *            - 修改 calldata：flipSwitch函数选择器 + 数据开始的位置是60 + onlyoff 数据大小 + only off（turnSwitchOff 函数选择器）+ actualinputs数据大小 + actualinputs(turnSwitchOn 函数选择器)；使其可以满足 require 的条件：0x30c13ade0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000420606e1500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000476227e1200000000000000000000000000000000000000000000000000000000
 *                   0x30c13ade
 *                   0000000000000000000000000000000000000000000000000000000000000060
 *                   0000000000000000000000000000000000000000000000000000000000000004
 *                   20606e1500000000000000000000000000000000000000000000000000000000
 *                   0000000000000000000000000000000000000000000000000000000000000004
 *                   76227e1200000000000000000000000000000000000000000000000000000000
 *            - 在合约中添加 fallback 函数，使用 合约地址 at address 获取合约实例，使用 CALLDATA 的 transact 方法调用函数
 */

contract Switch {
    bool public switchOn; // switch is off
    bytes4 public offSelector = bytes4(keccak256("turnSwitchOff()"));
    bytes4 public onSelector = bytes4(keccak256("turnSwitchOn()"));

    modifier onlyThis() {
        require(msg.sender == address(this), "Only the contract can call this");
        _;
    }

    modifier onlyOff() {
        // we use a complex data type to put in memory
        bytes32[1] memory selector;
        // check that the calldata at position 68 (location of _data)
        assembly {
            calldatacopy(selector, 68, 4) // grab function selector from calldata
        }
        require(
            selector[0] == offSelector,
            "Can only call the turnOffSwitch function"
        );
        _;
    }

    function flipSwitch(bytes memory _data) public onlyOff {
        (bool success, ) = address(this).call(_data);
        require(success, "call failed :(");
    }

    function turnSwitchOn() public onlyThis {
        switchOn = true;
    }

    function turnSwitchOff() public onlyThis {
        switchOn = false;
    }

    function simple(uint256 num1, uint256 num2) public pure {
        uint256 num3 = num1 + num2;
    }

    fallback() external {}
}
