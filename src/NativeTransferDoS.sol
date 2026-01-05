// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title DoS Examples (For-loop growth + Native transfer reverts)
 * @notice Simple vulnerable contracts and attacker contracts used to demonstrate DOS issues from the tutorial.
 * - VulnerableForLoop: mint() pushes new addresses into users[]; distributeDividends() loops through the array.
 * - NativeTransferVulnerable: attempts a gas-limited native transfer, and reverts on failure.
 */


// ---------------------
// Native transfer DoS example
// ---------------------

contract NativeTransferVulnerable {
    uint256 public nativeTransferGasLimit = 10_000;
    event NativeTokenTransferReverted(string reason);

    // Simplified transfer primitive that mirrors the GMX example
    function transferNativeToken(address payable receiver, uint256 amount) internal {
        if (amount == 0) { return; }

        (bool success, bytes memory data) = receiver.call{value: amount, gas: nativeTransferGasLimit}("");
        if (success) { return; }

        // Emit for observability and revert to show the failing path
        string memory reason = string(abi.encode(data));
        emit NativeTokenTransferReverted(reason);
        revert("NativeTokenTransferError");
    }

    // Exposed function to emulate liquidation flow
    function liquidate(address payable receiver) external payable {
        transferNativeToken(receiver, msg.value);
    }

    // PoC helper: allow changing the gas limit used for native transfers (useful to reproduce low-gas failures)
    function setNativeTransferGasLimit(uint256 newLimit) external {
        nativeTransferGasLimit = newLimit;
    }

    // PoC helper: attempt a transfer with a caller-provided gas limit so tests can probe when the call fails
    event TransferAttempt(address indexed receiver, uint256 amount, uint256 gasLimit, bool success, string reason);

    function transferWithCustomGas(address payable receiver, uint256 amount, uint256 gasLimit) external payable {
        require(msg.value == amount, "value mismatch");
        (bool success, bytes memory data) = receiver.call{value: amount, gas: gasLimit}("");
        if (success) {
            emit TransferAttempt(receiver, amount, gasLimit, true, "");
            return;
        }
        string memory reason = string(abi.encode(data));
        emit NativeTokenTransferReverted(reason);
        emit TransferAttempt(receiver, amount, gasLimit, false, reason);
        revert("NativeTokenTransferError");
    }
}

// Attacker receiver which *rejects* ETH (reverts in receive), causing transferNativeToken to revert
contract RejectingReceiver {
    receive() external payable {
        revert("I reject ETH");
    }
}

// Receiver that intentionally consumes gas in the fallback/receive
contract HeavyGasReceiver {
    receive() external payable {
        // consume a lot of gas (but note: this is bounded by the provided gas and may revert)
        for (uint256 i = 0; i < 1000; i++) {
            // do some meaningless computation
            uint256 x = i * i;
            x;
        }
    }
}
