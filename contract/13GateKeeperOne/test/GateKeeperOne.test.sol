pragma solidity ^0.8;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "src/13-gate-keeper-one.sol";

contract TestGateKeeperOne is Test {
    IGateKeeperOne private target;
    // GatekeeperOne private target;
    Hack private hack;

    function setUp() public {
        target = IGateKeeperOne(0x037e210a2575f2f57207540c3a33AF1C03Eaef39);
        // target = new GatekeeperOne();
        hack = new Hack();
    }

    function test() public {
        // 使用一个循环来尝试调用hack合约的enter函数，并传入目标合约的地址和一个参数i。如果调用成功，就会打印出gas的值，并结束测试。
        for (uint256 i = 100; i < 8191; i++) {
            try hack.enter(address(target), i) {
                console.log("gas", i);
                return;
            } catch {}
        }
        revert("all failed");
    }
}
