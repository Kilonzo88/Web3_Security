# Reentrancy (CEI Pattern & ReentrancyGuard)

## Introduction
Reentrancy is one of the most infamous vulnerabilities in smart contract history (e.g., The DAO hack). It occurs when a contract makes an external call to an untrusted address, and that address calls back into the calling contract to update state or withdraw funds *before* the first execution is finished.

The core reason this is possible is often a violation of the **Checks-Effects-Interactions (CEI)** pattern.

## The Checks-Effects-Interactions Pattern
The CEI pattern is a coding standard to prevent reentrancy and other race conditions.
1. **Checks**: Validate conditions (e.g., `require` statements, balance checks).
2. **Effects**: Update the state of the contract (e.g., deducting balances).
3. **Interactions**: Interact with other contracts or addresses (e.g., `call`, `transfer`).

### The Vulnerability (Violating CEI)
If an Interaction (sending ETH) happens *before* the Effect (deducting balance), the called contract can re-enter the function. Since the balance hasn't been deducted yet, the contract "thinks" the user still has funds.

## Code Example

[ReentrancyCEI.sol](../src/ReentrancyCEI.sol)

```solidity
// VULNERABLE
function withdrawVulnerable() external {
    uint256 amount = balances[msg.sender];
    require(amount > 0, "Insufficient balance");

    // Interaction (Sent before state update)
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");

    // Effect (Too late!)
    balances[msg.sender] = 0;
}
```

## Prevention

### 1. Follow CEI Pattern
Update internal state *before* calling external contracts.

```solidity
// SECURE
function withdrawSecureCEI() external {
    uint256 amount = balances[msg.sender];
    require(amount > 0, "Insufficient balance");

    balances[msg.sender] = 0; // Effect

    (bool success, ) = msg.sender.call{value: amount}(""); // Interaction
    require(success, "Transfer failed");
}
```

### 2. Use ReentrancyGuard
OpenZeppelin provides a `ReentrancyGuard` contract with a `nonReentrant` modifier. This acts as a mutex lock, explicitly preventing a function from being entered again while it is still executing.

```solidity
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SecureContract is ReentrancyGuard {
    // SECURE with ReentrancyGuard
    function withdrawSecureGuard() external nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Insufficient balance");

        // Even if we call before updating state, reentrancy is blocked
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        balances[msg.sender] = 0;
    }
}
```

The `nonReentrant` modifier is the gold standard for functions that must perform external calls, especially if CEI is difficult to strictly follow (though CEI is always recommended).
