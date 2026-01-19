// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title OverflowUnderflow
 * @dev Demonstrates integer overflow/underflow vulnerability.
 * In Solidity 0.8.x, arithmetic operations revert on overflow/underflow by default.
 * However, this can be bypassed using `unchecked` blocks, which is common for gas optimization
 * or in legacy code (pre-0.8.0) where SafeMath was required.
 */
contract OverflowUnderflow {
    uint64 public totalFees;
    uint256 public balance;

    constructor() {
        balance = 100; // Initial balance
    }

    /**
     * @dev Demonstrates manual overflow using `unchecked`.
     * This mimics the behavior of Solidity < 0.8.0 without SafeMath.
     */
    function addFee(uint256 fee) external {
        unchecked {
            // VULNERABLE: If totalFees + fee > type(uint64).max, it wraps around.
            // Also, casting `fee` to `uint64` can truncate data if fee > type(uint64).max
            
            //@Audit: overflow possible here
            totalFees = totalFees + uint64(fee);
        }
    }

    /**
     * @dev Demonstrates underflow.
     * If `amount` > `balance`, `balance - amount` wraps to a huge number.
     */
    function withdraw(uint256 amount) external {
        unchecked {
            require(balance >= 0, "Redundant check since uint is always >= 0");
            
            // VULNERABLE: Underflow if amount > balance
            // e.g., 100 - 101 = 2^256 - 1 (huge number)
            balance = balance - amount; 
        }
        
        // Transfer logic would go here
    }
}
