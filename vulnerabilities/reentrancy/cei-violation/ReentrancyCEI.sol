// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

/**
 * @title ReentrancyCEI
 * @dev Demonstrates adherence and violation of Checks-Effects-Interactions pattern.
 */
contract ReentrancyCEI is ReentrancyGuard {
    mapping(address => uint256) public balances;

    // VULNERABLE: Effects (state update) happen after Interactions (external call)
    function withdrawVulnerable() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Insufficient balance");

        // Interaction
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        // Effect (Too late!)
        balances[msg.sender] = 0;
    }

    // SECURE: Checks-Effects-Interactions Pattern
    function withdrawSecureCEI() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Insufficient balance"); // Check

        balances[msg.sender] = 0; // Effect

        (bool success, ) = msg.sender.call{value: amount}(""); // Interaction
        require(success, "Transfer failed");
    }

    // SECURE: Using ReentrancyGuard
    // Even if we violate CEI (which we shouldn't), this prevents reentrancy.
    function withdrawSecureGuard() external nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Insufficient balance");

        // Interaction (violating CEI order, but protected by modifier)
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        // Effect
        balances[msg.sender] = 0;
    }
    
    // Deposit helper
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }
    
    receive() external payable {}
}
