// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * 1、任务分析
 * 1）Goal: bug is in CryptoVault and protect it from being drained out of tokens
 * 2）合约简介：使用了委托合约的模式来执行代币转账，通过Forta平台的机器人进行通信和检测，以确保转账交易的安全性
 *
 * 2、逻辑：
 * transfer LGT 时因为 DoubleEntryPoint 所以也会transfer DEG；
 *
 *
 */

import "openzeppelin-contracts-08/access/Ownable.sol";
import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";

interface DelegateERC20 {
    function delegateTransfer(
        address to,
        uint256 value,
        address origSender
    ) external returns (bool);
}

interface IDetectionBot {
    function handleTransaction(address user, bytes calldata msgData) external;
}

interface IForta {
    function setDetectionBot(address detectionBotAddress) external;

    function notify(address user, bytes calldata msgData) external;

    function raiseAlert(address user) external;
}

contract Forta is IForta {
    // usersDetectionBots 跟踪每个用户分配的检测机器人
    // botRaisedAlerts 跟踪每个检测机器人所引发的警报数量
    mapping(address => IDetectionBot) public usersDetectionBots;
    mapping(address => uint256) public botRaisedAlerts;

    function setDetectionBot(address detectionBotAddress) external override {
        // 映射的键是用户的地址，值是检测机器人的地址;用户就可以通过调用setDetectionBot函数来设置他们的检测机器人地址
        usersDetectionBots[msg.sender] = IDetectionBot(detectionBotAddress);
    }

    function notify(address user, bytes calldata msgData) external override {
        if (address(usersDetectionBots[user]) == address(0)) return;
        // 允许检测机器人通知合约有关某个交易的信息。它接受两个参数：user（用户的地址）和msgData（与交易相关的数据）
        try usersDetectionBots[user].handleTransaction(user, msgData) {
            return;
        } catch {}
    }

    function raiseAlert(address user) external override {
        // 调用者不是用户分配的检测机器人
        if (address(usersDetectionBots[user]) != msg.sender) return;
        botRaisedAlerts[msg.sender] += 1;
    }
}

// 设置底层代币地址和指定接收者地址，合约地址的 token 余额转移到指定的接收者地址 sweptTokensRecipient。
// 不能清除 underlying 代币 DEG,清除的是 LGT；
contract CryptoVault {
    // sweep token 的代币的接收地址
    address public sweptTokensRecipient;
    IERC20 public underlying;

    constructor(address recipient) {
        sweptTokensRecipient = recipient;
    }

    function setUnderlying(address latestToken) public {
        // underlying变量是否已经设置过。如果已经设置过，则会抛出异常
        require(address(underlying) == address(0), "Already set");
        // underlying变量还没有设置过，将latestToken转换为IERC20接口类型，并将其赋值给underlying变量
        underlying = IERC20(latestToken);
    }

    /*
    ...
    */

    function sweepToken(IERC20 token) public {
        require(token != underlying, "Can't transfer underlying token");
        token.transfer(sweptTokensRecipient, token.balanceOf(address(this)));
    }
}

// 实现一个具有委托/代理功能的ERC20代币合约：铸造代币、设置委托/代理合约，并根据是否设置了委托/代理合约来决定代币转移的执行方式。
contract LegacyToken is ERC20("LegacyToken", "LGT"), Ownable {
    // 委托合约的地址
    DelegateERC20 public delegate;

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function delegateToNewContract(DelegateERC20 newContract) public onlyOwner {
        // 委托合约的地址设置为新合约
        delegate = newContract;
    }

    function transfer(
        address to,
        uint256 value
    ) public override returns (bool) {
        // delegate变量为0地址，表示没有设置委托合约，则调用父合约（ERC20合约）的transfer函数来执行代币转移。
        if (address(delegate) == address(0)) {
            return super.transfer(to, value);
        } else {
            // delegate变量不为0地址，表示已经设置了委托合约，则调用委托合约的delegateTransfer函数来执行代币转移，并传递to、value和msg.sender作为参数
            return delegate.delegateTransfer(to, value, msg.sender);
        }
    }
}

// 允许委托合约调用delegateTransfer函数来执行代币转移，并通过fortaNotify修饰符与Forta平台进行通信。
contract DoubleEntryPoint is
    ERC20("DoubleEntryPointToken", "DET"),
    DelegateERC20,
    Ownable
{
    address public cryptoVault;
    address public player;
    address public delegatedFrom;
    Forta public forta;

    //legacyToken（遗留代币合约的地址
    constructor(
        address legacyToken,
        address vaultAddress,
        address fortaAddress,
        address playerAddress
    ) {
        delegatedFrom = legacyToken;
        forta = Forta(fortaAddress);
        player = playerAddress;
        cryptoVault = vaultAddress;
        _mint(cryptoVault, 100 ether);
    }

    modifier onlyDelegateFrom() {
        // 只有委托合约（即delegatedFrom地址）才能调用被修饰的函数。
        require(msg.sender == delegatedFrom, "Not legacy contract");
        _;
    }

    modifier fortaNotify() {
        // Forta平台中与玩家相关的检测机器人的地址
        address detectionBot = address(forta.usersDetectionBots(player));

        // 缓存旧的机器人警报数量。
        // Cache old number of bot alerts
        uint256 previousValue = forta.botRaisedAlerts(detectionBot);

        // 调用Forta合约的notify函数，将玩家地址和msg.data作为参数进行通知
        // Notify Forta
        forta.notify(player, msg.data);

        // Continue execution
        _;

        // Check if alarms have been raised
        // 检查是否触发了警报，如果触发了警报，则回滚（revert）操作
        if (forta.botRaisedAlerts(detectionBot) > previousValue)
            revert("Alert has been triggered, reverting");
    }

    function delegateTransfer(
        address to,
        uint256 value,
        address origSender
    ) public override onlyDelegateFrom fortaNotify returns (bool) {
        // to（接收代币的地址）、value（要转移的代币数量）和origSender（原始发送者的地址）
        _transfer(origSender, to, value);
        return true;
    }
}
