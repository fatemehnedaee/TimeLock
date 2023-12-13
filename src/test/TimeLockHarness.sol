pragma solidity ^0.8.13;

import "../TimeLock.sol";

contract TimeLockHarness is TimeLock{


    function getTxIdHarness(address _target, bytes4 _func, bytes calldata _data, uint _value, uint _timestamp) public pure returns(bytes32) {
        return getTxId(_target, _func, _data, _value, _timestamp);
    }
}