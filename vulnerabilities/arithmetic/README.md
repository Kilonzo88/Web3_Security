# Arithmetic Vulnerabilities

Arithmetic vulnerabilities in smart contracts arise from the way the Ethereum Virtual Machine (EVM) handles mathematical operations. These vulnerabilities can lead to unexpected behavior, incorrect calculations, and significant financial losses.

## What are Arithmetic Vulnerabilities?

Arithmetic vulnerabilities occur when:
1. Mathematical operations exceed the maximum or minimum values of their data types
2. Integer overflow or underflow happens silently
3. Division by zero isn't properly handled
4. Rounding errors accumulate in financial calculations

## Historical Context

Prior to Solidity 0.8.0, arithmetic operations would silently overflow or underflow, leading to numerous exploits. The most famous example is the BeautyChain (BEC) token overflow attack, where tokens were created out of thin air.

**Solidity 0.8.0+ Changes**: Built-in overflow/underflow checks that cause transactions to revert instead of wrapping around.

## Types of Arithmetic Vulnerabilities

This directory contains examples and explanations of arithmetic vulnerabilities:

### [Integer Overflow/Underflow](./overflow-underflow/)
Demonstrations of how integers can wrap around when they exceed their maximum or minimum values, and the exploitation techniques for contracts using Solidity versions prior to 0.8.0.

## Common Patterns

### Overflow
When a value exceeds the maximum for its type:
```solidity
uint8 max = 255;
max + 1; // Overflows to 0 (pre-0.8.0)
```

### Underflow
When a value goes below the minimum for its type:
```solidity
uint256 min = 0;
min - 1; // Underflows to 2^256 - 1 (pre-0.8.0)
```

## Prevention Strategies

### For Solidity < 0.8.0
1. **SafeMath Library**: Use OpenZeppelin's SafeMath for all arithmetic
2. **Explicit Checks**: Add manual overflow/underflow checks
3. **Upgrade**: Migrate to Solidity 0.8.0 or later

### For Solidity >= 0.8.0
1. **Default Protection**: Built-in overflow/underflow checks
2. **Unchecked Blocks**: Use `unchecked {}` only when intentional and safe
3. **Gas Optimization**: Carefully use `unchecked` for proven safe operations

## Additional Arithmetic Considerations

- **Precision Loss**: Be aware of integer division truncation
- **Order of Operations**: Perform multiplications before divisions
- **Large Numbers**: Use appropriate data types for large values
- **Negative Numbers**: Be cautious with signed integer operations

## Impact

Arithmetic vulnerabilities can result in:
- Token inflation (creating tokens from nothing)
- Unauthorized fund withdrawals
- Breaking protocol invariants
- Incorrect reward calculations
- Complete economic model collapse

## Resources

- [OpenZeppelin: SafeMath](https://docs.openzeppelin.com/contracts/2.x/api/math#SafeMath)
- [SWC-101: Integer Overflow and Underflow](https://swcregistry.io/docs/SWC-101)
- [Solidity 0.8.0 Release Notes](https://blog.soliditylang.org/2020/12/16/solidity-0.8.0-release-announcement/)
