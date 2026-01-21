# Denial of Service (DoS) Vulnerabilities

Denial of Service attacks in smart contracts aim to make a contract temporarily or permanently unusable. Unlike traditional DoS attacks that flood servers with requests, blockchain DoS attacks exploit contract logic to prevent legitimate operations.

## What is DoS in Smart Contracts?

DoS vulnerabilities occur when:
1. An attacker can block or prevent normal contract operations
2. The contract becomes unusable for legitimate users
3. Critical functions cannot be executed
4. The cost of using the contract becomes prohibitively expensive

## Types of DoS Attacks

This directory contains examples and explanations of various DoS attack patterns:

### [For-Loop DoS](./for-loops/)
Attacks that exploit unbounded loops over dynamic arrays, causing gas costs to exceed block gas limits as the array grows.

### [Self-Destruct DoS](./selfdestruct/)
Exploits involving forcefully sending Ether to contracts using `selfdestruct`, breaking contracts that rely on exact balance checks.

### [Native Transfer DoS](./native-transfer/)
Attacks where an attacker causes Ether transfers to fail, blocking critical contract functionality that depends on successful transfers.

## Common DoS Patterns

- **Gas Limit DoS**: Operations that grow in cost with usage until they exceed block gas limits
- **Revert DoS**: External calls that can be made to revert, blocking dependent operations
- **Block Gas Limit**: Loops or operations that can be manipulated to exceed block gas limits
- **Unexpected Revert**: Contracts that fail when receiving Ether or when external calls fail

## Prevention Strategies

1. **Avoid Unbounded Loops**: Never iterate over arrays that can grow indefinitely
2. **Pull Over Push**: Use withdrawal patterns instead of pushing payments
3. **Limit Array Size**: Implement maximum constraints on dynamic arrays
4. **Handle Failed Transfers**: Don't rely on transfer success for critical operations
5. **Circuit Breakers**: Implement emergency stop mechanisms
6. **Favor Pull Payments**: Let users withdraw rather than pushing payments to them

## Impact

DoS vulnerabilities can:
- Freeze funds indefinitely
- Prevent critical protocol operations
- Make contracts completely unusable
- Block admin functions and upgrades
- Cause financial losses through stuck assets

## Resources

- [ConsenSys: Denial of Service](https://consensys.github.io/smart-contract-best-practices/attacks/denial-of-service/)
- [SWC-113: DoS with Failed Call](https://swcregistry.io/docs/SWC-113)
- [SWC-128: DoS with Block Gas Limit](https://swcregistry.io/docs/SWC-128)
