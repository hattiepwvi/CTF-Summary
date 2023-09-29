// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * 1、存储
 *   1） 逻辑：
 *       - 合约中定义状态变量的顺序就是存储的顺序：每个 slot 容纳 32 个字节；
 *          - slot 0: bool
 *          - slot 1: uint256 (正好 32 个字节)
 *          - slot 2: uint8（1 个字节）、uint16 (2 个字节)
 *          - slot 3，slot 4，slot 5: bytes32 (32 个字节) ------ Array
 *
 *        0xd0cb52fdd8e9bdaf8619f7a8079b17ee
 *
 *   2) 区块链上所有数据都能获取（包括 private）：状态变量都是存放在 storage 的某个 slot里的，slot 的宽度是 12 个 bytes，长度是 2 的 256 次方；
 *
 *
 *
 *
 */

contract Privacy {
    bool public locked = true;
    uint256 public ID = block.timestamp;
    uint8 private flattening = 10;
    uint8 private denomination = 255;
    uint16 private awkwardness = uint16(block.timestamp);
    bytes32[3] private data;

    constructor(bytes32[3] memory _data) {
        data = _data;
    }

    function unlock(bytes16 _key) public {
        require(_key == bytes16(data[2]));
        locked = false;
    }

    /*
    A bunch of super advanced solidity algorithms...

      ,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`
      .,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,
      *.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^         ,---/V\
      `*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.    ~|__(o.o)
      ^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'  UU  UU
  */
}
