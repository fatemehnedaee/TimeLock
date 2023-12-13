// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {TimeLockHarness} from "../src/test/TimeLockHarness.sol";
import {Target} from "../src/test/Target.sol";
import "../src/Errors.sol";

contract TimeLockTest is Test {
    TimeLockHarness public timeLock;
    Target public target;

    event Queue(address target, bytes4 func, bytes data, uint value, uint timestamp);
    event Execute(address target, bytes4 func, bytes data, uint value, uint timestamp);
    event Cancle(address target, bytes4 func, bytes data, uint value, uint timestamp);

    function setUp() public {
        timeLock = new TimeLockHarness();
        target = new Target();
    }

    function testGetTXId() public {
        assertEq(
            timeLock.getTxIdHarness(address(target), Target.func.selector, abi.encode(1, "b"), uint(1), block.timestamp + 1 days), 
            keccak256(abi.encodePacked(address(target), Target.func.selector, abi.encode(1, "b"), uint(1), block.timestamp + 1 days)));
    }

    function testQueueFailedWhenTimestampIsLessThanMinDelay() public {
        vm.expectRevert(Errors.InvalidTime.selector);
        timeLock.queue(address(target), Target.func.selector, abi.encode(1, "b"), uint(1), block.timestamp);
    }

    function testQueueFailedWhenTimestampIsMoreThanMaxDelay() public {
        vm.expectRevert(Errors.InvalidTime.selector);
        timeLock.queue(address(target), Target.func.selector, abi.encode(1, "b"), uint(1), block.timestamp + 4);
    }

    function testQueue() public {
        vm.expectEmit(true, false, false, true);
        emit Queue(address(target), Target.func.selector, abi.encode(1, "b"), uint(1), block.timestamp + 2 days);
        timeLock.queue(address(target), Target.func.selector, abi.encode(1, "b"), uint(1), block.timestamp + 2 days);

        bytes32 _txId = timeLock.getTxIdHarness(address(target), Target.func.selector, abi.encode(1, "b"), uint(1), block.timestamp + 2 days);
        assertEq(timeLock.txIds(_txId), true);
    }

    function testExecuteFailedWhenTransactionNotQueue() public {
        vm.expectRevert(Errors.InvalidTx.selector);
        timeLock.execute(address(target), Target.func.selector, abi.encode(1, "b"), uint(1), block.timestamp + 2 days);
    }

    function testExecuteFailedWhenCurrenttimeIslessThanTimestamp() public {
        timeLock.queue(address(target), Target.func.selector, abi.encode(1, "b"), uint(1), block.timestamp + 2 days);
        vm.expectRevert(Errors.InvalidTime.selector);
        timeLock.execute(address(target), Target.func.selector, abi.encode(1, "b"), uint(1), block.timestamp + 2 days);
    }

    function testExecuteFailedWhenCurrenttimeIsMoreThanTimestampPlusGracetime() public {
        uint _timestamp = block.timestamp + 2 days;
        timeLock.queue(address(target), Target.func.selector, abi.encode(1, "b"), uint(1), _timestamp);
        vm.warp(block.timestamp + 3 days);
        vm.expectRevert(Errors.InvalidTime.selector);
        timeLock.execute(address(target), Target.func.selector, abi.encode(1, "b"), uint(1), _timestamp);
    }

    function testExecuteFailedWhenTransactionFailed() public {
        uint _timestamp = block.timestamp + 2 days;
        timeLock.queue(address(target), Target.func.selector, abi.encode(1), uint(1), _timestamp);
        vm.warp(block.timestamp + 2 days);
        vm.expectRevert(Errors.TxFail.selector);
        timeLock.execute(address(target), Target.func.selector, abi.encode(1), uint(1), _timestamp);
    }

    function testExecuteWhenLengthOfFunctionIsMoreThanZero() public {
        uint _timestamp = block.timestamp + 2 days;
        timeLock.queue(address(target), Target.func.selector, abi.encode(1, "b"), uint(1), _timestamp);

        // Test emit
        vm.warp(block.timestamp + 2 days);
        vm.expectEmit(true, false, false, true);
        emit Execute(address(target), Target.func.selector, abi.encode(1, "b"), uint(1), _timestamp);
        timeLock.execute{value: 1}(address(target), Target.func.selector, abi.encode(1, "b"), uint(1), _timestamp);

        //  Test call
        assertEq(target.a(), 1);
        assertEq(target.b(), "b");

        //  Test mapping
        bytes32 _txId = timeLock.getTxIdHarness(address(target), Target.func.selector, abi.encode(1, "b"), uint(1), _timestamp);
        assertEq(timeLock.txIds(_txId), false);
    }

    function testExecuteWhenLengthOfFunctionIsZero() public {
        uint _timestamp = block.timestamp + 2 days;
        timeLock.queue(address(target), bytes4(""), abi.encode(1, "b"), uint(1), _timestamp);

        // Test emit
        vm.warp(block.timestamp + 2 days);
        vm.expectEmit(true, false, false, true);
        emit Execute(address(target), bytes4(""), abi.encode(1, "b"), uint(1), _timestamp);
        timeLock.execute{value: 1}(address(target), bytes4(""), abi.encode(1, "b"), uint(1), _timestamp);

        //  Test call
        assertEq(target.a(), 1);

        //  Test mapping
        bytes32 _txId = timeLock.getTxIdHarness(address(target), bytes4(""), abi.encode(1, "b"), uint(1), _timestamp);
        assertEq(timeLock.txIds(_txId), false);
    }

    function testCancleFailedWhenTransactionNotQueueOrTransactionExecuted() public {
        vm.expectRevert(Errors.InvalidTx.selector);
        timeLock.cancle(address(target), Target.func.selector, abi.encode(1, "b"), uint(1), block.timestamp + 2 days);
    }  

    function testCancle() public {
        uint _timestamp = block.timestamp + 2 days;
        timeLock.queue(address(target), Target.func.selector, abi.encode(1, "b"), uint(1), _timestamp);

        //  Test emit
        vm.expectEmit(true, false, false, true);
        emit Cancle(address(target), Target.func.selector, abi.encode(1, "b"), uint(1), _timestamp);
        timeLock.cancle(address(target), Target.func.selector, abi.encode(1, "b"), uint(1), _timestamp);

        //  Test mapping
        bytes32 _txId = timeLock.getTxIdHarness(address(target), Target.func.selector, abi.encode(1, "b"), uint(1), _timestamp);
        assertEq(timeLock.txIds(_txId), false);
    }
}
