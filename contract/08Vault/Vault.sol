pragma solidity ^0.8.0;

contract Vault {
    bool public locked;
    bytes32 private password;

    constructor(bytes32 _password) {
        locked = true;
        password = _password;
    }

    function unlock(bytes32 _password) public {
        if (password == _password) {
            locked = false;
        }
    }
}

// 在 foundry 环境下，用cast 获取密码
// cast storage 0x30D41d0B2a42c44A9E7D0f369D011cA21EB2d4ec 1 --rpc-url https://eth-sepolia.g.alchemy.com/v2/xxxxxxxxxxxxxxxxxx
// 返回的密码：0x412076657279207374726f6e67207365637265742070617373776f7264203a29
