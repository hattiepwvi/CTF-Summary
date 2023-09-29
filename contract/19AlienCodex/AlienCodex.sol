// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "../helpers/Ownable-05.sol";

contract AlienCodex is Ownable {
    bool public contact;
    bytes32[] public codex;

    // contact变量的值是否为true 时才能执行相应的操作
    modifier contacted() {
        assert(contact);
        _;
    }

    function makeContact() public {
        contact = true;
    }

    // 添加记录
    function record(bytes32 _content) public contacted {
        codex.push(_content);
    }

    // 减少最后一条信息，solidity 0.8 是用 pop 删除最后一个元素
    function retract() public contacted {
        codex.length--;
    }

    //修改指定位置的记录
    function revise(uint i, bytes32 _content) public contacted {
        codex[i] = _content;
    }
}
