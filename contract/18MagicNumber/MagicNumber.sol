// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Hack {
    // 这样写的话代码会超过 10 opcode;
    // function whatIsTheMeaningOfLife(
    //     MagicNum target
    // ) external pure returns (uint) {
    //     return 42;
    // }

    constructor(MagicNum target) {
        // 创建一个代码小于10 的合约（16 进制 hexdecimal, 实现与上面方程一样的结果）
        bytes memory bytecode = hex"69602a60005260206000f3600052600a6016f3";

        address addr; // 要部署的合约地址

        // 手动部署用 assembly
        assembly {
            /**
             * 1、create 创建部署合约并返回合约地址address
             *    1) create(value, offset, size) 三个参数（发送到合约的以太币数量、代码开始的指针内存 pointer memory、代码大小 size ）
             *    2) 代码存储的指针内存： bytecode 是 point
             *    3) dynamic array 的前 32 bytes 存储的是 array 的 length, 所以要跳过前32个字节才能获取真正的指针
             *    4) 向指针添加 32 个字节或 16 进制 的 0x20 (表示十进制的 32),
             *    5) address(0) 表示 Solidity 中的零地址，也被称为 "0x0" 地址，表示无效的或未初始化的地址。
             *    6) 部署时需要的运行代码 Rum time code 小于 10 字节: 2个字符 character 是1个 opcode;
             *
             */
            addr := create(0, add(bytecode, 0x20), 0x13)
        }
        require(addr != address(0));

        target.setSolver(addr);
    }
}

contract MagicNum {
    address public solver;

    constructor() {}

    function setSolver(address _solver) public {
        solver = _solver;
    }

    /*
    ____________/\\\_______/\\\\\\\\\_____        
     __________/\\\\\_____/\\\///////\\\___       
      ________/\\\/\\\____\///______\//\\\__      
       ______/\\\/\/\\\______________/\\\/___     
        ____/\\\/__\/\\\___________/\\\//_____    
         __/\\\\\\\\\\\\\\\\_____/\\\//________   
          _\///////////\\\//____/\\\/___________  
           ___________\/\\\_____/\\\\\\\\\\\\\\\_ 
            ___________\///_____\///////////////__
  */
}

/**
 * 2、node:将数字转换为十六进制字符串。
 *    - 19 在十六进制中表示为 13
 *   $ node
     Welcome to Node.js v18.17.1.
     Type ".help" for more information.
     > s = "69602a60005260206000f3600052600a6016f3"
    '69602a60005260206000f3600052600a6016f3'
     > s.length
     38
     > size = 19
     19
     > size.toString(16)
     '13'
 */
