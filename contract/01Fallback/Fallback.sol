// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Fallback {
    mapping(address => uint) public contributions;
    address public owner;

    constructor() {
        owner = msg.sender; // 合约部署者(当前交易的发送者的地址)是 owner
        contributions[msg.sender] = 1000 * (1 ether); // msg.sender对应的值设置为1000个以太币
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    function contribute() public payable {
        require(msg.value < 0.001 ether); // 调用者发送的以太币数量小于0.001 ether
        contributions[msg.sender] += msg.value; // 调用者发送的以太币数量加到contributions映射中与调用者地址对应的值上
        if (contributions[msg.sender] > contributions[owner]) {
            owner = msg.sender; // 调用者的贡献超过了当前的owner的贡献的话，将会更新owner为调用者的地址
        }
    }

    function getContribution() public view returns (uint) {
        return contributions[msg.sender];
    }

    // 将合约中的所有余额转移到合约的拥有者（owner）的地址上
    function withdraw() public onlyOwner {
        // payable(owner) 将owner地址转换为可支付的地址类型
        payable(owner).transfer(address(this).balance);
    }

    // 如果发送者满足条件（以太币数量大于0且贡献量大于0），那么他们将成为合约的新拥有者。
    receive() external payable {
        require(msg.value > 0 && contributions[msg.sender] > 0);
        owner = msg.sender;
    }
}
