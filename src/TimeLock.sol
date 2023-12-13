// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Errors.sol";

contract TimeLock {

    uint minDelay = 1 days;
    uint maxDelay = 3 days;
    uint graceTime = 1 days;

    mapping(bytes32 => bool) public txIds;

    event Queue(address target, bytes4 func, bytes data, uint value, uint timestamp);
    event Execute(address target, bytes4 func, bytes data, uint value, uint timestamp);
    event Cancle(address target, bytes4 func, bytes data, uint value, uint timestamp);

    function getTxId(address _target, bytes4 _func, bytes calldata _data, uint _value, uint _timestamp) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_target, _func, _data, _value, _timestamp));
    }

    function queue(address _target, bytes4 _func, bytes calldata _data, uint _value, uint _timestamp) public {
        uint currentTime = block.timestamp;
        if(_timestamp < currentTime + minDelay || _timestamp > currentTime + maxDelay){
            revert Errors.InvalidTime();
        }
        bytes32 _txId = getTxId(_target, _func, _data, _value,  _timestamp);
        txIds[_txId] = true;
        emit Queue(_target, _func, _data, _value,  _timestamp);
    }

    function execute(address _target, bytes4 _func, bytes calldata _data, uint _value, uint _timestamp) payable  public {
        bytes32 _txId = getTxId(_target, _func, _data, _value,  _timestamp);
        if(!txIds[_txId]) {
            revert Errors.InvalidTx();
        }
        uint currentTime = block.timestamp;
        if(currentTime < _timestamp || currentTime >= _timestamp + graceTime) {
            revert Errors.InvalidTime();
        }
        bytes memory data;
        if(bytes4(_func).length > 0){
            data = abi.encodePacked(_func, _data);
        }else 
        {data = _data;}
        (bool success, ) = _target.call{value: _value}(data);
        if(!success) {
            revert Errors.TxFail();
        }
        txIds[_txId] = false;
        emit Execute(_target, _func, _data, _value,  _timestamp);
    }

    function cancle(address _target, bytes4 _func, bytes calldata _data, uint _value, uint _timestamp) public {
        bytes32 _txId = getTxId(_target, _func, _data, _value,  _timestamp);
        if(!txIds[_txId]) {
            revert Errors.InvalidTx();
        }
        txIds[_txId] = false;
        emit Cancle(_target, _func, _data, _value,  _timestamp);
    }  
}
