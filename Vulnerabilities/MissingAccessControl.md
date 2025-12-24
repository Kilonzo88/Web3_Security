# Vulnerability: Missing Access Control
## Description
Missing Access Control (also known as Broken Access Control or Unauthorized Function Access) is one of the most critical vulnerabilities in smart contract development. It occurs when a function that performs a sensitive action—such as withdrawing funds, changing contract ownership, or updating critical parameters—is exposed to the public without any authorization checks.

In Solidity, visibility keywords (like public or external) define who can see or call a function, but they do not define who is allowed to execute the logic within it. Without a proper check (e.g., require(msg.sender == owner)), any address on the blockchain can trigger the function.

## Severity: High / Critical
If an administrative function is left unprotected, an attacker can:

Drain the contract's entire balance.

Take over ownership of the protocol.

Self-destruct the contract.

Brick the protocol by changing critical state variables.

## Vulnerable Code Example
In this example, the developer intended for only the owner to be able to withdraw funds, but they forgot to add an access control check to the withdrawAll function.

Solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VulnerableVault {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // Allows anyone to deposit funds
    receive() external payable {}

    /**
     * @dev VULNERABILITY: Missing Access Control.
     * There is no 'onlyOwner' modifier or 'require' check.
     * Any user can call this function and drain the vault.
     */
    function withdrawAll() public {
        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");
    }
}

## Exploit Scenario
-Deployer (the owner) deploys the contract and deposits 10 ETH.

-Attacker discovers the withdrawAll function on a block explorer.

-Attacker notices there are no onlyOwner modifiers or require statements checking msg.sender.

-Attacker calls withdrawAll() from their own wallet address.

-Result: The contract sends the entire 10 ETH balance to the Attacker's address.

## Recommended Mitigation
1. Using a Simple require Statement
The most basic fix is to manually check the caller's address at the start of the function.

Solidity

function withdrawAll() public {
    require(msg.sender == owner, "Not the owner"); // Access Control check
    uint256 balance = address(this).balance;
    // ... logic
}
2. Using the Ownable Pattern (Recommended)
Industry standard practice involves using a library like OpenZeppelin’s Ownable. This provides a reusable onlyOwner modifier.

Solidity

import "@openzeppelin/contracts/access/Ownable.sol";

contract SecureVault is Ownable {
    constructor() Ownable(msg.sender) {}

    receive() external payable {}

    // The 'onlyOwner' modifier automatically handles the access check
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");
    }
}
3. Role-Based Access Control (RBAC)
For complex systems, use AccessControl to define multiple roles (e.g., ADMIN_ROLE, MINTER_ROLE).

## Auditor's Checklist
Check all public and external functions that modify state.

Verify if the function should be restricted to a specific address or role.

Look for "hidden" administrative functions (e.g., init(), setup(), or migrate()) that might be callable more than once.

Ensure that the constructor correctly initializes the owner or admin address.