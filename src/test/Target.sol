// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Target {

    uint public a;
    string public b;

    function func(uint _a, string calldata _b) payable public {
        a = _a;
        b = _b;
    }

    fallback() external payable {
        a = 1;
    }

    receive() external payable {}
}