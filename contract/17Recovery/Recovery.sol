// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Hack {
    // function recover(SimpleToken target) external {
    //     target.destroy(payable(msg.sender));
    // }
    /**
     * 1）sender 是 Recovery 合约的地址
     * 2）下面是使用 Nounce 1 计算的地址，区别就是bytes1(0x80)的使用
     *     - Recovery 合约调用了一个generationToken，所以 Nounce 是1
     */

    function recover(address sender) external pure returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xd6), bytes1(0x94), sender, bytes1(0x01))
        );
        address addr = address(uint160(uint256(hash)));
        return addr;
    }
}

// 工厂合约 Recovery 会调用另一个合约SimpleToken的构造函数来创建一个新的代币。
contract Recovery {
    //generate tokens
    function generateToken(string memory _name, uint256 _initialSupply) public {
        new SimpleToken(_name, msg.sender, _initialSupply);
    }
}

// SimpleToken合约有三个主要的功能：记录账户余额、接收以太币并兑换成代币、以及允许代币的转账
contract SimpleToken {
    string public name;
    mapping(address => uint) public balances;

    // constructor
    constructor(string memory _name, address _creator, uint256 _initialSupply) {
        name = _name;
        balances[_creator] = _initialSupply;
    }

    // collect ether in return for tokens
    receive() external payable {
        // 将发送者的代币余额设置为发送者发送的以太币数量的10倍。
        // 这个功能可以用来设置以太币和代币之间的兑换比例为1:10。
        balances[msg.sender] = msg.value * 10;
    }

    // allow transfers of tokens
    function transfer(address _to, uint _amount) public {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = balances[msg.sender] - _amount;
        balances[_to] = _amount;
    }

    // clean up after ourselves
    // 销毁合约并将剩余的以太币发送给指定的地址。
    function destroy(address payable _to) public {
        selfdestruct(_to);
    }
}

/**
 * 1、用公式计算丢失的合约的地址
 *   1） 合约地址是根据创建者（发送者 sender）的地址、创建者发送的交易数量（nonce）、sender 和 nonce 编码和 hash 后的值；
 * 2、selfdestruct 找回丢失的代币
 *   1）使用找回的地址部署 SimpleToken 实例: 0x3CfE6fb5103110b284b88fC7C66Ea29aE8Bd2eDb
 */
