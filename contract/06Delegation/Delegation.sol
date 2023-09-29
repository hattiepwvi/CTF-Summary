// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * 这关直接在remix 上操作
 * 或者写个接口（接口写的有点多余）
 *
 *
 */

// 如果写一个合约的话， owner 会变成 Hack 合约，而不是自己的小狐狸钱包
// contract Hack {

//   Delegate private delegate;
//   constructor(address _target){
//     delegate = Delegate(_target);
//   }

//   function ChangePwn() external {
//     // delegate.pwn();
//     (bool result,) = address(delegate).delegatecall({data: "pwn()"});

//   }
// }

contract Delegate {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function pwn() public {
        owner = msg.sender;
    }
}

contract Delegation {
    address public owner;
    Delegate delegate;

    constructor(address _delegateAddress) {
        delegate = Delegate(_delegateAddress);
        owner = msg.sender;
    }

    fallback() external {
        (bool result, ) = address(delegate).delegatecall(msg.data);
        if (result) {
            this;
        }
    }
}
