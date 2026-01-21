# Reentrancy Vulnerabilities

Reentrancy is one of the most critical and well-known vulnerability classes in smart contracts. It occurs when an external call is made to an untrusted contract, which then calls back into the original contract before the first execution is complete. This can lead to unexpected state changes and is the root cause of infamous hacks like The DAO attack.

## What is Reentrancy?

Reentrancy vulnerabilities arise when:
1. A contract makes an external call to another contract
2. The external contract calls back into the original contract
3. The original contract's state isn't properly updated before the external call
4. This allows the attacker to exploit inconsistent state

## Types of Reentrancy

This directory contains examples and explanations of various reentrancy attack patterns:

### [Single-Function Reentrancy](./single-function/)
The classic reentrancy pattern where an attacker re-enters the same function before it completes execution. This is the type of attack used in The DAO hack.

### [Cross-Function Reentrancy](./cross-function/)
A more subtle variant where the attacker calls a different function in the same contract during reentrancy, exploiting shared state between functions.

### [Cross-Contract Reentrancy](./cross-contract/)
Reentrancy that occurs across multiple contracts, where state shared between contracts can be exploited by calling into a different contract during execution.

### [Cross-Chain Reentrancy](./cross-chain/)
An advanced attack pattern involving cross-chain bridges or messaging protocols, where reentrancy occurs across different blockchain networks.

### [Read-Only Reentrancy](./read-only/)
A sophisticated attack where the reentrancy doesn't modify state in the vulnerable contract but exploits inconsistent state reads by other contracts.

### [CEI Violation](./cei-violation/)
Examples demonstrating violations of the Checks-Effects-Interactions pattern, the fundamental principle for preventing reentrancy attacks.

## Prevention

The primary defense against reentrancy is following the **Checks-Effects-Interactions (CEI)** pattern:

1. **Checks**: Validate all conditions and requirements
2. **Effects**: Update all state variables
3. **Interactions**: Make external calls only after state is updated

Additional protection mechanisms:
- **Reentrancy Guards**: Use mutex locks (e.g., OpenZeppelin's `ReentrancyGuard`)
- **Pull Over Push**: Prefer withdrawal patterns over direct transfers
- **Gas Limits**: Be cautious with `.call{value: amount}()` as it forwards all available gas

## Resources

- [ConsenSys: Reentrancy](https://consensys.github.io/smart-contract-best-practices/attacks/reentrancy/)
- [SWC-107: Reentrancy](https://swcregistry.io/docs/SWC-107)
